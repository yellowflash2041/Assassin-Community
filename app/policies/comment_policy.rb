class CommentPolicy < ApplicationPolicy
  def edit?
    user_is_author?
  end

  def create?
    !user_is_banned?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def delete_confirm?
    edit?
  end

  def preview?
    true
  end

  def permitted_attributes_for_update
    %i[body_markdown]
  end
  
  def permitted_attributes_for_preview
    %i[body_markdown]
  end

  def permitted_attributes_for_create
    %i[body_markdown commentable_id commentable_type parent_id]
  end

  private

  def user_is_author?
    record.user_id == user.id
  end

  def user_is_banned?
    user.has_role?(:banned)
  end
end
