class TagAdjustmentsController < ApplicationController
  after_action only: %i[create destroy] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def create
    authorize(User, :moderation_routes?)
    service = TagAdjustmentCreationService.new(
      current_user,
      adjustment_type: params[:tag_adjustment][:adjustment_type],
      status: "committed",
      tag_name: params[:tag_adjustment][:tag_name],
      article_id: params[:tag_adjustment][:article_id],
      reason_for_adjustment: params[:tag_adjustment][:reason_for_adjustment],
    )
    tag_adjustment = service.tag_adjustment
    article = service.article
    if tag_adjustment.save
      service.update_tags_and_notify
      tag = tag_adjustment.tag
      respond_to do |format|
        format.json { render json: { status: "Success", result: tag_adjustment.adjustment_type, colors: { bg: tag.bg_color_hex, text: tag.text_color_hex } } }
        format.html { redirect_to "#{URI.parse(article.path).path}/mod" }
      end
    else
      # TODO: remove this when we move over to full JSON endpoint
      authorize(User, :moderation_routes?)
      @tag_adjustment = tag_adjustment
      @moderatable = article
      @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
      @adjustments = TagAdjustment.where(article_id: article.id)
      @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
      @allowed_to_adjust = @moderatable.class.name == "Article" && (current_user.any_admin? || @tag_moderator_tags.any?)
      respond_to do |format|
        format.json { render json: { error: "Failure: #{tag_adjustment.errors.full_messages.to_sentence}" } }
        format.html { render template: "moderations/mod" }
      end
    end
  end

  def destroy
    authorize User, :moderation_routes?
    tag_adjustment = TagAdjustment.find(params[:id])
    tag_adjustment.destroy
    @article = Article.find(tag_adjustment.article_id)
    @article.update!(tag_list: @article.tag_list.add(tag_adjustment.tag_name)) if tag_adjustment.adjustment_type == "removal"
    @article.update!(tag_list: @article.tag_list.remove(tag_adjustment.tag_name)) if tag_adjustment.adjustment_type == "addition"
    respond_to do |format|
      # TODO: add tag adjustment removal async route in actions panel
      format.json { render json: { result: "Tag adjustment destroyed" } }
      format.html { redirect_to "#{URI.parse(@article.path).path}/mod" }
    end
  end
end
