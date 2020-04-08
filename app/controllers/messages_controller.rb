class MessagesController < ApplicationController
  before_action :set_message, only: %i[destroy update]
  before_action :authenticate_user!, only: %i[create]
  include MessagesHelper

  def create
    @message = Message.new(message_params)
    @message.user_id = session_current_user_id
    @temp_message_id = (0...20).map { ("a".."z").to_a[rand(8)] }.join
    authorize @message

    # sending temp message only to sender
    pusher_message_created(true, @message, @temp_message_id)
    if @message.save
      pusher_message_created(false, @message, @temp_message_id)
      notify_users(@message.chat_channel.channel_users_ids, "all")
      notify_users(@mentioned_users_id, "mention")
      render json: { status: "success", message: { temp_id: @temp_message_id, id: @message.id } }, status: :created
    else
      render json: {
        status: "error",
        message: {
          chat_channel_id: @message.chat_channel_id,
          message: @message.errors.full_messages,
          type: "error"
        }
      }, status: :unauthorized
    end
  end

  def destroy
    authorize @message

    if @message.valid?
      begin
        Pusher.trigger(@message.chat_channel.pusher_channels, "message-deleted", @message.to_json)
      rescue Pusher::Error => e
        logger.info "PUSHER ERROR: #{e.message}"
      end
    end

    if @message.destroy
      render json: { status: "success", message: "Message was deleted" }
    else
      render json: {
        status: "error",
        message: {
          chat_channel_id: @message.chat_channel_id,
          message: @message.errors.full_messages,
          type: "error"
        }
      }, status: :unauthorized
    end
  end

  def update
    authorize @message

    if @message.update(permitted_attributes(@message).merge(edited_at: Time.zone.now))
      if @message.valid?
        begin
          message_json = create_pusher_payload(@message, "")
          Pusher.trigger(@message.chat_channel.pusher_channels, "message-edited", message_json)
        rescue Pusher::Error => e
          logger.info "PUSHER ERROR: #{e.message}"
        end
      end
      render json: { status: "success", message: "Message was edited" }
    else
      render json: {
        status: "error",
        message: {
          chat_channel_id: @message.chat_channel_id,
          message: @message.errors.full_messages,
          type: "error"
        }
      }, status: :unauthorized
    end
  end

  private

  def message_params
    @mentioned_users_id = params[:message][:mentioned_users_id]
    params.require(:message).permit(:message_markdown, :user_id, :chat_channel_id)
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def user_not_authorized
    respond_to do |format|
      format.json do
        render json: {
          status: "error",
          message: {
            chat_channel_id: message_params[:chat_channel_id],
            message: "You can not do that because you are suspended",
            type: "error"
          }
        }, status: :unauthorized
      end
    end
  end

  def notify_users(user_ids, type)
    return unless user_ids

    user_ids.each do |id|
      message_json = create_pusher_payload(@message, @temp_message_id)
      if type == "mention"
        Pusher.trigger("private-message-notifications-#{id}", "mentioned", message_json)
      else
        Pusher.trigger("private-message-notifications-#{id}", "message-created", message_json)
      end
    end
  end
end
