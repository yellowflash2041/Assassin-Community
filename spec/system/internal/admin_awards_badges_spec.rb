require "rails_helper"

RSpec.describe "Admin awards badges", type: :system do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:badges) { Badge.pluck(:title) }

  def award_two_badges
    find(:xpath, "//option[contains(text(), \"#{badges.last}\")]").select_option
    fill_in "usernames", with: "#{user.username}, #{user2.username}"
    fill_in "message_markdown", with: "He who controls the spice controls the universe."
    click_on "Award Badges"
  end

  before do
    create_list :badge, 5
    sign_in admin
    visit "/internal/badges"
  end

  it "loads the view" do
    expect(page).to have_content("Badges")
  end

  it "lists the badges" do
    badges.each do |badge|
      expect(page).to have_content(badge)
    end
  end

  it "awards badges" do
    expect { award_two_badges }.to change { user.badges.count }.by(1).
      and change { user2.badges.count }.by(1)
    expect(page).to have_content("BadgeRewarder task ran!")

    visit "/#{user.username}/"

    expect(page).to have_link(href: "/badge/#{Badge.last.slug}")
  end

  it "notifies users of new badges" do
    expect { award_two_badges }.to enqueue_job(Notifications::NewBadgeAchievementJob).
      exactly(2).times.
      and enqueue_job(BadgeAchievements::SendEmailNotificationJob).
      exactly(2).times
  end
end
