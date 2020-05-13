module Articles
  class Creator
    def initialize(user, article_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @article_params = article_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      rate_limit!

      article = save_article

      if article.persisted?
        NotificationSubscription.create(user: user, notifiable_id: article.id, notifiable_type: "Article", config: "all_comments")
        Notification.send_to_followers(article, "Published") if article.published?

        dispatch_event(article)
      end

      article
    end

    private

    attr_reader :user, :article_params, :event_dispatcher

    def rate_limit!
      user.rate_limiter.check_limit!(:published_article_creation)
    end

    def dispatch_event(article)
      return unless article.published?

      event_dispatcher.call("article_created", article)
    end

    def save_article
      series = article_params[:series]
      tags = article_params[:tags]

      # convert tags from array to a string
      if tags.present?
        article_params.delete(:tags)
        article_params[:tag_list] = tags.join(", ")
      end

      article = Article.new(article_params)
      article.user_id = user.id
      article.show_comments = true
      article.collection = Collection.find_series(series, user) if series.present?
      article.save
      article
    end
  end
end
