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
    if (!channel) {
      return;
    }
    const isActive = parseInt(activeChannelId, 10) === channel.id;
    let lastOpened = channel.last_opened_at;
    if (!lastOpened) {
      if (channel.channel_users[window.currentUser.username]) {
        lastOpened =
          channel.channel_users[window.currentUser.username].last_opened_at;
      } else {
        lastOpened = new Date();
      }
    }
    const isUnopened =
      new Date(channel.last_message_at) > new Date(lastOpened) &&
      channel.messages_count > 0;

    const otherClassname = isActive
      ? 'chatchanneltab--active'
      : 'chatchanneltab--inactive';
    const name =
      channel.channel_type === 'direct'
        ? `@${channel.slug
            .replace(`${window.currentUser.username}/`, '')
            .replace(`/${window.currentUser.username}`, '')}`
        : channel.channel_name;
    const newMessagesIndicatorClass = isUnopened ? 'new' : 'old';
    const modififedSlug =
      channel.channel_type === 'direct' ? name : channel.slug;
    const indicatorPic =
      channel.channel_type === 'direct' ? (
        <img
          alt={channel.channel_name}
          src={channel.channel_users[name.replace('@', '')].profile_image}
          className="chatchanneltabindicatordirectimage"
        />
      ) : (
        <img alt={channel.channel_name} src={GroupImage} />
      );
    let channelColor = 'transparent';
    if (channel.channel_type === 'direct' && isActive) {
      channelColor = channel.channel_users[name.replace('@', '')].darker_color;
    } else if (isActive) {
      channelColor = '#4e57ef';
    }

    let content = '';
    const contentInner = (
      <span
        data-channel-slug={modififedSlug}
        className={`chatchanneltabindicator chatchanneltabindicator--${newMessagesIndicatorClass}`}
        data-channel-id={channel.id}
      >
        {indicatorPic}
      </span>
    );
    if (expanded) {
      content = (
        <span>
          {contentInner}
          {name}
        </span>
      );
    } else if (channel.channel_type === 'direct') {
      content = contentInner;
    } else {
      content = name;
    }
    let callIndicator = '';
    if (
      incomingVideoCallChannelIds &&
      incomingVideoCallChannelIds.includes(channel.id)
    ) {
      callIndicator = (
        <span
          role="img"
          aria-label="emoji"
          className="chatchanneltabindicator chatchanneltabindicator--phone"
        >
          📞
        </span>
      );
    }
    return (
      <button
        type="button"
        key={channel.id}
        className="chatchanneltabbutton"
        onClick={handleSwitchChannel}
        data-channel-id={channel.id}
        data-channel-slug={modififedSlug}
      >
        <span
          className={`chatchanneltab ${otherClassname} chatchanneltab--${newMessagesIndicatorClass}`}
          data-channel-id={channel.id}
          data-channel-slug={modififedSlug}
          style={{
            border: `1px solid ${channelColor}`,
            boxShadow: `3px 3px 0px ${channelColor}`,
          }}
        >
          {callIndicator}
          {content}
        </span>
      </button>
    );
  });
  let channelsListFooter = '';
  if (channels.length === 30) {
    channelsListFooter = (
      <div className="chatchannels__channelslistfooter">...</div>
    );
  }
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
        </span>
        {' '}
        Welcome to
        <b> DEV Connect</b>
! You may message anyone you mutually follow.
      </div>
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
