class RoundupJob < ApplicationJob
  queue_as :default

  class Sidekiq < RoundupJob
    self.queue_adapter = :sidekiq
  end

  class Goodjob < RoundupJob
    self.queue_adapter = :good_job
  end

  class Solidqueue < RoundupJob
    self.queue_adapter = :solid_queue
  end
end
