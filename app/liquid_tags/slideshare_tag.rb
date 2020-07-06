class SlideshareTag < LiquidTagBase
  PARTIAL = "liquids/slideshare".freeze

  def initialize(_tag_name, key, _parse_context)
    super
    @key = validate(key.strip)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        key: @key,
        height: 450
      },
    )
  end

  private

  def validate(key)
    raise StandardError, "Invalid Slideshare Key" unless key.match?(/\A[a-zA-Z0-9]{14}\Z/)

    key
  end
end

Liquid::Template.register_tag("slideshare", SlideshareTag)
