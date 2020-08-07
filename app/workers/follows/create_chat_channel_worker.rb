module Follows
  class CreateChatChannelWorker
    include Sidekiq::Worker
    sidekiq_options queue: :medium_priority, retry: 10

    def perform(follow_id)
      follow = Follow
        .includes(:follower, :followable)
        .find_by(id: follow_id, follower_type: "User", followable_type: "User")
      return unless follow&.followable&.following?(follow.follower)

      ChatChannels::CreateWithUsers.call(users: [follow.followable, follow.follower])
    end
  end
end
