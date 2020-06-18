import { h } from 'preact';
import PropTypes from 'prop-types';

const InviteForm = ({
  handleChatChannelInvitations,
  invitationUsernames,
  handleInvitationUsernames,
}) => {
  return (
    <div data-testid="invite-form" className="crayons-card p-4 grid gap-2 mb-4">
      <div className="crayons-field">
        <label
          className="crayons-field__label invitation_form_title"
          htmlFor="chat_channel_membership_invitation_usernames"
        >
          Usernames to invite
        </label>
        <input
          placeholder="Comma separated"
          className="crayons-textfield"
          type="text"
          value={invitationUsernames}
          name="chat_channel_membership[invitation_usernames]"
          id="chat_channel_membership_invitation_usernames"
          onChange={handleInvitationUsernames}
        />
      </div>
      <div>
        <button
          className="crayons-btn"
          type="submit"
          onClick={handleChatChannelInvitations}
        >
          Submit
        </button>
      </div>
    </div>
  );
};

InviteForm.propTypes = {
  handleInvitationUsernames: PropTypes.func.isRequired,
  handleChatChannelInvitations: PropTypes.func.isRequired,
  invitationUsernames: PropTypes.func.isRequired,
};

export default InviteForm;
