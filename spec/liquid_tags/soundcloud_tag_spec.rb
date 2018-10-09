require "rails_helper"
require "nokogiri"

RSpec.describe SoundcloudTag, type: :liquid_template do
  describe "#link" do
    let(:soundcloud_link) { "https://soundcloud.com/user-261265215/dev-to-review-episode-2" }
    let(:evil_string) { "<SCRIPT SRC=//xss.rocks/.j>soundcloud.com</SCRIPT>" }
    let(:url_segment) { "https://w.soundcloud.com/player/?url" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("soundcloud", SoundcloudTag)
      Liquid::Template.parse("{% soundcloud #{link} %}")
    end

    def extract_iframe_src(rendered_iframe)
      parsed_iframe = Nokogiri.HTML(rendered_iframe)
      iframe_src = parsed_iframe.xpath("//iframe/@src")
      CGI::parse(iframe_src[0].value)
    end

    it "accepts soundcloud link" do
      liquid = generate_new_liquid(soundcloud_link)
      rendered_soundcloud_iframe = liquid.render
      Approvals.verify(rendered_soundcloud_iframe, name: "soundcloud_liquid_tag", format: :html)
    end

    it "rejects invalid soundcloud link" do
      expect do
        generate_new_liquid("invalid_soundcloud_link")
      end.to raise_error(StandardError)
    end

    it "strips script input" do
      allow(ActionController::Base.helpers).to receive(:strip_tags).and_return(evil_string)

      liquid = generate_new_liquid(evil_string)
      rendered_soundcloud_iframe = liquid.render
      iframe_src = extract_iframe_src(rendered_soundcloud_iframe)

      expect(iframe_src[url_segment]).not_to include("<SCRIPT SRC=//xss.rocks/.j>")
    end
  end
end
