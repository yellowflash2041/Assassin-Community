class UserPolicy < ApplicationPolicy
  def edit?
    current_user?
  end

  def onboarding_update?
    true
  end

  def update?
    current_user?
  end

  def destroy?
    current_user?
  end

  def join_org?
    !user_is_banned?
  end

  def leave_org?
    true
  end

  def add_org_admin?
    user.org_admin && within_the_same_org?
  end

  def remove_org_admin?
    user.org_admin && not_self? && within_the_same_org?
  end

  def remove_from_org?
    user.org_admin && not_self? && within_the_same_org?
  end

  def remove_association?
    current_user?
  end

  def dashboard_show?
    current_user? || user_admin? || minimal_admin?
  end

  def pro_user?
    current_user? && user.has_role?(:pro)
  end

  def moderation_routes?
    user.has_role?(:trusted) && !user.banned
  end

  def permitted_attributes
    %i[available_for
       behance_url
       bg_color_hex
       config_theme
       config_font
       contact_consent
       currently_hacking_on
       currently_learning
       display_sponsors
       dribbble_url
       education
       email
       email_badge_notifications
       email_comment_notifications
       email_digest_periodic
       email_follower_notifications
       email_membership_newsletter
       email_mention_notifications
       email_connect_messages
       email_newsletter
       email_public
       editor_version
       email_unread_notifications
       mobile_comment_notifications
       employer_name
       employer_url
       employment_title
       experience_level
       facebook_url
       feed_admin_publish_permission
       feed_mark_canonical
       feed_url
       gitlab_url
       linkedin_url
       location
       looking_for_work
       looking_for_work_publicly
       mastodon_url
       medium_url
       mentee_description
       mentee_form_updated_at
       mentor_description
       mentor_form_updated_at
       mostly_work_with
       name
       offering_mentorship
       inbox_type
       permit_adjacent_sponsors
       password
       password_confirmation
       prefer_language_en
       prefer_language_es
       prefer_language_fr
       prefer_language_it
       prefer_language_ja
       profile_image
       seeking_mentorship
       stackoverflow_url
       summary
       text_color_hex
       username
       website_url
       export_requested]
  end

  private

  def within_the_same_org?
    user.organization == record.organization
  end

  def not_self?
    user != record
  end

  def current_user?
    user == record
  end
end
