class GistTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
  end

  def render(_context)
    html = <<~HTML
      <div class="ltag_gist-liquid-tag">
          <script id="gist-ltag" src="#{@link}.js"></script>
      </div>
    HTML
    finalize_html(html)
  end

  def self.special_script
    <<~JAVASCRIPT
      if (postscribe) {
        var els = document.getElementsByClassName("ltag_gist-liquid-tag")
        for (i = 0; i < els.length; i++) {
            postscribe(els[i], els[i].firstElementChild.outerHTML);
        }
      }
    JAVASCRIPT
  end

  private

  def parse_link(link)
    link = ActionController::Base.helpers.strip_tags(link)
    input_no_space = link.delete(" ").gsub(".js", "")
    if valid_link?(input_no_space)
      input_no_space
    else
      raise StandardError,
        "Invalid Gist link: #{link} Links must follow this format: https://gist.github.com/username/gist_id"
    end
  end

  def valid_link?(link)
    (link =~ /\Ahttps\:\/\/gist\.github\.com\/([a-zA-Z0-9\-]){1,39}\/([a-zA-Z0-9]){32}\Z/)&.
      zero?
  end
end

Liquid::Template.register_tag("gist", GistTag)
