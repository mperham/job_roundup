require "benchmark_driver"
require "sidekiq/api"
require File.expand_path("./config/environment", File.dirname(__FILE__))

Rails.logger.level = Logger::WARN
ActiveJob::Base.queue_adapter = :async
Sidekiq.redis { |c| c.flushdb }

# You can run this to clear all data from PG and Redis
# rake db:drop db:create db:migrate ; redis-cli flushall
raise "Databases not empty" unless [GoodJob::Job.count, SolidQueue::Job.count, Sidekiq::Queue.new.size].all?(&:zero?)

puts RUBY_DESCRIPTION
p({rails: Rails.version,
   good_job: GoodJob::VERSION,
   sidekiq: Sidekiq::VERSION,
   solid_queue: SolidQueue::VERSION})

jobs = 1000
puts "Benchmarking with #{jobs} jobs per iteration"

Benchmark.driver do |x|
  x.prelude <<~RUBY
    require File.expand_path("./config/environment", #{File.dirname(__FILE__).inspect})

    hash = {"foo" => true}
    jobs = #{jobs}
  RUBY

  x.report "good_job-push", <<~RUBY
    ActiveJob::Base.queue_adapter = :good_job
    jobs.times do
      RoundupJob.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "good_job-pushbulk", <<~RUBY
    ActiveJob::Base.queue_adapter = :good_job
    GoodJob::Bulk.enqueue do
      jobs.times do
        RoundupJob.perform_later(123, "hello world", hash)
      end
    end
  RUBY

  x.report "solid_queue-push", <<~RUBY
    ActiveJob::Base.queue_adapter = :solid_queue
    jobs.times do
      RoundupJob.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "solid_queue-pushbulk", <<~RUBY
    ActiveJob::Base.queue_adapter = :solid_queue
    ActiveJob.perform_all_later(jobs.times.map do
      RoundupJob.new(123, "hello world", hash)
    end)
  RUBY

  x.report "sidekiq-push", <<~RUBY
    ActiveJob::Base.queue_adapter = :sidekiq
    jobs.times do
      RoundupJob.perform_later(123, "hello world", hash)
    end
  RUBY

  x.report "sidekiq-native-enq", <<~RUBY
    jobs.times do
      RoundupWorker.perform_async(123, "hello world", hash)
    end
  RUBY

  x.report "sidekiq-native-enq-bulk", <<~RUBY
    RoundupWorker.perform_bulk(jobs.times.map { [123, "hello world", hash] })
  RUBY
end
