class RssReader
  class Assembler
    def self.call(item, user, feed, feed_source_url)
      new(item, user, feed, feed_source_url).assemble
    end

    def initialize(item, user, feed, feed_source_url)
      @item = item
      @title = item[:title].strip
      @categories = item[:categories] || []
      @user = user
      @feed = feed
      @feed_source_url = feed_source_url
    end

    def assemble
      body = <<~HEREDOC
        ---
        title: #{@title}
        published: false
        tags: #{get_tags}
        canonical_url: #{@user.feed_mark_canonical ? @feed_source_url : ''}
        ---

        #{assemble_body_markdown}
      HEREDOC

      body.strip
    end

    private

    def get_tags
      @categories.first(4).map { |tag| tag[0..19] }.join(",")
    end

    def assemble_body_markdown
      cleaned_content = HtmlCleaner.new.clean_html(get_content)
      cleaned_content = thorough_parsing(cleaned_content, @feed.url)
      ReverseMarkdown.
        convert(cleaned_content, github_flavored: true).
        gsub("```\n\n```", "").gsub(/&nbsp;|\u00A0/, " ")
    end

    def get_content
      @item.content || @item.summary || @item.description
    end

    def thorough_parsing(content, feed_url)
      html_doc = Nokogiri::HTML(content)
      find_and_replace_possible_links!(html_doc)
      if feed_url.include?("medium.com")
        parse_and_translate_gist_iframe!(html_doc)
        parse_and_translate_youtube_iframe!(html_doc)
        parse_and_translate_tweet!(html_doc)
      else
        clean_relative_path!(html_doc, feed_url)
      end
      html_doc.to_html
    end

    def parse_and_translate_gist_iframe!(html_doc)
      html_doc.css("iframe").each do |iframe|
        a_tag = iframe.css("a")
        next if a_tag.empty?

        possible_link = a_tag[0].inner_html
        if /medium\.com\/media\/.+\/href/.match?(possible_link)
          real_link = HTTParty.head(possible_link).request.last_uri.to_s
          return unless real_link.include?("gist.github.com")

          iframe.name = "p"
          iframe.keys.each { |attr| iframe.remove_attribute(attr) }
          iframe.inner_html = "{% gist #{real_link} %}"
        end
      end
      html_doc
    end

    def parse_and_translate_tweet!(html_doc)
      html_doc.search("style").remove
      html_doc.search("script").remove
      html_doc.css("blockquote").each do |bq|
        bq_with_p = bq.css("p")
        next if bq_with_p.empty?

        second_content = bq_with_p.css("p")[1].css("a")[0].attributes["href"].value
        if bq_with_p.length == 2 && second_content.include?("twitter.com")
          bq.name = "p"
          tweet_id = second_content.scan(/\/status\/(\d{10,})/).flatten.first
          bq.inner_html = "{% tweet #{tweet_id} %}"
        end
      end
    end

    def parse_and_translate_youtube_iframe!(html_doc)
      html_doc.css("iframe").each do |iframe|
        if /youtube\.com/.match?(iframe.attributes["src"].value)
          iframe.name = "p"
          youtube_id = iframe.attributes["src"].value.scan(/embed%2F(.{4,12})%3F/).flatten.first
          iframe.keys.each { |attr| iframe.remove_attribute(attr) }
          iframe.inner_html = "{% youtube #{youtube_id} %}"
        end
      end
    end

    def clean_relative_path!(html_doc, url)
      html_doc.css("img").each do |img_tag|
        path = img_tag.attributes["src"].value
        img_tag.attributes["src"].value = URI.join(url, path).to_s if path.start_with? "/"
      end
    end

    def find_and_replace_possible_links!(html_doc)
      html_doc.css("a").each do |a_tag|
        link = a_tag.attributes["href"]&.value
        next unless link

        found_article = Article.find_by(feed_source_url: link)&.decorate
        a_tag.attributes["href"].value = found_article.url if found_article
      end
    end
  end
end
