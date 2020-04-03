module Metrics
  class RecordDataCountsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      models = [User, Article, Organization, Comment, Podcast, PodcastEpisode, ClassifiedListing, PageView, Notification]
      models.each do |model|
        estimate = model.estimated_count
        Rails.logger.info("db_table_size", table_info: { table_name: model.table_name, table_size: estimate })
        DatadogStatsClient.gauge("postgres.db_table_size", estimate, tags: { table_name: model.table_name })

        next unless model.const_defined?(:SEARCH_CLASS)

        document_count = if model::SEARCH_CLASS.respond_to?("#{model.to_s.underscore.pluralize}_document_count")
                           model::SEARCH_CLASS.public_send("#{model.to_s.underscore.pluralize}_document_count")
                         else
                           model::SEARCH_CLASS.document_count
                         end
        DatadogStatsClient.gauge("elasticsearch.document_count", document_count, tags: { table_name: model.table_name })
      end
    end
  end
end
