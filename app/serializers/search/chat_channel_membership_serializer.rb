module Search
  class ChatChannelMembershipSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id, :status, :viewable_by, :chat_channel_id, :last_opened_at,
               :channel_text, :channel_last_message_at, :channel_status,
               :channel_status, :channel_type, :channel_username, :channel_name,
               :channel_image, :channel_modified_slug, :channel_messages_count
  end
end
