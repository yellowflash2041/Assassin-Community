require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let_it_be(:user) { create(:user) }
  let_it_be_changeable(:article) do
    create(:article, :with_notification_subscription, user: user)
  end
  let(:timestamp) { "2019-03-04T10:00:00Z" }

  before do
    sign_in user
  end

  it "shows an article", js: true, percy: true do
    visit article.path
    Percy.snapshot(page, name: "Article: renders")
    expect(page).to have_content(article.title)
  end

  it "shows comments", js: true, percy: true do
    create_list(:comment, 3, commentable: article)

    visit article.path
    Percy.snapshot(page, name: "Article: shows comments")
    expect(page).to have_selector(".single-comment-node", visible: :visible, count: 3)
  end

  it "stops a user from moderating an article" do
    expect { visit("/#{user.username}/#{article.slug}/mod") }.to raise_error(Pundit::NotAuthorizedError)
  end

  describe "when showing the date" do
    before do
      article.update_columns(published_at: Time.zone.parse(timestamp))
    end

    it "shows the readable publish date", js: true do
      visit article.path
      expect(page).to have_selector("article time", text: "Mar 4")
    end

    it "embeds the published timestamp" do
      visit article.path

      selector = "article time[datetime='#{timestamp}']"
      expect(page).to have_selector(selector)
    end
  end

  describe "when articles belong to a collection" do
    let_it_be_readonly(:collection) { create(:collection) }
    let(:articles_selector) { "//div[@class='article-collection']//a" }

    context "with regular articles" do
      it "lists the articles in ascending published_at order" do
        articles = create_list(:article, 2)
        articles.first.update(published_at: 1.week.ago)
        articles.each { |a| a.update_columns(collection_id: collection.id) }

        visit articles.first.path

        elements = page.all(:xpath, articles_selector)
        paths = elements.map { |e| e[:href] }
        expect(paths).to eq([articles.first.path, articles.second.path])
      end
    end

    context "when a crossposted article is between two regular articles" do
      let(:article1) { create(:article) }
      let(:crossposted_article) { create(:article) }
      let(:article2) { create(:article) }

      # TODO: Uncomment this spec when we decide to use percy again
      xit "renders the articles in ascending order considering crossposted_at", js: true, percy: true do
        visit article1.path
        Percy.snapshot(page, name: "Articles: renders crossposted articles")
      end

      # rubocop:disable RSpec/ExampleLength
      it "lists the articles in ascending order considering crossposted_at" do
        article1.update_columns(
          collection_id: collection.id,
          published_at: Time.zone.parse("2020-03-15T13:50:09Z"),
        )

        crossposted_article.update_columns(
          canonical_url: Faker::Internet.url,
          collection_id: collection.id,
          crossposted_at: Time.zone.parse("2020-03-21T10:25:00Z"),
          feed_source_url: Faker::Internet.url,
          published_at: Time.zone.parse("2020-02-21T06:00:00Z"),
          published_from_feed: true,
        )

        article2.update_columns(collection_id: collection.id)

        visit article1.path

        expected_paths = [article1.path, crossposted_article.path, article2.path]

        elements = page.all(:xpath, articles_selector)
        paths = elements.map { |e| e[:href] }
        expect(paths).to eq(expected_paths)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
