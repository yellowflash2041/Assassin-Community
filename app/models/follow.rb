class Follow < ApplicationRecord
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, polymorphic: true
  belongs_to :follower,   polymorphic: true
  counter_culture :follower, column_name: proc { |follow|
    case follow.followable_type
    when "User"
      "following_users_count"
    when "Organization"
      "following_orgs_count"
    when "ActsAsTaggableOn::Tag"
      "following_tags_count"
      # add more whens if we add more follow types
    end
  }, column_names: {
    ["follows.followable_type = ?", "User"] => "following_users_count",
    ["follows.followable_type = ?", "Organization"] => "following_orgs_count",
    ["follows.followable_type = ?", "ActsAsTaggableOn::Tag"] => "following_tags_count"
  }
  after_save :touch_follower
  after_create :send_email_notification, :create_chat_channel
  before_destroy :modify_chat_channel_status

  validates :followable_id, uniqueness: { scope: %i[followable_type follower_id] }

  private

  def touch_follower
    Follows::TouchFollowerJob.perform_later(id)
  end

  def create_chat_channel
    return unless followable_type == "User"

    Follows::CreateChatChannelJob.perform_later(id)
  end

  def send_email_notification
    return unless followable.class.name == "User" && followable.email?

    Follows::SendEmailNotificationJob.perform_later(id)
  end

  # TODO: remove methods #touch_user, #touch_user_followed_at, #create_chat_channel_without_delay, #send_email_notification_without_delay
  def touch_user
    follower.touch
  end
  handle_asynchronously :touch_user

  def touch_user_followed_at
    follower.touch(:last_followed_at)
  end
  handle_asynchronously :touch_user_followed_at

  # *_without_delay method will be used if there're jobs created before introducing ActiveJob
  def create_chat_channel_without_delay
    if followable_type == "User" && followable.following?(follower)
      ChatChannel.create_with_users([followable, follower])
    end
  end

  def send_email_notification_without_delay
    if followable.class.name == "User" && followable.email.present? && followable.email_follower_notifications
      return if EmailMessage.where(user_id: followable.id).
        where("sent_at > ?", rand(15..35).hours.ago).
        where("subject LIKE ?", "%followed you on dev.to%").any?

      NotifyMailer.new_follower_email(self).deliver
    end
  end

  def modify_chat_channel_status
    if followable_type == "User" && followable.following?(follower)
      channel = follower.chat_channels.
        where("slug LIKE ? OR slug like ?", "%/#{followable.username}%", "%#{followable.username}/%").
        first
      channel&.update(status: "inactive")
    end
  end
end
