require "rails_helper"

RSpec.describe "Infinite scroll on dashboard", type: :system, js: true do
  let(:default_per_page) { 3 }
  let(:total_records) { default_per_page * 2 }
  let(:user) { create(:user) }
  let!(:users) { create_list(:user, total_records) }
  let!(:tags) { create_list(:tag, total_records) }
  let!(:organizations) { create_list(:organization, total_records) }
  let!(:podcasts) { create_list(:podcast, total_records) }

  before do
    sign_in user
  end

  context "when /dashboard/user_followers is visited" do
    before do
      users.each do |u|
        create(:follow, follower: u, followable: user)
      end

      visit "/dashboard/user_followers?per_page=#{default_per_page}"
    end

    # TODO: Uncomment this spec when we decide to use percy again
    xit "renders the page", percy: true do
      Percy.snapshot(page, name: "Homepage: /dashboard/user_followers?per_page= infinite scroll")
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_tags is visited" do
    before do
      tags.each do |tag|
        create(:follow, follower: user, followable: tag)
      end
      visit dashboard_following_tags_path(per_page: default_per_page)

      page.execute_script("window.scrollTo(0, 100000)")
    end

    it "scrolls through all tags" do
      page.assert_selector('div[id^="follows"]', count: total_records)
    end

    it "updates a tag point value" do
      last_div = page.all('div[id^="follows"]').last
      within last_div do
        fill_in "follow_points", with: 10.0
        click_button "commit"
      end
      first_div = page.find('div[id^="follows"]', match: :first)
      within first_div do
        expect(page).to have_field("follow_points", with: 10.0)
      end
    end
  end

  context "when /dashboard/following_users is visited" do
    before do
      users.each do |u|
        create(:follow, follower: user, followable: u)
      end

      visit dashboard_following_users_path(per_page: default_per_page)
    end

    # TODO: Uncomment this spec when we decide to use percy again
    xit "renders the page", percy: true do
      Percy.snapshot(page, name: "Homepage: /dashboard/following_users infinite scroll")
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_organizations is visited" do
    before do
      organizations.each do |organization|
        create(:follow, follower: user, followable: organization)
      end

      visit dashboard_following_organizations_path(per_page: default_per_page)
    end

    # TODO: Uncomment this spec when we decide to use percy again
    xit "renders the page", percy: true do
      Percy.snapshot(page, name: "Homepage: /dashboard/following_organizations infinite scroll")
    end

    it "scrolls through all users" do
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_podcasts is visited" do
    before do
      podcasts.each do |podcast|
        create(:follow, follower: user, followable: podcast)
      end
      visit dashboard_following_podcasts_path(per_page: default_per_page)

      page.execute_script("window.scrollTo(0, 100000)")
    end

    it "scrolls through all podcasts" do
      page.assert_selector('div[id^="follows"]', count: total_records)
    end

    it "shows working links" do
      podcasts.each do |podcast|
        expect(page).to have_link(nil, href: "/" + podcast.path)
      end
    end
  end
end
