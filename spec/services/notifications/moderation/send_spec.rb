require "rails_helper"

RSpec.describe Notifications::Moderation::Send do
  let(:last_moderation_time) { Time.zone.now - Notifications::Moderation::MODERATORS_AVAILABILITY_DELAY - 3.hours }
  let(:dev_account) { create(:user) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:available_moderators) { Notifications::Moderation.available_moderators }
  let(:moderator) { available_moderators.first }

  before do
    create(:user, :trusted, last_moderation_notification: last_moderation_time)
    allow(User).to receive(:dev_account).and_return(dev_account)
    # Creating a comment calls moderation job which itself call moderation service
    Comment.skip_callback(:create, :after, :send_to_moderator)
  end

  after do
    Comment.set_callback(:create, :after, :send_to_moderator)
  end

  it "calls comment_data since parameter is a comment" do
    allow(Notifications).to receive(:comment_data)
    described_class.call(moderator, comment)
    expect(Notifications).to have_received(:comment_data)
  end

  it "checks whether Notification is inserted on DB" do
    expect do
      described_class.call(moderator, comment)
    end.to change(Notification, :count).by(1)
  end

  it "checks whether created Notification is valid", :aggregate_failures do
    notification = described_class.call(moderator, comment)
    expect(notification).to be_a Notification
    expect(notification.action).to eq "Moderation"
    expect(notification.notifiable_type).to eq "Comment"
    expect(notification.user_id).to eq moderator.id
    expect(notification.notifiable_id).to eq comment.id
  end

  it "checks that moderator last notification time updates" do
    expect do
      described_class.call(moderator, comment)
    end.to change(moderator, :last_moderation_notification)
  end
end
