require "rails_helper"

RSpec.describe MarkdownParser do
  let(:random_word) { Faker::Lorem.word }
  let(:basic_parsed_markdown) { described_class.new(random_word) }

  def generate_and_parse_markdown(raw_markdown)
    described_class.new(raw_markdown).finalize
  end

  it "works" do
    expect(basic_parsed_markdown.finalize).to include(random_word)
  end

  it "escape liquid tags in codeblock" do
    code_block = "```\n{% what %}\n```"
    expect(generate_and_parse_markdown(code_block)).to include("{% what %}")
  end

  it "escape liquid tags in inline code" do
    inline_code = "`{% what %}`"
    expect(generate_and_parse_markdown(inline_code)).to include(inline_code[1..-2])
  end

  context "when provided with an @username" do
    it "links to a user if user exist" do
      username = create(:user).username
      with_user = "@#{username}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a").to_s).to include("/#{username}")
    end

    it "doesn't link to a user if user doesn't exist" do
      with_user = "@#{random_word}"
      html = Nokogiri::HTML(generate_and_parse_markdown(with_user))
      expect(html.search("a")).to be_empty
    end
  end

  context "when provided with nested links" do
    it "does not generated nested link tags" do
      nested_links = generate_and_parse_markdown("[[](http://b)](http://a)")
      nested_links = Nokogiri::HTML(nested_links).at("p").inner_html
      expect(nested_links).to eq('[<a href="http://b"></a>](<a href="http://a">http://a</a>)')
    end
  end

  context "when provided with liquid tags" do
    it "raises error if liquid tag was used incorrectly" do
      bad_ltag = "{% #{random_word} %}"
      expect { generate_and_parse_markdown(bad_ltag) }.to raise_error(StandardError)
    end
  end

  describe "#tags_used" do
    let(:parsed_markdown) { described_class.new("{% youtube oHg5SJYRHA0 %}") }

    it "returns empty if no tag was used" do
      expect(basic_parsed_markdown.tags_used).to eq([])
    end

    it "return tags used if it was used" do
      expect(parsed_markdown.tags_used).to eq([YoutubeTag])
    end
  end

  context "when an image is used" do
    it "wraps image in link" do
      inline_code = "![](https://image.com/image.jpg)"
      expect(generate_and_parse_markdown(inline_code)).to include("<a")
    end

    it "replaces image with picture tag" do
      inline_code = "![](https://image.com/image.jpg)"
      expect(generate_and_parse_markdown(inline_code)).to include("<a")
    end

  end
end
