module Tags
  class ResaveSupportedTagsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 5

    def perform
      Tag.where(supported: true).find_each(&:save)
    end
  end
end
