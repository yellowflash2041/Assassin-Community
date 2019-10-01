require "rails_helper"

RSpec.describe MediumArticleRetrievalService, vcr: {} do
  let(:expected_response) do
    {
      title: "My Ruby Journey: Hooking Things Up - Fave Product & Engineering - Medium",
      author: "Edison Yap",
      author_image: "https://miro.medium.com/fit/c/96/96/1*qFzi921ix0_kkrFMKYgELw.jpeg",
      reading_time: "4 min read",
      url: "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c"
    }
  end

  context "when valid medium url" do
    let(:medium_url) { "https://medium.com/@edisonywh/my-ruby-journey-hooking-things-up-91d757e1c59c" }

    it "returns a valid response" do
      VCR.use_cassette("medium") do
        html = HTTParty.get(medium_url)
        stub_request(:get, medium_url).to_return(body: html.body, status: 200)
        expect(described_class.call(medium_url)).to eq(expected_response)
      end
    end
  end
end
