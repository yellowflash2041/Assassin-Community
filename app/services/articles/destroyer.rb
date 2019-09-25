module Articles
  module Destroyer
    module_function

    def call(article, event_dispatcher = Webhook::DispatchEvent)
      article.destroy!
      Notification.remove_all_without_delay(notifiable_ids: article.id, notifiable_type: "Article")
      Notification.remove_all(notifiable_ids: article.comments.pluck(:id), notifiable_type: "Comment") if article.comments.exists?
      event_dispatcher.call("article_destroyed", article) if article.published?
    end
  end
end
