require "rails_helper"

RSpec.describe "AdditionalContentBoxes", type: :request do
  let(:tag) { create(:tag) }
  let(:user) { create(:user) }
  let(:regular_article) { create(:article, user: user, tags: [tag.name]) }

  describe "GET /additional_content_boxes" do
    it "returns an article if there is a published/featured one" do
      suggestion = build_stubbed(:article, published: true, featured: true, path: "blah")
      suggestion.title = "Title of the article"

      fake = instance_double(Suggester::Articles::Classic)
      allow(Suggester::Articles::Classic).to receive(:new).and_return(fake)
      allow(fake).to receive(:get).and_return([suggestion])

      get "/additional_content_boxes?article_id=#{regular_article.id}&state=include_sponsors"
      expect(response.body).to include CGI.escapeHTML(suggestion.title)
    end

    it "returns no article if not published/featured" do
      suggestion = create(:article)
      get "/additional_content_boxes?article_id=#{regular_article.id}&state=include_sponsors"
      expect(response.body).not_to include CGI.escapeHTML(suggestion.title)
    end

    it "returns boosted article if available" do
      organization = create(:organization)
      create(:article, published: true, featured: true)
      boosted_sugg = create(:article, tags: [tag.name], featured: true, boosted_additional_articles: true, organization_id: organization.id)
      get "/additional_content_boxes?article_id=#{regular_article.id}&state=include_sponsors"
      expect(response.body).to include CGI.escapeHTML(boosted_sugg.title)
    end
  end
end
