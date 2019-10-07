class CacheBuster
  TIMEFRAMES = [
    [1.week.ago, "week"], [1.month.ago, "month"], [1.year.ago, "year"], [5.years.ago, "infinity"]
  ].freeze

  def bust(path)
    return unless Rails.env.production?

    HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}",
                  headers: { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"] })
    HTTParty.post("https://api.fastly.com/purge/https://dev.to#{path}?i=i",
                  headers: { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"] })
  rescue URI::InvalidURIError => e
    Rails.logger.error("Trying to bust cache of an invalid uri: #{e}")
  end

  def bust_comment(commentable)
    return unless commentable

    bust_article_comment(commentable) if commentable.is_a?(Article)
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)

    bust("#{commentable.path}/comments/")
    bust(commentable.path.to_s)
    commentable.comments.includes(:user).find_each do |comment|
      bust(comment.path)
      bust(comment.path + "?i=i")
    end
    bust("#{commentable.path}/comments/*")
  end

  def bust_article(article)
    bust("/" + article.user.username)
    bust(article.path)
    bust(article.path + "/")
    bust(article.path + "?i=i")
    bust(article.path + "/?i=i")
    bust(article.path + "/comments")
    bust(article.path + "?preview=" + article.password)
    bust(article.path + "?preview=" + article.password + "&i=i")
    bust("/#{article.organization.slug}") if article.organization.present?
    bust_home_pages(article)
    bust_tag_pages(article)
    bust("/api/articles/#{article.id}")
    return unless article.collection_id

    article.collection&.articles&.find_each do |collection_article|
      bust(collection_article.path)
    end
  end

  def bust_home_pages(article)
    if article.featured_number.to_i > Time.current.to_i
      bust("/")
      bust("?i=i")
    end
    if article.video.present? && article.featured_number.to_i > 10.days.ago.to_i
      CacheBuster.new.bust "/videos"
      CacheBuster.new.bust "/videos?i=i"
    end
    TIMEFRAMES.each do |timeframe|
      if Article.published.where("published_at > ?", timeframe[0]).
          order("positive_reactions_count DESC").limit(3).pluck(:id).include?(article.id)
        bust("/top/#{timeframe[1]}")
        bust("/top/#{timeframe[1]}?i=i")
        bust("/top/#{timeframe[1]}/?i=i")
      end
    end
    if article.published && article.published_at > 1.hour.ago
      bust("/latest")
      bust("/latest?i=i")
    end
    bust("/") if Article.published.order("hotness_score DESC").limit(4).pluck(:id).include?(article.id)
  end

  def bust_tag_pages(article)
    return unless article.published

    article.tag_list.each do |tag|
      if article.published_at.to_i > 2.minutes.ago.to_i
        bust("/t/#{tag}/latest")
        bust("/t/#{tag}/latest?i=i")
      end
      TIMEFRAMES.each do |timeframe|
        if Article.published.where("published_at > ?", timeframe[0]).tagged_with(tag).
            order("positive_reactions_count DESC").limit(3).pluck(:id).include?(article.id)
          bust("/top/#{timeframe[1]}")
          bust("/top/#{timeframe[1]}?i=i")
          bust("/top/#{timeframe[1]}/?i=i")
          12.times do |i|
            bust("/api/articles?tag=#{tag}&top=#{i}")
          end
        end
      end
      if rand(2) == 1 &&
          Article.published.tagged_with(tag).
              order("hotness_score DESC").limit(2).pluck(:id).include?(article.id)
        bust("/t/#{tag}")
        bust("/t/#{tag}?i=i")
      end
    end
  end

  def bust_page(slug)
    bust "/page/#{slug}"
    bust "/page/#{slug}?i=i"
    bust "/#{slug}"
    bust "/#{slug}?i=i"
  end

  def bust_tag(name)
    bust("/t/#{name}")
    bust("/t/#{name}?i=i")
    bust("/t/#{name}/?i=i")
    bust("/t/#{name}/")
    bust("/tags")
  end

  def bust_events
    bust("/events")
    bust("/events?i=i")
  end

  def bust_podcast(path)
    bust("/" + path)
  end

  def bust_organization(organization, slug)
    bust("/#{slug}")
    begin
      organization.articles.find_each do |article|
        bust(article.path)
      end
    rescue StandardError => e
      Rails.logger.error("Tag issue: #{e}")
    end
  end

  def bust_podcast_episode(podcast_episode, path, podcast_slug)
    podcast_episode.purge
    podcast_episode.purge_all
    begin
      bust(path)
      bust("/" + podcast_slug)
      bust("/pod")
      bust(path)
    rescue StandardError => e
      Rails.logger.warn(e)
    end
    podcast_episode.purge
    podcast_episode.purge_all
  end

  def bust_classified_listings(classified_listing)
    bust("/listings")
    bust("/listings?i=i")
    bust("/listings/#{classified_listing.category}/#{classified_listing.slug}")
    bust("/listings/#{classified_listing.category}/#{classified_listing.slug}?i=i")
    bust("/listings/#{classified_listing.category}")
  end

  def bust_user(user)
    username = user.username
    paths = [
      "/#{username}", "/#{username}?i=i",
      "/#{username}/comments",
      "/#{username}/comments?i=i", "/#{username}/comments/?i=i",
      "/live/#{username}", "/live/#{username}?i=i",
      "/feed/#{username}"
    ]
    paths.each { |path| bust(path) }
  end

  # bust commentable if it's an article
  def bust_article_comment(commentable)
    bust("/") if Article.published.order("hotness_score DESC").limit(3).pluck(:id).include?(commentable.id)
    if commentable.decorate.cached_tag_list_array.include?("discuss") &&
        commentable.featured_number.to_i > 35.hours.ago.to_i
      bust("/")
      bust("/?i=i")
      bust("?i=i")
    end
  end
end
