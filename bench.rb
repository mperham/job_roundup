require "benchmark"
require "sidekiq/api"

Rails.logger.level = Logger::WARN
ActiveJob::Base.queue_adapter = :async
Sidekiq.redis { |c| c.flushdb }

# You can run this to clear all data from PG and Redis
# rake db:drop db:create db:migrate ; redis-cli flushall
raise "Databases not empty" unless [GoodJob::Job.count, SolidQueue::Job.count, Sidekiq::Queue.new.size].all?(&:zero?)

hash = {"foo" => true}
Benchmark.bm(25) do |x|
  outer = 10
  inner = 1000
  puts RUBY_DESCRIPTION
  p({rails: Rails.version, 
     good_job: GoodJob::VERSION,
     sidekiq: Sidekiq::VERSION,
     solid_queue: SolidQueue::VERSION})
  puts "Benchmarking with #{outer * inner} jobs"

  ActiveJob::Base.queue_adapter = :good_job
  x.report("good_job-pushbulk") do
    GoodJob::Bulk.enqueue do
      outer.times do
        inner.times do
          RoundupJob.perform_later(123, "hello world", hash)
        end
      end
    end
  end

  x.report("good_job-push") do
    outer.times do
      inner.times do
        RoundupJob.perform_later(123, "hello world", hash)
      end
    end
  end

  ActiveJob::Base.queue_adapter = :solid_queue
  x.report("solid_queue-push") do
    outer.times do
      inner.times do
        RoundupJob.perform_later(123, "hello world", hash)
      end
    end
  end

  ActiveJob::Base.queue_adapter = :sidekiq
  x.report("sidekiq-push") do
    outer.times do
      inner.times do
        RoundupJob.perform_later(123, "hello world", hash)
      end
    end
  end

  x.report("sidekiq-native-enq") do
    outer.times do
      inner.times do
        RoundupWorker.perform_async(123, "hello world", hash)
      end
    end
  end

  x.report("sidekiq-native-enq-bulk") do
    total = outer * inner
    RoundupWorker.perform_bulk(total.times.map { [123, "hello world", hash] })
  end
end
