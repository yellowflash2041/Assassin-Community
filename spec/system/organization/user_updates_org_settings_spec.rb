require "rails_helper"

RSpec.describe "Organization setting page(/settings/organization)", type: :system, js: true do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    sign_in user
  end

  it "user creates an organization" do
    visit "settings/organization"
    fill_in_org_form
    click_button "SUBMIT"
    expect(page).to have_text("Your organization was successfully created and you are an admin.")
  end

  it "remove user from organization" do
    user.update(organization_id: organization.id, org_admin: true)
    user2 = create(:user, username: "newuser", organization_id: organization.id)
    visit "settings/organization"
    click_button("Remove from org")
    page.driver.browser.switch_to.alert.accept
    expect(page).not_to have_text(user2.name)
  end

  def fill_in_org_form
    fill_in "organization[name]", with: "Organization Name"
    fill_in "organization[slug]", with: "Organization"
    attach_file(
      "organization_profile_image",
      Rails.root.join("app", "assets", "images", "android-icon-36x36.png"),
    )
    fill_in "Text color (hex)", with: "#ffffff"
    fill_in "Background color (hex)", with: "#000000"
    fill_in "organization[url]", with: "http://company.com"
    fill_in "organization[summary]", with: "Summary"
    fill_in "organization[proof]", with: "Proof"
  end
end
