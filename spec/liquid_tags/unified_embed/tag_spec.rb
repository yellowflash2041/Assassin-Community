require "rails_helper"

RSpec.describe UnifiedEmbed::Tag, type: :liquid_tag do
  it "delegates parsing to the link-matching class" do
    link = "https://gist.github.com/jeremyf/662585f5c4d22184a6ae133a71bf891a"

    allow(GistTag).to receive(:new).and_call_original
    stub_head_request(link)
    parsed_tag = Liquid::Template.parse("{% embed #{link} %}")

    expect { parsed_tag.render }.not_to raise_error
    expect(GistTag).to have_received(:new)
  end

  it "delegates parsing to the link-matching class when there are options", vcr: true do
    link = "https://github.com/rust-lang/rust"

    allow(GithubTag).to receive(:new).and_call_original

    VCR.use_cassette("github_client_repository_no_readme") do
      stub_head_request(link)
      parsed_tag = Liquid::Template.parse("{% embed #{link} noreadme %}")

      expect { parsed_tag.render }.not_to raise_error
      expect(GithubTag).to have_received(:new)
    end
  end

  it "doesn't raise an error when link redirects" do
    link = "https://www.instagram.com/p/Ca2MhbCrK_t/"

    expect do
      stub_head_request(link, 301)
      Liquid::Template.parse("{% embed #{link} %}")
    end.not_to raise_error

    expect do
      stub_head_request(link, 302)
      Liquid::Template.parse("{% embed #{link} %}")
    end.not_to raise_error
  end

  it "raises an error when link cannot be found" do
    link = "https://takeonrules.com/goes-nowhere"

    expect do
      stub_head_request(link, 404)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided was not found; please check and try again")
  end

  it "raises an error when link returns unhandled http status" do
    link = "https://takeonrules.com/unhandled-response"

    expect do
      stub_head_request(link, 405)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "URL provided may have a typo or error; please check and try again")
  end

  it "raises an error when no link-matching class is found" do
    link = "https://takeonrules.com/about"

    expect do
      stub_head_request(link)
      Liquid::Template.parse("{% embed #{link} %}")
    end.to raise_error(StandardError, "Embeds for this URL are not supported")
  end
end
