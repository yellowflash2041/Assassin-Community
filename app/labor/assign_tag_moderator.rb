module AssignTagModerator
  def self.add_tag_moderators(user_ids, tag_ids)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      tag = Tag.find(tag_ids[index])
      user.add_role(:tag_moderator, tag)
      ChatChannel.find_by(slug: "tag-moderators").add_users(user) if user.chat_channels.find_by(slug: "tag-moderators").blank?
      NotifyMailer.tag_moderator_confirmation_email(user, tag.name).deliver unless tag.name == "go"
    end
  end
end
