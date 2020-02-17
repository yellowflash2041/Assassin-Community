class PodcastEpisodeDecorator < ApplicationDecorator
  def comments_to_show_count
    cached_tag_list_array.include?("discuss") ? 75 : 25
  end

  # this method exists because podcast episodes are "commentables"
  # and in some parts of the code we assume they have this method,
  # but podcast episodes don't have a cached_tag_list like articles do
  def cached_tag_list_array
    tag_list
  end

  def readable_publish_date
    return "" unless published_at

    if published_at.year == Time.current.year
      published_at.strftime("%b %e")
    else
      published_at.strftime("%b %e '%y")
    end
  end

  def published_timestamp
    return "" unless published_at

    published_at.utc.iso8601
  end
end
