class AsyncInfoController < ApplicationController
  skip_before_action :ensure_signup_complete
  include Devise::Controllers::Rememberable

  caches_action :base_data,
  cache_path: Proc.new { "#{request.path}__
                            #{request.session_options[:id]}__
                            #{current_user.id}__
                            #{current_user.last_sign_in_at}__
                            #{current_user.updated_at}__
                            #{current_user.reactions_count}__
                            #{current_user.comments_count}__
                            #{current_user.saw_onboarding}__
                            #{current_user.checked_code_of_conduct}__
                            #{current_user.articles_count}__
                            #{cookies[:remember_user_token]}" },
  expires_in: 15.minutes

  def base_data
    flash.discard(:notice)
    unless user_signed_in?
      render json: {}
      return
    end
    if cookies[:remember_user_token].blank?
      current_user.remember_me = true
      current_user.remember_me!
      remember_me(current_user)
    end
    @user = current_user.decorate
    respond_to do |format|
      format.json do
        render json: {
          param: request_forgery_protection_token,
          token: form_authenticity_token,
          user: {
            id: @user.id,
            name: @user.name,
            username: @user.username,
            profile_image_90: ProfileImage.new(@user).get(90),
            followed_tag_names: @user.cached_followed_tag_names,
            followed_tags: @user.cached_followed_tags.to_json(only: [:id,:name,:bg_color_hex,:text_color_hex]),
            followed_user_ids: @user.cached_following_users_ids,
            reading_list_ids: ReadingList.new(@user).cached_ids_of_articles,
            saw_onboarding: @user.saw_onboarding,
            onboarding_checklist: UserStates.new(@user).cached_onboarding_checklist,
            checked_code_of_conduct: @user.checked_code_of_conduct,
            number_of_comments: @user.comments.count,
            display_sponsors: @user.display_sponsors,
          }.to_json
        }
      end
    end
  end
end
