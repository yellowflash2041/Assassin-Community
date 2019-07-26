import { h } from 'preact';
import PropTypes from 'prop-types';
import ConfigImage from 'images/three-dots.svg';
import GroupImage from 'images/organization.svg';

const Channels = ({
  activeChannelId,
  chatChannels,
  handleSwitchChannel,
  expanded,
  filterQuery,
  channelsLoaded,
  incomingVideoCallChannelIds,
}) => {
  const channels = chatChannels.map(channel => {
    const isActive = parseInt(activeChannelId, 10) === channel.chat_channel_id;
    const lastOpened = channel.last_opened_at;
    const isUnopened =
      new Date(channel.channel_last_message_at) > new Date(lastOpened) &&
      channel.channel_messages_count > 0;
    let newMessagesIndicator = isUnopened ? 'new' : 'old';
    if (incomingVideoCallChannelIds.indexOf(channel.chat_channel_id) > -1) {
      newMessagesIndicator = 'video';
    }
    const otherClassname = isActive
      ? 'chatchanneltab--active'
      : 'chatchanneltab--inactive';
    return (
      <button
        type="button"
        key={channel.id}
        className="chatchanneltabbutton"
        onClick={handleSwitchChannel}
        data-channel-id={channel.chat_channel_id}
        data-channel-slug={channel.channel_modified_slug}
      >
        <span
          className={`chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicator}`}
          data-channel-id={channel.chat_channel_id}
          data-channel-slug={channel.channel_modified_slug}
          style={{
            border: `1px solid ${channel.channel_color}`,
            boxShadow: `3px 3px 0px ${channel.channel_color}`,
          }}
        >
          <span
            data-channel-slug={channel.channel_modified_slug}
            className={`chatchanneltabindicator chatchanneltabindicator--${newMessagesIndicator}`}
            data-channel-id={channel.chat_channel_id}
          >
            <img
              src={channel.channel_image}
              alt="pic"
              className="chatchanneltabindicatordirectimage"
            />
          </span>
          {channel.channel_name}
        </span>
      </button>
    );
  });
  let topNotice = '';
  if (
    expanded &&
    filterQuery.length === 0 &&
    channelsLoaded &&
    (channels.length === 0 || channels[0].messages_count === 0)
  ) {
    topNotice = (
      <div className="chatchannels__channelslistheader">
        <span role="img" aria-label="emoji">
          👋
        </span>{' '}
        Welcome to
        <b> DEV Connect</b>! You may message anyone you mutually follow.
      </div>
    );
  }
  let channelsListFooter = '';
  if (channels.length === 30) {
    channelsListFooter = (
      <div className="chatchannels__channelslistfooter">...</div>
    );
  }
  let configFooter = '';
  if (expanded) {
    configFooter = (
      <div className="chatchannels__config">
        <img alt="" src={ConfigImage} style={{ height: '18px' }} />
        <div className="chatchannels__configmenu">
          <a href="/settings">DEV Settings</a>
          <a href="/report-abuse">Report Abuse</a>
        </div>
      </div>
    );
  }
  return (
    <div className="chatchannels">
      <div
        className="chatchannels__channelslist"
        id="chatchannels__channelslist"
      >
        {topNotice}
        {channels}
        {channelsListFooter}
      </div>
      {configFooter}
    </div>
  );
};

Channels.propTypes = {
  activeChannelId: PropTypes.number.isRequired,
  chatChannels: PropTypes.array.isRequired,
  handleSwitchChannel: PropTypes.func.isRequired,
  expanded: PropTypes.bool.isRequired,
  filterQuery: PropTypes.string.isRequired,
  channelsLoaded: PropTypes.bool.isRequired,
  incomingVideoCallChannelIds: PropTypes.array.isRequired,
};

export default Channels;
