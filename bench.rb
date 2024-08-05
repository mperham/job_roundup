require "benchmark_driver"
require "sidekiq/api"
require File.expand_path("./config/environment", File.dirname(__FILE__))

Rails.logger.level = Logger::WARN
ActiveJob::Base.queue_adapter = :async
Sidekiq.redis { |c| c.flushdb }

# You can run this to clear all data from PG and Redis
# rake db:drop db:create db:migrate ; redis-cli flushall
raise "Databases not empty. Use bin/bench" unless [GoodJob::Job.count, SolidQueue::Job.count, Sidekiq::Queue.new.size].all?(&:zero?)

puts RUBY_DESCRIPTION
p({rails: Rails.version,
   good_job: GoodJob::VERSION,
   sidekiq: Sidekiq::VERSION,
   solid_queue: SolidQueue::VERSION})

jobs = 1000
puts "Benchmarking with #{jobs} jobs per iteration"

puts "==== Single Enqueue ===="
Benchmark.driver do |x|
  x.prelude <<~RUBY
    # frozen_string_literal: true
    require File.expand_path("./config/environment", #{File.dirname(__FILE__).inspect})

    hash = {"foo" => true}
    jobs = #{jobs}
  RUBY

  x.report "good_job", <<~RUBY
    jobs.times do
      RoundupJob::Goodjob.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "solid_queue", <<~RUBY
    jobs.times do
      RoundupJob::Solidqueue.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "sidekiq", <<~RUBY
    jobs.times do
      RoundupJob::Sidekiq.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "sidekiq-native", <<~RUBY
    jobs.times do
      RoundupWorker.perform_async(123, "hello world", hash)
    end
  RUBY
end

puts "==== Bulk Enqueue ===="
Benchmark.driver do |x|
  x.prelude <<~RUBY
    # frozen_string_literal: true
    require File.expand_path("./config/environment", #{File.dirname(__FILE__).inspect})

    hash = {"foo" => true}
    jobs = #{jobs}
  RUBY

  x.report "good_job", <<~RUBY
    GoodJob::Bulk.enqueue do
      jobs.times do
        RoundupJob::Goodjob.perform_later(123, "hello world", hash)
      end
    end
  RUBY

  x.report "sidekiq", <<~RUBY
    ActiveJob.perform_all_later(jobs.times.map do
      RoundupJob::Sidekiq.new(123, "hello world", hash)
    end )
  RUBY

  x.report "sidekiq-native", <<~RUBY
    RoundupWorker.perform_bulk(jobs.times.map { [123, "hello world", hash] })
  RUBY
end
