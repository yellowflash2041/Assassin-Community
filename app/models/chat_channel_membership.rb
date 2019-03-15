class ChatChannelMembership < ApplicationRecord
  belongs_to :chat_channel
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: :chat_channel_id }
  validates :chat_channel_id, presence: true, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: %w[active inactive pending rejected left_channel] }
  validates :role, inclusion: { in: %w[member mod] }
  validate  :permission

  private

  def permission
    errors.add(:user_id, "is not allowed in chat") if chat_channel.direct? && chat_channel.slug.split("/").exclude?(user.username)
    # To be possibly implemented in future
    # if chat_channel.users.size > 128
    #   errors.add(:base, "too many members in channel")
    # end
  end
end
