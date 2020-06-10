import { request } from '../../utilities/http';

/**
 * This function will get all details of the chat channel accrding to the membership role.
 *
 * @param {number} chatChannelMembershipId Current User chat channel membership ID
 */
export async function getChannelDetails(chatChannelMembershipId) {
  const response = await request(
    `/chat_channel_memberships/chat_channel_info/${chatChannelMembershipId}`,
    {
      credentials: 'same-origin',
    },
  );

  return response.json();
}

/**
 * This function is used to update the notification settings.
 *
 * @param {number} membershipId Current user Chat Channel membership Id.
 * @param {boolean} notificationBadge Boolean value for the notification
 */
export async function updatePersonalChatChannelNotificationSettings(
  membershipId,
  notificationBadge,
) {
  const response = await request(
    `/chat_channel_memberships/update_membership/${membershipId}`,
    {
      method: 'PATCH',
      body: {
        chat_channel_membership: {
          show_global_badge_notification: notificationBadge,
        },
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

/**
 * This function is used to reject chat channel joining request & pending requests.
 *
 * @param { number } channelId Active Chat Channel ID
 * @param { number } membershipId Requested user membership Id
 * @param { string } membershipStatus Requested user membership status
 */
export async function rejectChatChannelJoiningRequest(
  channelId,
  membershipId,
  membershipStatus,
) {
  const response = await request(
    `/chat_channel_memberships/remove_membership`,
    {
      method: 'POST',
      body: {
        status: membershipStatus || 'pending',
        chat_channel_id: channelId,
        membership_id: membershipId,
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

/**
 *
 * @param {number} channelId Active chat channel Id
 * @param {number} membershipId Chat channel joining request membership id
 */
export async function acceptChatChannelJoiningRequest(channelId, membershipId) {
  const response = await request(`/chat_channel_memberships/add_membership`, {
    method: 'POST',
    body: {
      chat_channel_id: channelId,
      membership_id: membershipId,
      chat_channel_membership: {
        user_action: 'accept',
      },
    },
    credentials: 'same-origin',
  });

  return response.json();
}

export async function updateChatChannelDescription(
  channelId,
  description,
  discoverable,
) {
  const response = await request(`/chat_channels/update_channel/${channelId}`, {
    method: 'PATCH',
    body: { chat_channel: { description, discoverable } },
    credentials: 'same-origin',
  });

  return response.json();
}

/**
 * Send Active chat channel invitation
 *
 * @param {numner} channelId Active chat channel
 * @param {string} invitationUsernames UserNames coma seprated
 */
export async function sendChatChannelInvitation(
  channelId,
  invitationUsernames,
) {
  const response = await request(
    `/chat_channel_memberships/create_membership_request`,
    {
      method: 'POST',
      body: {
        chat_channel_membership: {
          chat_channel_id: channelId,
          invitation_usernames: invitationUsernames,
        },
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

/**
 * This function is used to leave the chat channel.
 *
 * @param {number} membershipId Current User Chat channel membership id
 */
export async function leaveChatChannelMembership(membershipId) {
  const response = await request(
    `/chat_channel_memberships/leave_membership/${membershipId}`,
    {
      method: 'PATCH',

      credentials: 'same-origin',
    },
  );

  return response.json();
}
