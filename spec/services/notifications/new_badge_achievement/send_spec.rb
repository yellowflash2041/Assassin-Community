require "rails_helper"

RSpec.describe Notifications::NewBadgeAchievement::Send, type: :service do
  let(:badge_achievement) { create(:badge_achievement) }

  def expected_json_data
    {
      user: Notifications.user_data(badge_achievement.user),
      badge_achievement: {
        badge_id: badge_achievement.badge_id,
        rewarding_context_message: badge_achievement.rewarding_context_message,
        badge: {
          title: badge_achievement.badge.title,
          description: badge_achievement.badge.description,
          badge_image_url: badge_achievement.badge.badge_image_url
        }
      }
    }.to_json
  end

  it "creates a notification" do
    expect do
      described_class.call(badge_achievement)
    end.to change(Notification, :count).by(1)
  end

  it "creates a notification for the badge achievement user" do
    notification = described_class.call(badge_achievement)
    expect(notification.user).to eq(badge_achievement.user)
  end

  it "creates a notification for the badge achievement" do
    notification = described_class.call(badge_achievement)
    expect(notification.notifiable_id).to eq(badge_achievement.id)
    expect(notification.notifiable_type).to eq("BadgeAchievement")
  end

  it "creates a notification with no action" do
    notification = described_class.call(badge_achievement)
    expect(notification.action).to be(nil)
  end

  it "creates a notification with the proper json data" do
    notification = described_class.call(badge_achievement)
    json_data = notification.json_data.to_json
    expect(JSON.parse(json_data)).to eq(JSON.parse(expected_json_data))
  end
end
