require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let_it_be(:user) { create(:user) }
  let_it_be(:moderator) { create(:user, :trusted) }
  let_it_be(:article, reload: true) { create(:article, :with_notification_subscription, user: user) }
  let(:timestamp) { "2019-03-04T10:00:00Z" }

  before do
    sign_in moderator
    visit "/#{user.username}/#{article.slug}/mod"
  end

  it "shows an article" do
    visit "/#{user.username}/#{article.slug}"
    expect(page).to have_content(article.title)
  end

  it "lets moderators visit /mod" do
    visit "/#{user.username}/#{article.slug}/mod"
    expect(page).to have_content("Moderate: #{article.title}")
    expect(page).to have_selector('button[data-category="thumbsdown"][data-reactable-type="Article"]')
    expect(page).to have_selector('button[data-category="vomit"][data-reactable-type="Article"]')
    expect(page).to have_selector('button[data-category="vomit"][data-reactable-type="User"]')
    expect(page).to have_selector("button.level-rating-button")
  end
end
