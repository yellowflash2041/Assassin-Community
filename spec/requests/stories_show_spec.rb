require "rails_helper"

RSpec.describe "StoriesShow", type: :request do
  let_it_be(:user)                  { create(:user) }
  let_it_be(:org, reload: true)     { create(:organization) }
  let_it_be(:article, reload: true) { create(:article, user: user) }

  describe "GET /:username/:slug (articles)" do
    it "renders proper title" do
      get article.path
      expect(response.body).to include CGI.escapeHTML(article.title)
    end

    it "redirects to appropriate if article belongs to org and user visits user version" do
      old_path = article.path
      article.update(organization: org)
      get old_path
      expect(response.body).to redirect_to article.path
      expect(response).to have_http_status(:moved_permanently)
    end

    ## Title tag
    it "renders signed-in title tag for signed-in user" do
      sign_in user
      get article.path
      expect(response.body).to include "<title>#{CGI.escapeHTML(article.title)} - #{community_qualified_name} 👩‍💻👨‍💻</title>"
    end

    it "renders signed-out title tag for signed-out user" do
      get article.path
      expect(response.body).to include "<title>#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
    end

    # search_optimized_title_preamble

    it "renders title tag with search_optimized_title_preamble if set and not signed in" do
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.reload.path
      expect(response.body).to include "<title>Hey this is a test: #{CGI.escapeHTML(article.title)} - #{community_name}</title>"
    end

    it "does not render title tag with search_optimized_title_preamble if set and not signed in" do
      sign_in user
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.path
      expect(response.body).to include "<title>#{CGI.escapeHTML(article.title)} - #{community_qualified_name} 👩‍💻👨‍💻</title>"
    end

    it "does not render preamble with search_optimized_title_preamble not signed in but search_optimized_title_preamble not set" do
      get article.path
      expect(response.body).to include "#{CGI.escapeHTML(article.title)} - #{community_name}</title>"
    end

    it "renders title preamble with search_optimized_title_preamble if set and not signed in" do
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.reload.path
      expect(response.body).to include "<span class=\"article-title-preamble\">Hey this is a test</span>"
    end

    it "does not render preamble with search_optimized_title_preamble if set and signed in" do
      sign_in user
      article.update_column(:search_optimized_title_preamble, "Hey this is a test")
      get article.path
      expect(response.body).not_to include "<span class=\"article-title-preamble\">Hey this is a test</span>"
    end

    it "does not render title tag with search_optimized_title_preamble not signed in but search_optimized_title_preamble not set" do
      get article.path
      expect(response.body).not_to include "<span class=\"article-title-preamble\">Hey this is a test</span>"
    end

    it "renders user payment pointer if set" do
      article.user.update_column(:payment_pointer, "this-is-a-pointer")
      get article.path
      expect(response.body).to include "author-payment-pointer"
      expect(response.body).to include "this-is-a-pointer"
    end

    it "does not render payment pointer if not set" do
      get article.path
      expect(response.body).not_to include "author-payment-pointer"
    end

    it "renders second and third users if present" do
      # 3rd user doesn't seem to get rendered for some reason
      user2 = create(:user)
      article.update(second_user_id: user2.id)
      get article.path
      expect(response.body).to include "<em>with <b><a href=\"#{user2.path}\">"
    end

    it "renders articles of long length without breaking" do
      # This is a pretty weak test, just to exercise different lengths with no breakage
      article.update(title: (0...75).map { rand(65..90).chr }.join)
      get article.path
      article.update(title: (0...100).map { rand(65..90).chr }.join)
      get article.path
      article.update(title: (0...118).map { rand(65..90).chr }.join)
      get article.path
      expect(response.body).to include "title"
    end

    it "redirects to appropriate page if user changes username" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to appropriate page if user changes username twice" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{old_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to appropriate page if user changes username twice and go to middle username" do
      user.update(username: "new_hotness_#{rand(10_000)}")
      middle_username = user.username
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{middle_username}/#{article.slug}"
      expect(response.body).to redirect_to("/#{user.username}/#{article.slug}")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "renders canonical url when exists" do
      article = create(:article, with_canonical_url: true)
      get article.path
      expect(response.body).to include(%("canonical" href="#{article.canonical_url}"))
    end

    it "does not render canonical url when not on article model" do
      article = create(:article, with_canonical_url: false)
      get article.path
      expect(response.body).not_to include(%("canonical" href="#{article.canonical_url}"))
    end

    it "handles invalid slug characters" do
      allow(Article).to receive(:find_by).and_raise(ArgumentError)
      get article.path

      expect(response.status).to be(400)
    end

    it "has noindex if article has low score" do
      article = create(:article, score: -5)
      get article.path
      expect(response.body).to include("noindex")
    end

    it "has noindex if article has low score even with <code>" do
      article = create(:article, score: -5)
      article.update_column(:processed_html, "<code>hello</code>")
      get article.path
      expect(response.body).to include("noindex")
    end

    it "does not have noindex if article has high score" do
      article = create(:article, score: 6)
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "does not have noindex if article intermediate score and <code>" do
      article = create(:article, score: 3)
      article.update_column(:processed_html, "<code>hello</code>")
      get article.path
      expect(response.body).not_to include("noindex")
    end

    it "does not have noindex if article w/ intermediate score w/ 1 comment " do
      article = create(:article, score: 3)
      article.user.update_column(:comments_count, 1)
      get article.path
      expect(response.body).not_to include("noindex")
    end
  end

  describe "GET /:username (org)" do
    it "redirects to the appropriate page if given an organization's old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects to the appropriate page if given an organization's old old slug" do
      original_slug = org.slug
      org.update(slug: "somethingnew")
      org.update(slug: "anothernewslug")
      get "/#{original_slug}"
      expect(response.body).to redirect_to org.path
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
