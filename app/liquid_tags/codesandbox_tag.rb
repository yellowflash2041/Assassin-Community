class CodesandboxTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    '<iframe src="https://codesandbox.io/embed/' + @id + '"
      style="width:100%; height:calc(300px + 8vw); border:0; border-radius: 4px; overflow:hidden;"
      sandbox="allow-same-origin allow-scripts allow-forms allow-top-navigation-by-user-activation"
    </iframe>'
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid codesandbox Id"

    end
  end

  def valid_id?(id)
    id =~ /\A[a-zA-Z0-9\-]{0,60}\Z/
  end
end

Liquid::Template.register_tag("codesandbox", CodesandboxTag)
