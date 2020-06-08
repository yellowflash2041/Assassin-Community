module Moderator
  class ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def initialize(user:, admin:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def self.handle_user_roles(admin:, user:, user_params:)
      new(user: user, admin: admin, user_params: user_params).update_roles
    end

    def delete_comments
      Users::DeleteComments.call(user)
    end

    def delete_articles
      Users::DeleteArticles.call(user)
    end

    def delete_user_activity
      Users::DeleteActivity.call(user)
    end

    def remove_privileges
      @user.remove_role :workshop_pass
      @user.remove_role :pro
      remove_mod_roles
      remove_tag_moderator_role
    end

    def remove_mod_roles
      @user.remove_role :trusted
      @user.remove_role :tag_moderator
      @user.update(email_tag_mod_newsletter: false)
      MailchimpBot.new(user).manage_tag_moderator_list
      @user.update(email_community_mod_newsletter: false)
      MailchimpBot.new(user).manage_community_moderator_list
    end

    def remove_tag_moderator_role
      @user.remove_role :tag_moderator
      MailchimpBot.new(user).manage_tag_moderator_list
    end

    def create_note(reason, content)
      Note.create(
        author_id: @admin.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: reason,
        content: content,
      )
    end

    def handle_user_status(role, note)
      case role
      when "Ban" || "Spammer"
        user.add_role :banned
        remove_privileges
      when "Warn"
        warned
      when "Comment Ban"
        comment_banned
      when "Regular Member"
        regular_member
      when "Trusted"
        remove_negative_roles
        user.remove_role :pro
        add_trusted_role
      when "Pro"
        remove_negative_roles
        add_trusted_role
        user.add_role :pro
      end
      create_note(role, note)
    end

    def comment_banned
      user.add_role :comment_banned
      user.remove_role :banned
      remove_privileges
    end

    def regular_member
      remove_negative_roles
      user.remove_role :pro
      remove_mod_roles
    end

    def warned
      user.add_role :warned
      user.remove_role :banned
      remove_privileges
    end

    def add_trusted_role
      return if user.has_role?(:trusted)

      user.add_role :trusted
      user.update(email_community_mod_newsletter: true)
      NotifyMailer.trusted_role_email(user).deliver
      MailchimpBot.new(user).manage_community_moderator_list
    end

    def remove_negative_roles
      user.remove_role :banned if user.banned
      user.remove_role :warned if user.warned
      user.remove_role :comment_banned if user.comment_banned
    end

    def update_trusted_cache
      Rails.cache.delete("user-#{@user.id}/has_trusted_role")
      @user.trusted
    end

    def update_roles
      handle_user_status(user_params[:user_status], user_params[:note_for_current_role])
      update_trusted_cache
    end
  end
end
