class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = Message.new(message_params)
    authorize @message
    success = false

    if @message.save
      begin
        message_json = create_pusher_payload(@message)
        notification_channels = @message.chat_channel.chat_channel_memberships.pluck(:user_id).map { |id| "message-notifications-#{id}"}
        Pusher.trigger(notification_channels, "message-created", message_json)
        success = true
      rescue Pusher::Error => e
        logger.info "PUSHER ERROR: #{e.message}"
      end

      if success
        render json: { status: "success", message: "Message created" }, status: 201
      else
        error_message = "Message created but could not trigger Pusher"
        render json: { status: "error", message: error_message }, status: 201
      end
    else
      render json: {
        status: "error",
        message: {
          chat_channel_id: @message.chat_channel_id,
          message: @message.errors.full_messages,
          type: "error",
        },
      }, status: 401
    end
  end

  private

  def create_pusher_payload(new_message)
    {
      user_id: new_message.user.id,
      chat_channel_id: new_message.chat_channel.id,
      chat_channel_adjusted_slug: new_message.chat_channel.adjusted_slug(current_user, "sender"),
      username: new_message.user.username,
      profile_image_url: ProfileImage.new(new_message.user).get(90),
      message: new_message.message_html,
      timestamp: new_message.created_at,
      color: new_message.preferred_user_color,
      reception_method: "pushed"
    }.to_json
  end

  def message_params
    params.require(:message).permit(:message_markdown, :user_id, :chat_channel_id)
  end

  def user_not_authorized
    respond_to do |format|
      format.json do
        render json: {
          status: "error",
          message: {
            chat_channel_id: message_params[:chat_channel_id],
            message: "You can not do that because you are banned",
            type: "error",
          },
        }, status: 401
      end
    end
  end
end
