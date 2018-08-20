class ChatChannelPolicy < ApplicationPolicy
  def index?
    user
  end

  def create?
    true
  end

  def update?
    user_can_edit_channel
  end

  def moderate?
    !user_is_banned? && user_admin?
  end

  def show?
    user_part_of_channel_or_open
  end

  def open?
    user_part_of_channel
  end

  def permitted_attributes
    %i[channel_name slug command]
  end

  private

  def user_can_edit_channel
    record.present? &&
      (user.has_role?(:super_admin) || record.channel_mod_ids.include?(user.id))
  end

  def user_part_of_channel_or_open
    record.present? && (record.channel_type == "open" || record.has_member?(user))
  end

  def user_part_of_channel
    record.present? && record.has_member?(user)
  end
end
