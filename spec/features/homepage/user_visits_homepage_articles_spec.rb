require "rails_helper"

describe "User visits a homepage", type: :feature do
  let!(:article) { create(:article, reactions_count: 12, featured: true) }
  let!(:article2) { create(:article, reactions_count: 20) }
  let!(:bad_article) { create(:article, reactions_count: 0) }

  context "when no options specified" do
    before { visit "/" }

    it "shows the main article" do
      expect(page).to have_selector(".big-article", visible: true)
    end

    it "shows correct articles", js: true do
      expect(page).to have_selector(".single-article", count: 2)
      expect(page).to have_text(article.title)
      expect(page).to have_text(article2.title)
      expect(page).not_to have_text(bad_article.title)
    end
  end
end
