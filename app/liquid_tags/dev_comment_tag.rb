class DevCommentTag < LiquidTagBase
  attr_reader :id_code, :comment

  def initialize(_tag_name, id_code, _tokens)
    @id_code = parse_id(id_code)
    @comment = find_comment
  end

  def render(_context)
    raise_error unless @comment
    <<-HTML
    <div class="liquid-comment">
      <div class="details">
        <a href="/#{@comment.user.username}">
          <img class="profile-pic" src="#{ProfileImage.new(@comment.user).get(50)}"
            alt="#{@comment.user.username} profile image"/>
        </a>
        <a href="/#{@comment.user.username}">
          <span class="comment-username">#{@comment.user.name}</span>
        </a>
        <div class="comment-date" data-published-timestamp="#{@comment.decorate.published_timestamp}">
          <a href="#{@comment.path}">#{@comment.readable_publish_date}</a>
        </div>
      </div>
      <div class="body">
        #{@comment.processed_html.html_safe}
      </div>
    </div>
    HTML
  end

  def render_twitter_and_github
    result = ""
    if @comment.user.twitter_username.present?
      result += "<a href=\"https://twitter.com/#{@comment.user.twitter_username}\">" \
        +image_tag("/assets/twitter-logo.svg", class: "icon-img", alt: "twitter") + \
        "</a>"
    end
    return unless @comment.user.github_username.present?

    result + "<a href=\"https://github.com/#{@comment.user.github_username}\">" \
      +image_tag("/assets/github-logo.svg", class: "icon-img", alt: "github") + \
      "</a>"
  end

  private

  def parse_id(id)
    id_no_space = id.delete(" ")
    raise_error unless valid_id?(id_no_space)
    id_no_space
  end

  def find_comment
    comment = Comment.find_by_id(@id_code.to_i(26))
    raise_error unless comment
    comment
  end

  def valid_id?(id)
    id.length < 10 && id =~ /^[a-zA-Z0-9]*$/
  end

  def raise_error
    raise StandardError, "Invalid comment ID or comment does not exist"
  end
end

Liquid::Template.register_tag("devcomment", DevCommentTag)
