class ArticlePolicy < ApplicationPolicy
  def update?
    user_is_author? || user_admin? || user_org_admin? || minimal_admin?
  end

  def new?
    true
  end

  def create?
    !user_is_banned?
  end

  def delete_confirm?
    update?
  end

  def destroy?
    update?
  end

  def preview?
    true
  end

  def permitted_attributes
    %i[title body_html body_markdown main_image published canonical_url
       description allow_small_edits allow_big_edits tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications
       archived]
  end

  private

  def user_is_author?
    if record.instance_of?(Article)
      record.user_id == user.id
    else
      record.pluck(:user_id).uniq == [user.id]
    end
  end

  def user_org_admin?
    user.org_admin?(record.organization_id)
  end
end
