module DataUpdateScripts
  class IndexReadingListReactions
    def run
      Reaction.readinglist.select(:id).in_batches do |batch|
        Search::BulkIndexToElasticsearchWorker.set(queue: :default).perform_async(
          "Reaction", batch.pluck(:id)
        )
      end
    end
  end
end
