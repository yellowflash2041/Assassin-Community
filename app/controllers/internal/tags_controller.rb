class Internal::TagsController < Internal::ApplicationController
  layout "internal"

  def index
    @tags = if params[:state] == "supported"
              Tag.where(supported: true).order("taggings_count DESC").page(params[:page]).per(50)
            elsif params[:state] == "unsupported"
              Tag.where(supported: false).order("taggings_count DESC").page(params[:page]).per(50)
            else
              Tag.order("taggings_count DESC").page(params[:page]).per(50)
            end
    @tags = @tags.where("tags.name ILIKE :search", search: "%#{params[:search]}%") if params[:search].present?
  end

  def show
    @tag = Tag.find(params[:id])
  end

  def edit
    @tag = Tag.find(params[:id])
  end

  def update
    @tag = Tag.find(params[:id])
    @add_user_id = params[:tag][:tag_moderator_id]
    @remove_user_id = params[:tag][:remove_moderator_id]
    add_moderator if @add_user_id
    remove_moderator if @remove_user_id
    @tag.update!(tag_params)
    redirect_to "/internal/tags/#{params[:id]}"
  end

  private

  def remove_moderator
    user = User.find(@remove_user_id)
    user.update(email_tag_mod_newsletter: false)
    AssignTagModerator.remove_tag_moderator(user, @tag)
  end

  def add_moderator
    User.find(@add_user_id).update(email_tag_mod_newsletter: true)
    AssignTagModerator.add_tag_moderators([@add_user_id], [@tag.id])
  end

  def tag_params
    params.require(:tag).permit(:supported,
                                :rules_markdown,
                                :short_summary,
                                :pretty_name,
                                :bg_color_hex,
                                :text_color_hex,
                                :tag_moderator_id,
                                :remove_moderator_id,
                                :alias_for)
  end
end
