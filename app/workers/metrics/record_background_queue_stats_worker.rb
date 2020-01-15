module Metrics
  class RecordBackgroundQueueStatsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      Loggers::LogWorkerQueueStats.run
    end
  end
end
