require "rails_helper"

RSpec.describe "ArticlesShow", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:article, reload: true) { create(:article, user: user, published: true, organization: organization) }
  let_it_be(:organization) { create(:organization) }
  let(:doc) { Nokogiri::HTML(response.body) }
  let(:text) { doc.at('script[type="application/ld+json"]').text }
  let(:response_json) { JSON.parse(text) }

  describe "GET /:slug (articles)" do
    before do
      get article.path
    end

    it "returns a 200 status when navigating to the article's page" do
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it "renders the proper JSON-LD for an article" do
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Article",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.article(article)
        },
        "url" => URL.article(article),
        "image" => [
          ApplicationController.helpers.article_social_image_url(article, width: 1080, height: 1080),
          ApplicationController.helpers.article_social_image_url(article, width: 1280, height: 720),
          ApplicationController.helpers.article_social_image_url(article, width: 1600, height: 900),
        ],
        "publisher" => {
          "@context" => "http://schema.org",
          "@type" => "Organization",
          "name" => "#{ApplicationConfig['COMMUNITY_NAME']} Community",
          "logo" => {
            "@context" => "http://schema.org",
            "@type" => "ImageObject",
            "url" => ApplicationController.helpers.cloudinary(SiteConfig.logo_png, 192, 80, "png"),
            "width" => "192",
            "height" => "192"
          }
        },
        "headline" => article.title,
        "author" => {
          "@context" => "http://schema.org",
          "@type" => "Person",
          "url" => URL.user(user),
          "name" => user.name
        },
        "datePublished" => article.published_timestamp,
        "dateModified" => article.published_timestamp,
      )
    end
  end

  it "renders the proper organization for an article when one is present" do
    get organization.path
    expect(response_json).to include(
      {
        "@context" => "http://schema.org",
        "@type" => "Organization",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.organization(organization)
        },
        "url" => URL.organization(organization),
        "image" => ProfileImage.new(organization).get(width: 320),
        "name" => organization.name,
        "description" => organization.summary
      },
    )
  end
  # rubocop:enable RSpec/ExampleLength

  context "when keywords are set up" do
    it "shows keywords" do
      SiteConfig.meta_keywords = { article: "hello, world" }
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).to include('<meta name="keywords" content="super sheep, hello, world">')
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  context "when user not signed in" do
    before do
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get article.path + "?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
