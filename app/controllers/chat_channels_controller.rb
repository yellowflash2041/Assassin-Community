class ChatChannelsController < ApplicationController
  before_action :authenticate_user!, only: %i[moderate]
  before_action :set_channel, only: %i[show update update_channel open moderate]
  after_action :verify_authorized

  def index
    if params[:state] == "unopened"
      authorize ChatChannel
      render_unopened_json_response
    elsif params[:state] == "unopened_ids"
      authorize ChatChannel
      render_unopened_ids_response
    elsif params[:state] == "pending"
      authorize ChatChannel
      render_pending_json_response
    elsif params[:state] == "joining_request"
      authorize ChatChannel
      render_joining_request_json_response
    else
      skip_authorization
      render_channels_html
    end
  end

  def show
    @chat_messages = @chat_channel.messages.includes(:user).order("created_at DESC").offset(params[:message_offset]).limit(50)
  end

  def create
    authorize ChatChannel
    @chat_channel = ChatChannelCreationService.new(current_user, params[:chat_channel]).create
    render_chat_channel
  end

  def update
    chat_channel = ChatChannelUpdateService.perform(@chat_channel, chat_channel_params)
    if chat_channel.errors.any?
      flash[:error] = chat_channel.errors.full_messages.to_sentence
    else
      if chat_channel_params[:discoverable].to_i.zero?
        ChatChannelMembership.create(user_id: SiteConfig.mascot_user_id, chat_channel_id: chat_channel.id, role: "member", status: "active")
      else
        ChatChannelMembership.find_by(user_id: SiteConfig.mascot_user_id)&.destroy
      end
      flash[:settings_notice] = "Channel settings updated."
    end
    current_user_membership = @chat_channel.mod_memberships.find_by!(user: current_user)

    redirect_to edit_chat_channel_membership_path(current_user_membership)
  end

  def update_channel
    chat_channel = ChatChannelUpdateService.perform(@chat_channel, chat_channel_params)
    if chat_channel.errors.any?
      render json: { success: false, errors: chat_channel.errors.full_messages, message: "Channel settings updation failed. Try again later." }, success: :bad_request
    else
      if chat_channel_params[:discoverable]
        ChatChannelMembership.create(user_id: SiteConfig.mascot_user_id, chat_channel_id: chat_channel.id, role: "member", status: "active")
      else
        ChatChannelMembership.find_by(user_id: SiteConfig.mascot_user_id)&.destroy
      end
      render json: { success: true, message: "Channel settings updated.", data: {} }, success: :ok
    end
  end

  def open
    membership = @chat_channel.chat_channel_memberships.where(user_id: current_user.id).first
    membership.update(last_opened_at: 1.second.from_now, has_unopened_messages: false)
    send_open_notification
    render json: { status: "success", channel: params[:id] }, status: :ok
  end

  def moderate
    command = chat_channel_params[:command].split
    case command[0]
    when "/ban"
      banned_user = User.find_by(username: command[1])
      if banned_user
        banned_user.add_role :banned
        banned_user.messages.delete_all
        Pusher.trigger(@chat_channel.pusher_channels, "user-banned", { userId: banned_user.id }.to_json)
        render json: { status: "success", message: "suspended!" }, status: :ok
      else
        render json: { status: "error", message: "username not found" }, status: :bad_request
      end
    when "/unban"
      banned_user = User.find_by(username: command[1])
      if banned_user
        banned_user.remove_role :banned
        render json: { status: "success", message: "unsuspended!" }, status: :ok
      else
        render json: { status: "error", message: "username not found" }, status: :bad_request
      end
    when "/clearchannel"
      @chat_channel.clear_channel
      render json: { status: "success", message: "cleared!" }, status: :ok
    else
      render json: { status: "error", message: "invalid command" }, status: :bad_request
    end
  end

  def create_chat
    chat_recipient = User.find(params[:user_id])
    valid_listing = Listing.where(user_id: params[:user_id], contact_via_connect: true).limit(1)
    authorize ChatChannel

    if chat_recipient.inbox_type == "open" || valid_listing.length == 1
      chat = ChatChannel.create_with_users(users: [current_user, chat_recipient], channel_type: "direct")
      message_markdown = params[:message]
      message = Message.new(
        chat_channel: chat,
        message_markdown: message_markdown,
        user: current_user,
      )
      chat.messages.append(message)
      render json: { status: "success", message: "chat channel created!" }, status: :ok
    else
      render json: { status: "error", message: "not allowed!" }, status: :bad_request
    end
  rescue StandardError => e
    render json: { status: "error", message: e.message }, status: :bad_request
  end

  def block_chat
    chat_channel = ChatChannel.find(params[:chat_id])
    authorize chat_channel
    chat_channel.status = "blocked"
    chat_channel.save
    chat_channel.chat_channel_memberships.map(&:index_to_elasticsearch)
    render json: { status: "success", message: "chat channel blocked" }, status: :ok
  end

  # Note: this is part of an effort of moving some things from the external to
  # the internal API. No behavior was changes as part of this refactoring, so
  # this action is a bit unusual.
  def channel_info
    skip_authorization

    @chat_channel =
      ChatChannel.
        select(CHANNEL_ATTRIBUTES_FOR_SERIALIZATION).
        find_by(id: params[:id])

    return if @chat_channel&.has_member?(current_user)

    render json: { error: "not found", status: 404 }, status: :not_found
  end

  CHANNEL_ATTRIBUTES_FOR_SERIALIZATION = %i[id description channel_name].freeze
  private_constant :CHANNEL_ATTRIBUTES_FOR_SERIALIZATION

  private

  def set_channel
    @chat_channel = ChatChannel.find_by(id: params[:id]) || not_found
    authorize @chat_channel
  end

  def chat_channel_params
    params.require(:chat_channel).permit(policy(ChatChannel).permitted_attributes)
  end

  def render_unopened_json_response
    @chat_channels_memberships = if session_current_user_id
                                   ChatChannelMembership.where(user_id: session_current_user_id).includes(%i[chat_channel user]).
                                     where(has_unopened_messages: true).
                                     where(show_global_badge_notification: true).
                                     where.not(status: %w[removed_from_channel left_channel]).
                                     order("chat_channel_memberships.updated_at DESC")
                                 else
                                   []
                                 end
    render "index.json"
  end

  def render_pending_json_response
    @chat_channels_memberships = if current_user
                                   current_user.
                                     chat_channel_memberships.includes(:chat_channel).
                                     where(status: "pending").
                                     order("chat_channel_memberships.updated_at DESC")
                                 else
                                   []
                                 end
    render "index.json"
  end

  def render_unopened_ids_response
    @unopened_ids = ChatChannelMembership.where(user_id: session_current_user_id).includes(:chat_channel).
      where(has_unopened_messages: true).where.not(status: %w[removed_from_channel left_channel]).pluck(:chat_channel_id)
    render json: { unopened_ids: @unopened_ids }
  end

  def render_joining_request_json_response
    requested_memberships_id = current_user.chat_channel_memberships.includes(:chat_channel).
      where(chat_channels: { discoverable: true }, role: "mod").pluck(:chat_channel_id).map { |membership_id| ChatChannel.find_by(id: membership_id).requested_memberships }.flatten.map(&:id)
    @chat_channels_memberships = ChatChannelMembership.includes(%i[user chat_channel]).where(id: requested_memberships_id)

    render "index.json"
  end

  def render_channels_html
    return unless current_user && params[:slug]

    slug = if params[:slug]&.start_with?("@")
             [current_user.username, params[:slug].delete("@")].sort.join("/")
           else
             params[:slug]
           end
    @active_channel = ChatChannel.find_by(slug: slug)
    @active_channel.current_user = current_user if @active_channel
  end

  def render_chat_channel
    if @chat_channel.valid?
      render json: { status: "success",
                     chat_channel: @chat_channel.to_json(only: %i[channel_name slug]) },
             status: :ok
    else
      render json: { errors: @chat_channel.errors.full_messages }
    end
  end

  def send_open_notification
    adjusted_slug = if @chat_channel.group?
                      @chat_channel.adjusted_slug
                    else
                      @chat_channel.adjusted_slug(current_user)
                    end
    Pusher.trigger("private-message-notifications-#{session_current_user_id}", "message-opened", { channel_type: @chat_channel.channel_type, adjusted_slug: adjusted_slug }.to_json)
  end
end
