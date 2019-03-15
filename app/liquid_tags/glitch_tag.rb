require "uri"

class GlitchTag < LiquidTagBase
  attr_accessor :uri
  def initialize(tag_name, id, tokens)
    super
    @uri = build_uri(id)
    @id = parse_id(id)
  end

  def render(_context)
    html = <<-HTML
      <div class="glitch-embed-wrap" style="height: 450px; width: 100%;margin: 1em auto 1.3em">
        <iframe
          sandbox="allow-same-origin allow-scripts allow-forms allow-top-navigation-by-user-activation"
          src="#{@uri}"
          alt="#{@id} on glitch"
          style="height: 100%; width: 100%; border: 0;margin:0;padding:0"></iframe>
      </div>
    HTML
    finalize_html(html)
  end

  private

  def valid_id?(input)
    (input =~ /^[a-zA-Z0-9\-]{1,110}$/)&.zero?
  end

  def parse_id(input)
    id = input.split(" ").first
    raise StandardError, "Invalid Glitch ID" unless valid_id?(id)

    id
  end

  def valid_option(option)
    option.match(/(app|code|no-files|preview-first|no-attribution|file\=\w(\.\w)?)/)
  end

  def option_to_query_pair(option)
    case option
    when "app"
      %w[previewSize 100]
    when "code"
      %w[previewSize 0]
    when "no-files"
      %w[sidebarCollapsed true]
    when "preview-first"
      %w[previewFirst true]
    when "no-attribution"
      %w[attributionHidden true]
    end
  end

  def build_options(options)
    # Convert options to query param pairs
    params = options.map { |x| option_to_query_pair(x) }.compact

    # Deal with the file option if present or use default
    file_option = options.detect { |x| x.start_with?("file=") }
    path = file_option ? (file_option.sub! "file=", "") : "index.html"
    params.push ["path", path]

    # Encode the resulting pairs as a query string
    URI.encode_www_form(params)
  end

  def parse_options(input)
    _, *options = input.split(" ")

    # 'app' and 'code' should cancel each other out
    options -= %w[app code] if (options & %w[app code]) == %w[app code]

    # Validation
    validated_options = options.map { |o| valid_option(o) }.reject(&:nil?)
    raise StandardError, "Invalid Options" unless options.empty? || !validated_options.empty?

    build_options(options)
  end

  def build_uri(input)
    id = parse_id(input)
    query = parse_options(input)
    "https://glitch.com/embed/#!/embed/#{id}?#{query}"
  end
end

Liquid::Template.register_tag("glitch", GlitchTag)
