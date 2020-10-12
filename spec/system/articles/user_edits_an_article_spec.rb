require "rails_helper"

RSpec.describe "Editing with an editor", type: :system, js: true do
  let(:template) { file_fixture("article_published.txt").read }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, body_markdown: template) }

  before do
    sign_in user
  end

  it "user previews their changes" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Preview")
    expect(page).to have_text("Yooo")
  end

  it "user updates their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Save changes")
    expect(page).to have_text("Yooo")
  end

  it "user unpublishes their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in("article_body_markdown", with: template.gsub("true", "false"), fill_options: { clear: :backspace })
    click_button("Save changes")
    expect(page).to have_text("Unpublished Post.")
  end
end
