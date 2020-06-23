module AssignTagModerator
  def self.add_trusted_role(user)
    return if user.has_role?(:trusted)
    return if user.has_role?(:banned)

    user.add_role :trusted
    user.update(email_community_mod_newsletter: true)
    MailchimpBot.new(user).manage_community_moderator_list
    Rails.cache.delete("user-#{user.id}/has_trusted_role")
    NotifyMailer.with(user: user).trusted_role_email.deliver_now
  end

  def self.add_tag_moderators(user_ids, tag_ids)
    user_ids.each_with_index do |user_id, index|
      user = User.find(user_id)
      tag = Tag.find(tag_ids[index])
      add_tag_mod_role(user, tag)
      add_trusted_role(user)
      add_to_chat_channels(user, tag)

      NotifyMailer.with(user: user, tag: tag, channel_slug: chat_channel_slug(tag)).
        tag_moderator_confirmation_email.
        deliver_now
    end
  end

  def self.add_to_chat_channels(user, tag)
    ChatChannel.find_by(slug: "tag-moderators").add_users(user) if user.chat_channels.where(slug: "tag-moderators").none?
    if tag.mod_chat_channel_id
      ChatChannel.find(tag.mod_chat_channel_id).add_users(user) if user.chat_channels.where(id: tag.mod_chat_channel_id).none?
    else
      channel = ChatChannel.create_with_users(
        users: ([user] + User.with_role(:mod_relations_admin)).flatten.uniq,
        channel_type: "invite_only",
        contrived_name: "##{tag.name} mods",
      )
      tag.update_column(:mod_chat_channel_id, channel.id)
    end
  end

  def self.add_tag_mod_role(user, tag)
    user.update(email_tag_mod_newsletter: true) if user.email_tag_mod_newsletter == false
    user.add_role(:tag_moderator, tag)
    Rails.cache.delete("user-#{user.id}/tag_moderators_list")
    MailchimpBot.new(user).manage_tag_moderator_list
  end

  def self.remove_tag_moderator(user, tag)
    user.remove_role(:tag_moderator, tag)
    user.update(email_tag_mod_newsletter: false) if user.email_tag_mod_newsletter == true
    Rails.cache.delete("user-#{user.id}/tag_moderators_list")
    MailchimpBot.new(user).manage_tag_moderator_list
  end

  def self.chat_channel_slug(tag)
    tag.mod_chat_channel&.slug
  end
end
