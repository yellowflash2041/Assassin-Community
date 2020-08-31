class ChatChannelsController < ApplicationController
  before_action :authenticate_user!, only: %i[moderate]
  before_action :set_channel, only: %i[show update update_channel open moderate]
  after_action :verify_authorized

  CHANNEL_ATTRIBUTES_FOR_SERIALIZATION = %i[id description channel_name].freeze
  private_constant :CHANNEL_ATTRIBUTES_FOR_SERIALIZATION

  def index
    case params[:state]
    when "unopened"
      authorize ChatChannel
      render_unopened_json_response
    when "unopened_ids"
      authorize ChatChannel
      render_unopened_ids_response
    when "pending"
      authorize ChatChannel
      render_pending_json_response
    when "joining_request"
      authorize ChatChannel
      render_joining_request_json_response
    else
      skip_authorization
      render_channels_html
    end
  end

  def show
    @chat_messages = @chat_channel.messages
      .includes(:user)
      .order(created_at: :desc)
      .offset(params[:message_offset])
      .limit(50)
  end

  def create
    authorize ChatChannel
    @chat_channel = current_user.chat_channels.create(
      channel_type: "invite_only",
      channel_name: chat_channel_params[:channel_name],
      slug: chat_channel_params[:slug],
    )
    render_chat_channel
  end

  def update
    @chat_channel.update(chat_channel_params)
    if @chat_channel.errors.any?
      flash[:error] = @chat_channel.errors.full_messages.to_sentence
    else
      if chat_channel_params[:discoverable].to_i.zero?
        ChatChannelMembership.create(user_id: SiteConfig.mascot_user_id, chat_channel_id: @chat_channel.id,
                                     role: "member", status: "active")
      else
        ChatChannelMembership.find_by(user_id: SiteConfig.mascot_user_id)&.destroy
      end
      flash[:settings_notice] = "Channel settings updated."
    end
    current_user_membership = @chat_channel.mod_memberships.find_by!(user: current_user)

    redirect_to edit_chat_channel_membership_path(current_user_membership)
  end

  def update_channel
    @chat_channel.update(chat_channel_params)
    if @chat_channel.errors.any?
      render json: { success: false, errors: @chat_channel.errors.full_messages,
                     message: "Channel settings updation failed. Try again later." }, success: :bad_request
    else
      if chat_channel_params[:discoverable]
        ChatChannelMembership.create(user_id: SiteConfig.mascot_user_id, chat_channel_id: @chat_channel.id,
                                     role: "member", status: "active")
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
    chat_channel = ChatChannel.find_by(id: params[:id])
    authorize chat_channel
    command, username = chat_channel_params[:command].split
    case command
    when "/ban"
      user = User.find_by(username: username)
      membership = user&.chat_channel_memberships&.find_by(chat_channel: chat_channel)
      if user && membership
        user.add_role :banned
        user.messages.where(chat_channel: chat_channel).delete_all
        membership.update(status: "removed_from_channel")
        Pusher.trigger(chat_channel.pusher_channels, "user-banned", { userId: user.id }.to_json)
        render json: { status: "moderation-success", message: "#{username} was suspended.", userId: user.id,
                       chatChannelId: chat_channel.id }, status: :ok
      else
        render json: {
          status: "error",
          message: "Ban failed. user with username '#{username}' not found in this channel."
        }, status: :bad_request
      end
    when "/unban"
      user = User.find_by(username: username)
      if user
        user.remove_role :banned
        render json: { status: "moderation-success", message: "#{username} was unsuspended." }, status: :ok
      else
        render json: {
          status: "error",
          message: "Unban failed. User with username '#{username}' not found in this channel."
        }, status: :bad_request
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
      chat = ChatChannels::CreateWithUsers.call(users: [current_user, chat_recipient], channel_type: "direct")
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
      ChatChannel
        .select(CHANNEL_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by(id: params[:id])

    return if @chat_channel&.has_member?(current_user)

    render json: { error: "not found", status: 404 }, status: :not_found
  end

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
                                   ChatChannelMembership.where(user_id: session_current_user_id)
                                     .where(has_unopened_messages: true)
                                     .where(show_global_badge_notification: true)
                                     .where.not(status: %w[removed_from_channel left_channel])
                                     .includes(%i[chat_channel user])
                                     .order("chat_channel_memberships.updated_at" => :desc)
                                 else
                                   []
                                 end
    render "index.json"
  end

  def render_pending_json_response
    @chat_channels_memberships = if current_user
                                   current_user
                                     .chat_channel_memberships.includes(:chat_channel)
                                     .where(status: "pending")
                                     .order("chat_channel_memberships.updated_at" => :desc)
                                 else
                                   []
                                 end
    render "index.json"
  end

  def render_unopened_ids_response
    @unopened_ids = ChatChannelMembership.where(user_id: session_current_user_id).includes(:chat_channel)
      .where(has_unopened_messages: true).where.not(status: %w[removed_from_channel
                                                               left_channel]).pluck(:chat_channel_id)
    render json: { unopened_ids: @unopened_ids }
  end

  def render_joining_request_json_response
    requested_memberships_id = current_user
      .chat_channel_memberships
      .includes(:chat_channel)
      .where(chat_channels: { discoverable: true }, role: "mod")
      .pluck(:chat_channel_id)
      .map { |membership_id| ChatChannel.find_by(id: membership_id).requested_memberships }
      .flatten
      .map(&:id)

    @chat_channels_memberships = ChatChannelMembership
      .includes(%i[user chat_channel])
      .where(id: requested_memberships_id)

    render "index.json"
  end

  def render_channels_html
    return unless current_user && params[:slug]

    slug = if params[:slug]&.start_with?("@")
             [current_user.username, params[:slug].delete("@")].sort.join("/")
           else
             params[:slug]
           end
    chat_channel = ChatChannel.find_by(slug: slug)
    return unless chat_channel

    membership = chat_channel.chat_channel_memberships.find_by(user_id: current_user.id)
    @active_channel = membership&.status == "active" ? chat_channel : nil
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
    payload = { channel_type: @chat_channel.channel_type, adjusted_slug: adjusted_slug }.to_json
    Pusher.trigger(ChatChannel.pm_notifications_channel(session_current_user_id), "message-opened", payload)
  end
end
