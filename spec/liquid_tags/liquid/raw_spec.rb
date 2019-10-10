require "rails_helper"

RSpec.describe Liquid::Raw, type: :liquid_template do
  it "does not allow non whitespace characters in between the tags" do
    invalid_markdown = '<img src="x" class="before{% raw %}inside{% endraw ">%}rawafter"onerror=alert(document.domain) '
    expect { Liquid::Template.parse(invalid_markdown) }.to raise_error(StandardError)
  end

  it "raise error message when link tag contain non article URL" do
    invalid_markdown = "{% link /some-random-link/ %}"
    expect { Liquid::Template.parse(invalid_markdown) }.to(
      raise_error(StandardError, "This URL is not an article link: {% link /some-random-link/ %}"),
    )
  end
end
