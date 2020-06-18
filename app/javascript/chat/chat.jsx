/* eslint-disable consistent-return,no-unused-vars,react/destructuring-assignment,react/no-access-state-in-setstate,react/button-has-type */
import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import ConfigImage from '../../assets/images/overflow-horizontal.svg';
import {
  conductModeration,
  getAllMessages,
  sendMessage,
  sendOpen,
  getChannels,
  getUnopenedChannelIds,
  getContent,
  getChannelInvites,
  getJoiningRequest,
  sendChannelInviteAction,
  deleteMessage,
  editMessage,
} from './actions/actions';
import {
  sendChannelRequest,
  rejectJoiningRequest,
  acceptJoiningRequest,
} from './actions/requestActions';
import {
  hideMessages,
  scrollToBottom,
  setupObserver,
  getCurrentUser,
  channelSorter,
} from './util';
import Alert from './alert';
import Channels from './channels';
import Compose from './compose';
import Message from './message';
import ActionMessage from './actionMessage';
import Content from './content';
import VideoContent from './videoContent';

import { setupPusher } from '../utilities/connect';
import debounceAction from '../utilities/debounceAction';

export default class Chat extends Component {
  static propTypes = {
    pusherKey: PropTypes.number.isRequired,
    chatChannels: PropTypes.string.isRequired,
    chatOptions: PropTypes.string.isRequired,
    githubToken: PropTypes.string.isRequired,
  };

  constructor(props) {
    super(props);
    const chatChannels = JSON.parse(props.chatChannels);
    const chatOptions = JSON.parse(props.chatOptions);
    this.debouncedChannelFilter = debounceAction(
      this.triggerChannelFilter.bind(this),
    );

    this.state = {
      messages: [],
      scrolled: false,
      showAlert: false,
      chatChannels,
      unopenedChannelIds: [],
      filterQuery: '',
      channelTypeFilter: 'all',
      channelsLoaded: false,
      channelPaginationNum: 0,
      fetchingPaginatedChannels: false,
      activeChannelId: chatOptions.activeChannelId,
      activeChannel: null,
      showChannelsList: chatOptions.showChannelsList,
      showTimestamp: chatOptions.showTimestamp,
      currentUserId: chatOptions.currentUserId,
      notificationsPermission: null,
      activeContent: {},
      fullscreenContent: null,
      videoPath: null,
      expanded: window.innerWidth > 600,
      isMobileDevice: typeof window.orientation !== 'undefined',
      subscribedPusherChannels: [],
      inviteChannels: [],
      joiningRequests: [],
      messageOffset: 0,
      showDeleteModal: false,
      messageDeleteId: null,
      allMessagesLoaded: false,
      currentMessageLocation: 0,
      startEditing: false,
      activeEditMessage: {},
      markdownEdited: false,
      searchShowing: false,
      channelUsers: [],
      showMemberlist: false,
      memberFilterQuery: null,
      rerenderIfUnchangedCheck: null,
    };
    if (chatOptions.activeChannelId) {
      getAllMessages(chatOptions.activeChannelId, 0, this.receiveAllMessages);
    }
  }

  componentDidMount() {
    const {
      chatChannels,
      activeChannelId,
      showChannelsList,
      channelTypeFilter,
      isMobileDevice,
      channelPaginationNum,
      currentUserId,
      messageOffset,
    } = this.state;

    this.setupChannels(chatChannels);

    const channelsForPusherSub = chatChannels.filter(
      this.channelTypeFilterFn('open'),
    );
    this.subscribeChannelsToPusher(
      channelsForPusherSub,
      (channel) => `open-channel-${channel.chat_channel_id}`,
    );

    setupObserver(this.observerCallback);

    this.subscribePusher(`private-message-notifications-${currentUserId}`);

    if (activeChannelId) {
      sendOpen(activeChannelId, this.handleChannelOpenSuccess, null);
    }
    if (showChannelsList) {
      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      const searchParams = {
        query: '',
        retrievalID: activeChannelId,
        searchType: '',
        paginationNumber: channelPaginationNum,
      };
      getChannels(searchParams, filters, this.loadChannels);
      getUnopenedChannelIds(this.markUnopenedChannelIds);
    }
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (document.getElementById('chatchannels__channelslist')) {
      document
        .getElementById('chatchannels__channelslist')
        .addEventListener('scroll', this.handleChannelScroll);
    }
    getChannelInvites(this.handleChannelInvites, null);
    getJoiningRequest(this.handleChannelJoiningRequest, null);
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (
      this.state.rerenderIfUnchangedCheck !== nextState.rerenderIfUnchangedCheck
    ) {
      return false;
    }
  }

  componentDidUpdate() {
    const { scrolled, currentMessageLocation } = this.state;
    const messageList = document.getElementById('messagelist');
    if (messageList) {
      if (!scrolled) {
        scrollToBottom();
      }
    }

    if (currentMessageLocation && messageList.scrollTop === 0) {
      messageList.scrollTop =
        messageList.scrollHeight - (currentMessageLocation + 30);
    }
  }

  filterForActiveChannel = (channels, id, currentUserId) =>
    channels.filter(
      (channel) =>
        channel.chat_channel_id === parseInt(id, 10) &&
        channel.viewable_by === parseInt(currentUserId, 10),
    )[0];

  subscribePusher = (channelName) => {
    const { subscribedPusherChannels } = this.state;
    const { pusherKey } = this.props;
    if (!subscribedPusherChannels.includes(channelName)) {
      setupPusher(pusherKey, {
        channelId: channelName,
        messageCreated: this.receiveNewMessage,
        messageDeleted: this.removeMessage,
        messageEdited: this.updateMessage,
        channelCleared: this.clearChannel,
        redactUserMessages: this.redactUserMessages,
        channelError: this.channelError,
        mentioned: this.mentioned,
        messageOpened: this.messageOpened,
      });
      const subscriptions = subscribedPusherChannels;
      subscriptions.push(channelName);
      this.setState({ subscribedPusherChannels: subscriptions });
    }
  };

  mentioned = () => {};

  messageOpened = () => {};

  loadChannels = (channels, query) => {
    const { activeChannelId } = this.state;
    const activeChannel =
      this.state.activeChannel ||
      channels.filter(
        (channel) => channel.chat_channel_id === activeChannelId,
      )[0];
    if (activeChannelId && query.length === 0) {
      this.setState({
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: '',
        activeChannel:
          activeChannel ||
          this.filterForActiveChannel(channels, activeChannelId),
      });
      this.setupChannel(activeChannelId);
    } else if (activeChannelId) {
      this.setState({
        scrolled: false,
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query,
        activeChannel:
          activeChannel ||
          this.filterForActiveChannel(channels, activeChannelId),
      });
      this.setupChannel(activeChannelId);
    } else if (channels.length > 0) {
      this.setState({
        chatChannels: channels,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query || '',
        scrolled: false,
      });
      const channel = channels[0];
      this.triggerSwitchChannel(
        channel.chat_channel_id,
        channel.channel_modified_slug,
      );
    } else {
      this.setState({ channelsLoaded: true });
    }
    this.subscribeChannelsToPusher(
      channels.filter(this.channelTypeFilterFn('open')),
      (channel) => `open-channel-${channel.chat_channel_id}`,
    );
    this.subscribeChannelsToPusher(
      channels.filter(this.channelTypeFilterFn('invite_only')),
      (channel) => `presence-channel-${channel.chat_channel_id}`,
    );
    const chatChannelsList = document.getElementById(
      'chatchannels__channelslist',
    );

    if (chatChannelsList) {
      chatChannelsList.scrollTop = 0;
    }
  };

  markUnopenedChannelIds = (ids) => {
    this.setState({ unopenedChannelIds: ids });
  };

  subscribeChannelsToPusher = (channels, channelNameFn) => {
    channels.forEach((channel) => {
      this.subscribePusher(channelNameFn(channel));
    });
  };

  channelTypeFilterFn = (type) => (channel) => {
    return channel.channel_type === type;
  };

  setupChannels = (channels) => {
    channels.forEach((channel, index) => {
      if (index < 3) {
        this.setupChannel(channel.chat_channel_id);
      }
    });
  };

  loadPaginatedChannels = (channels) => {
    const { state } = this;
    const currentChannels = state.chatChannels;
    const currentChannelIds = currentChannels.map((channel) => channel.id);
    const newChannels = currentChannels;
    channels.forEach((channel) => {
      if (!currentChannelIds.includes(channel.id)) {
        newChannels.push(channel);
      }
    });
    if (
      currentChannels.length === newChannels.length &&
      state.channelPaginationNum > 3
    ) {
      return;
    }
    this.setState({
      chatChannels: newChannels,
      fetchingPaginatedChannels: false,
      channelPaginationNum: state.channelPaginationNum + 1,
    });
  };

  setupChannel = (channelId) => {
    const {
      messages,
      messageOffset,
      activeChannel,
      activeChannelId,
    } = this.state;
    if (
      !messages[channelId] ||
      messages[channelId].length === 0 ||
      messages[channelId][0].reception_method === 'pushed'
    ) {
      getAllMessages(channelId, messageOffset, this.receiveAllMessages);
    }
    if (activeChannel && activeChannel.channel_type !== 'direct') {
      getContent(
        `/chat_channels/${activeChannelId}/channel_info`,
        this.setOpenChannelUsers,
        null,
      );
      if (activeChannel.channel_type === 'open')
        this.subscribePusher(`open-channel-${channelId}`);
    }
    this.subscribePusher(`presence-channel-${channelId}`);
  };

  setOpenChannelUsers = (res) => {
    const { activeChannelId, activeChannel } = this.state;
    Object.filter = (obj, predicate) =>
      Object.fromEntries(Object.entries(obj).filter(predicate));
    const leftUser = Object.filter(
      res.channel_users,
      ([username]) => username !== window.currentUser.username,
    );
    if (activeChannel.channel_type === 'open') {
      this.setState({
        channelUsers: {
          [activeChannelId]: leftUser,
        },
      });
    } else {
      this.setState({
        channelUsers: {
          [activeChannelId]: {
            all: { username: 'all', name: 'To notify everyone here' },
            ...leftUser,
          },
        },
      });
    }
  };

  observerCallback = (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting && this.state.scrolled === true) {
        this.setState({ scrolled: false, showAlert: false });
      } else if (this.state.scrolled === false) {
        this.setState({
          scrolled: true,
          rerenderIfUnchangedCheck: Math.random(),
        });
      }
    });
  };

  channelError = (_error) => {
    this.setState({
      subscribedPusherChannels: [],
    });
  };

  receiveAllMessages = (res) => {
    const { chatChannelId, messages } = res;
    this.setState((prevState) => ({
      messages: { ...prevState.messages, [chatChannelId]: messages },
      scrolled: false,
    }));
  };

  removeMessage = (message) => {
    const { activeChannelId } = this.state;
    this.setState((prevState) => ({
      messages: {
        [activeChannelId]: [
          ...prevState.messages[activeChannelId].filter(
            (oldmessage) => oldmessage.id !== message.id,
          ),
        ],
      },
    }));
  };

  updateMessage = (message) => {
    const { activeChannelId } = this.state;
    if (message.chat_channel_id === activeChannelId) {
      this.setState(({ messages }) => {
        const newMessages = messages;
        const foundIndex = messages[activeChannelId].findIndex(
          (oldMessage) => oldMessage.id === message.id,
        );
        newMessages[activeChannelId][foundIndex] = message;
        return { messages: newMessages };
      });
    }
  };

  receiveNewMessage = (message) => {
    const {
      messages,
      activeChannelId,
      scrolled,
      chatChannels,
      unopenedChannelIds,
    } = this.state;
    const receivedChatChannelId = message.chat_channel_id;
    const messageList = document.getElementById('messagelist');
    const nearBottom =
      messageList.scrollTop + messageList.offsetHeight + 400 >
      messageList.scrollHeight;
    if (nearBottom) {
      scrollToBottom();
    }
    let newMessages = [];
    if (
      message.temp_id &&
      messages[activeChannelId].findIndex(
        (oldmessage) => oldmessage.temp_id === message.temp_id,
      ) > -1
    ) {
      return;
    }

    if (messages[receivedChatChannelId]) {
      newMessages = messages[receivedChatChannelId].slice();
      newMessages.push(message);
      if (newMessages.length > 150) {
        newMessages.shift();
      }
    }
    const newShowAlert =
      activeChannelId === receivedChatChannelId
        ? { showAlert: !nearBottom }
        : {};
    let newMessageChannelIndex = 0;
    let newMessageChannel = null;
    const newChannelsObj = chatChannels.map((channel, index) => {
      if (receivedChatChannelId === channel.chat_channel_id) {
        newMessageChannelIndex = index;
        newMessageChannel = channel;
        return { ...channel, channel_last_message_at: new Date() };
      }
      return channel;
    });

    if (newMessageChannelIndex > 0) {
      newChannelsObj.splice(newMessageChannelIndex, 1);
      newChannelsObj.unshift(newMessageChannel);
    }

    if (receivedChatChannelId === activeChannelId) {
      sendOpen(receivedChatChannelId, this.handleChannelOpenSuccess, null);
    } else {
      const newUnopenedChannels = unopenedChannelIds;
      if (!unopenedChannelIds.includes(receivedChatChannelId)) {
        newUnopenedChannels.push(receivedChatChannelId);
      }
      this.setState({
        unopenedChannelIds: newUnopenedChannels,
      });
    }

    this.setState((prevState) => ({
      ...newShowAlert,
      chatChannels: newChannelsObj,
      messages: {
        ...prevState.messages,
        [receivedChatChannelId]: newMessages,
      },
    }));
  };

  redactUserMessages = (res) => {
    const { messages } = this.state;
    const newMessages = hideMessages(messages, res.userId);
    this.setState({ messages: newMessages });
  };

  clearChannel = (res) => {
    this.setState((prevState) => ({
      messages: { ...prevState.messages, [res.chat_channel_id]: [] },
    }));
  };

  handleChannelScroll = (e) => {
    const {
      fetchingPaginatedChannels,
      chatChannels,
      channelTypeFilter,
      filterQuery,
      activeChannelId,
      channelPaginationNum,
    } = this.state;

    if (fetchingPaginatedChannels || chatChannels.length < 30) {
      return;
    }
    const { target } = e;
    if (target.scrollTop + target.offsetHeight + 1800 > target.scrollHeight) {
      this.setState({ fetchingPaginatedChannels: true });

      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      const searchParams = {
        query: filterQuery,
        retrievalID: activeChannelId,
        searchType: '',
        paginationNumber: channelPaginationNum,
      };
      getChannels(searchParams, filters, this.loadPaginatedChannels);
    }
  };

  handleChannelInvites = (response) => {
    this.setState({ inviteChannels: response });
  };

  handleChannelJoiningRequest = (res) => {
    this.setState({ joiningRequests: res });
  };

  handleKeyDown = (e) => {
    const { showMemberlist, activeContent, activeChannelId } = this.state;
    const enterPressed = e.keyCode === 13;
    const leftPressed = e.keyCode === 37;
    const rightPressed = e.keyCode === 39;
    const escPressed = e.keyCode === 27;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;

    if (enterPressed) {
      if (showMemberlist) {
        e.preventDefault();
        const selectedUser = document.querySelector('.active__message__list');
        this.addUserName({ target: selectedUser });
      } else if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        this.handleMessageSubmit(e.target.value);
        e.target.value = '';
      }
    }
    if (e.target.value.includes('@')) {
      if (e.keyCode === 40 || e.keyCode === 38) {
        e.preventDefault();
      }
    }
    if (
      leftPressed &&
      activeContent[activeChannelId] &&
      e.target.value === '' &&
      document.getElementById('activecontent-iframe')
    ) {
      e.preventDefault();
      try {
        e.target.value = document.getElementById(
          'activecontent-iframe',
        ).contentWindow.location.href;
      } catch (err) {
        e.target.value = activeContent[activeChannelId].path;
      }
    }
    if (
      rightPressed &&
      !activeContent[activeChannelId] &&
      e.target.value === ''
    ) {
      e.preventDefault();
      const richLinks = document.querySelectorAll('.chatchannels__richlink');
      if (richLinks.length === 0) {
        return;
      }
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: richLinks[richLinks.length - 1].href,
        type_of: 'article',
      });
    }
    if (escPressed && activeContent[activeChannelId]) {
      this.setActiveContentState(activeChannelId, null);
      this.setState({
        fullscreenContent: null,
        expanded: window.innerWidth > 600,
      });
    }
  };

  handleKeyDownEdit = (e) => {
    const enterPressed = e.keyCode === 13;
    const targetValue = e.target.value;
    const messageIsEmpty = targetValue.length === 0;
    const shiftPressed = e.shiftKey;

    if (enterPressed) {
      if (messageIsEmpty) {
        e.preventDefault();
      } else if (!messageIsEmpty && !shiftPressed) {
        e.preventDefault();
        this.handleMessageSubmitEdit(e.target.value);
        e.target.value = '';
      }
    }
  };

  handleMessageSubmitEdit = (message) => {
    const { activeChannelId, activeEditMessage } = this.state;
    const editedMessage = {
      activeChannelId,
      id: activeEditMessage.id,
      message,
    };
    editMessage(editedMessage, this.handleSuccess, this.handleFailure);
    this.handleEditMessageClose();
  };

  handleMessageSubmit = (message) => {
    const { activeChannelId } = this.state;
    scrollToBottom();
    // should check if user has the privilege
    if (message.startsWith('/code')) {
      this.setActiveContentState(activeChannelId, { type_of: 'code_editor' });
    } else if (message.startsWith('/call')) {
      const messageObject = {
        activeChannelId,
        message: '/call',
        mentionedUsersId: this.getMentionedUsers(message),
      };
      this.setState({ videoPath: `/video_chats/${activeChannelId}` });
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    } else if (message.startsWith('/play ')) {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: this.getMentionedUsers(message),
      };
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    } else if (message.startsWith('/new')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: '/new',
        type_of: 'article',
      });
    } else if (message.startsWith('/search')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: `/search?q=${message.replace('/search ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/s ')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: `/search?q=${message.replace('/s ', '')}`,
        type_of: 'article',
      });
    } else if (message.startsWith('/')) {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: message,
        type_of: 'article',
      });
    } else if (message.startsWith('/github')) {
      const args = message.split('/github ')[1].trim();
      this.setActiveContentState(activeChannelId, { type_of: 'github', args });
    } else if (message[0] === '/') {
      conductModeration(
        activeChannelId,
        message,
        this.handleSuccess,
        this.handleFailure,
      );
    } else {
      const messageObject = {
        activeChannelId,
        message,
        mentionedUsersId: this.getMentionedUsers(message),
      };
      this.setState({ scrolled: false, showAlert: false });
      sendMessage(messageObject, this.handleSuccess, this.handleFailure);
    }
  };

  handleSwitchChannel = (e) => {
    e.preventDefault();
    let { target } = e;
    if (!target.dataset.channelId) {
      target = target.parentElement;
    }
    this.triggerSwitchChannel(
      parseInt(target.dataset.channelId, 10),
      target.dataset.channelSlug,
    );
  };

  triggerSwitchChannel = (id, slug) => {
    const {
      chatChannels,
      isMobileDevice,
      unopenedChannelIds,
      activeChannelId,
      currentUserId,
    } = this.state;
    const newUnopenedChannelIds = unopenedChannelIds;
    const index = newUnopenedChannelIds.indexOf(id);
    if (index > -1) {
      newUnopenedChannelIds.splice(index, 1);
    }
    this.setState({
      activeChannel: this.filterForActiveChannel(
        chatChannels,
        id,
        currentUserId,
      ),
      activeChannelId: parseInt(id, 10),
      scrolled: false,
      showAlert: false,
      allMessagesLoaded: false,
      unopenedChannelIds: unopenedChannelIds.filter(
        (unopenedId) => unopenedId !== id,
      ),
    });
    this.setupChannel(id);
    const params = new URLSearchParams(window.location.search);

    if (params.get('ref') === 'group_invite') {
      this.setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      this.setActiveContent({
        path: '/chat_channel_memberships',
        type_of: 'article',
      });
    }
    window.history.replaceState(null, null, `/connect/${slug}`);
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', window.location.pathname + window.location.search);
    }
    sendOpen(id, this.handleChannelOpenSuccess, null);
  };

  handleSubmitOnClick = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmit(message);
      document.getElementById('messageform').value = '';
    }
  };

  handleSubmitOnClickEdit = (e) => {
    e.preventDefault();
    const message = document.getElementById('messageform').value;
    if (message.length > 0) {
      this.handleMessageSubmitEdit(message);
      document.getElementById('messageform').value = '';
    }
  };

  triggerDeleteMessage = (e) => {
    this.setState({ messageDeleteId: e.target.dataset.content });
    this.setState({ showDeleteModal: true });
  };

  triggerEditMessage = (e) => {
    const { messages, activeChannelId } = this.state;
    this.setState({
      activeEditMessage: messages[activeChannelId].filter(
        (message) => message.id === parseInt(e.target.dataset.content, 10),
      )[0],
    });
    this.setState({ startEditing: true });
  };

  handleSuccess = (response) => {
    const { activeChannelId } = this.state;
    scrollToBottom();
    if (response.status === 'success') {
      if (response.message.temp_id) {
        this.setState(({ messages }) => {
          const newMessages = messages;
          const foundIndex = messages[activeChannelId].findIndex(
            (message) => message.temp_id === response.message.temp_id,
          );
          if (foundIndex > 0) {
            newMessages[activeChannelId][foundIndex].id = response.message.id;
          }
          return { messages: newMessages };
        });
      }
    } else if (response.status === 'error') {
      this.receiveNewMessage(response.message);
    }
  };

  handleRequestRejection = (e) => {
    rejectJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId,
      this.handleJoiningManagerSuccess(e.target.dataset.membershipId),
      null,
    );
  };

  handleRequestApproval = (e) => {
    acceptJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId,
      this.handleJoiningManagerSuccess(e.target.dataset.membershipId),
      null,
    );
  };

  triggerActiveContent = (e) => {
    if (
      // Trying to open in new tab
      e.ctrlKey ||
      e.shiftKey ||
      e.metaKey || // apple
      (e.button && e.button === 1) // middle click, >IE9 + everyone else
    ) {
      return false;
    }
    const { target } = e;
    const content =
      target.dataset.content || target.parentElement.dataset.content;
    if (content) {
      e.preventDefault();
      e.stopPropagation();

      const { activeChannelId, activeChannel } = this.state;

      if (content.startsWith('chat_channels/')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-user',
        });
        getContent(`/${content}/channel_info`, this.setActiveContent, null);
      } else if (content === 'sidecar-channel-request') {
        this.setActiveContent({
          data: {
            user: getCurrentUser(),
            channel: {
              id: target.dataset.channelId,
              name: target.dataset.channelName,
              status: target.dataset.channelStatus,
            },
          },
          handleJoiningRequest: this.handleJoiningRequest,
          type_of: 'channel-request',
        });
      } else if (content === 'sidecar-joining-request-manager') {
        this.setActiveContent({
          data: this.state.joiningRequests,
          type_of: 'channel-request-manager',
          handleRequestRejection: this.handleRequestRejection,
          handleRequestApproval: this.handleRequestApproval,
        });
      } else if (content === 'sidecar_all') {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: `/chat_channel_memberships/${activeChannel.id}/edit`,
          type_of: 'article',
        });
      } else if (content.startsWith('sidecar-content-plus-video')) {
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
        this.setState({ videoPath: `/video_chats/${activeChannelId}` });
      } else if (content.startsWith('sidecar-video')) {
        this.setState({ videoPath: target.href || target.parentElement.href });
      } else if (
        content.startsWith('sidecar') ||
        content.startsWith('article')
      ) {
        // article is legacy which can be removed shortly
        this.setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        this.setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
      } else if (target.dataset.content === 'exit') {
        this.setActiveContentState(activeChannelId, null);
        this.setState({
          fullscreenContent: null,
          expanded: window.innerWidth > 600,
        });
      } else if (target.dataset.content === 'fullscreen') {
        const mode =
          this.state.fullscreenContent === 'sidecar' ? null : 'sidecar';
        this.setState({
          fullscreenContent: mode,
          expanded: mode === null || window.innerWidth > 1600,
        });
      } else if (target.dataset.content === 'chat_channel_setting') {
        this.setActiveContent({
          data: {},
          type_of: 'chat-channel-setting',
          activeMembershipId: activeChannel.id,
        });
      }
    }
    return false;
  };

  setActiveContentState = (channelId, state) => {
    this.setState((prevState) => ({
      activeContent: {
        ...prevState.activeContent,
        [channelId]: state,
      },
    }));
  };

  setActiveContent = (response) => {
    const { activeChannelId } = this.state;
    this.setActiveContentState(activeChannelId, response);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 3);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 10);
  };

  handleChannelOpenSuccess = (response) => {
    this.setState(({ chatChannels }) => {
      const newChannelsObj = chatChannels.map((channel) => {
        if (parseInt(response.channel, 10) === channel.chat_channel_id) {
          return { ...channel, last_opened_at: new Date() };
        }
        return channel;
      });
      return { chatChannels: newChannelsObj };
    });
  };

  handleInvitationAccept = (e) => {
    const id = e.target.dataset.content;
    sendChannelInviteAction(id, 'accept', this.handleChannelInviteResult, null);
  };

  handleInvitationDecline = (e) => {
    const id = e.target.dataset.content;
    sendChannelInviteAction(
      id,
      'decline',
      this.handleChannelInviteResult,
      null,
    );
  };

  handleChannelInviteResult = (response) => {
    this.setState({ inviteChannels: response });
  };

  triggerChannelTypeFilter = (e) => {
    const { filterQuery } = this.state;
    const type = e.target.dataset.channelType;
    this.setState({
      channelTypeFilter: type,
      fetchingPaginatedChannels: false,
    });
    const filters = type === 'all' ? {} : { filters: `channel_type:${type}` };
    const searchParams = {
      query: filterQuery,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (filterQuery && type !== 'direct') {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, this.loadChannels);
    } else {
      getChannels(searchParams, filters, this.loadChannels);
    }
  };

  handleFailure = (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
  };

  renderMessages = () => {
    const {
      activeChannelId,
      messages,
      showTimestamp,
      activeChannel,
      currentUserId,
    } = this.state;
    if (!messages[activeChannelId]) {
      return '';
    }
    if (messages[activeChannelId].length === 0 && activeChannel) {
      if (activeChannel.channel_type === 'direct') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You and
              {' '}
              <a href={`/${activeChannel.channel_modified_slug}`}>
                {activeChannel.channel_modified_slug}
              </a>
              {' '}
              are connected because you both follow each other. All interactions
              {' '}
              <em>
                <b>must</b>
              </em>
              {' '}
              abide by the
              {' '}
              <a href="/code-of-conduct">code of conduct</a>
              .
            </div>
          </div>
        );
      }
      if (activeChannel.channel_type === 'open') {
        return (
          <div className="chatmessage" style={{ color: 'grey' }}>
            <div className="chatmessage__body">
              You have joined
              {' '}
              {activeChannel.channel_name}
              ! All interactions
              {' '}
              <em>
                <b>must</b>
              </em>
              {' '}
              abide by the
              {' '}
              <a href="/code-of-conduct">code of conduct</a>
              .
            </div>
          </div>
        );
      }
    }

    return messages[activeChannelId].map((message) =>
      message.action ? (
        <ActionMessage
          user={message.username}
          profileImageUrl={message.profile_image_url}
          message={message.message}
          timestamp={showTimestamp ? message.timestamp : null}
          color={message.color}
          onContentTrigger={this.triggerActiveContent}
        />
      ) : (
        <Message
          currentUserId={currentUserId}
          id={message.id}
          user={message.username}
          userID={message.user_id}
          profileImageUrl={message.profile_image_url}
          message={message.message}
          timestamp={showTimestamp ? message.timestamp : null}
          editedAt={message.edited_at}
          color={message.color}
          onContentTrigger={this.triggerActiveContent}
          onDeleteMessageTrigger={this.triggerDeleteMessage}
          onEditMessageTrigger={this.triggerEditMessage}
        />
      ),
    );
  };

  triggerChannelFilter = (e) => {
    const { channelTypeFilter } = this.state;
    const filters =
      channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${channelTypeFilter}` };
    const searchParams = {
      query: e.target.value,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (e.target.value) {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, this.loadChannels);
    } else {
      getChannels(searchParams, filters, this.loadChannels);
    }
  };

  toggleExpand = () => {
    this.setState((prevState) => ({ expanded: !prevState.expanded }));
  };

  renderChannelFilterButton = (type, name, active) => (
    <button
      data-channel-type={type}
      onClick={this.triggerChannelTypeFilter}
      className={`chat__channeltypefilterbutton crayons-indicator crayons-indicator--${
        type === active ? 'accent' : ''
      }`}
      type="button"
    >
      {name}
    </button>
  );

  toggleSearchShowing = () => {
    if (!this.state.searchShowing) {
      setTimeout(() => {
        document.getElementById('chatchannelsearchbar').focus();
      }, 100);
    } else {
      const searchParams = {
        query: '',
        retrievalID: null,
        searchType: '',
        paginationNumber: 0,
      };
      getChannels(searchParams, this.loadChannels);
      this.setState({ filterQuery: '' });
    }
    this.setState({ searchShowing: !this.state.searchShowing });
  };

  renderChatChannels = () => {
    const { state } = this;
    if (state.showChannelsList) {
      const { notificationsPermission } = state;
      const notificationsButton = '';
      let notificationsState = '';
      let invitesButton = '';
      let joiningRequestButton = '';
      if (notificationsPermission === 'granted') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--on">
            Notifications On
          </div>
        );
      } else if (notificationsPermission === 'denied') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--off">
            Notifications Off
          </div>
        );
      }
      if (state.inviteChannels.length > 0) {
        invitesButton = (
          <div className="chat__channelinvitationsindicator">
            <a
              href="/chat_channel_memberships"
              onClick={this.triggerActiveContent}
              data-content="sidecar-chat_channel_memberships"
              type="button"
            >
              <span role="img" aria-label="emoji">
                👋
              </span>
              {' '}
              New Invitations!
            </a>
          </div>
        );
      }
      if (state.joiningRequests.length > 0) {
        joiningRequestButton = (
          <div className="chat__channelinvitationsindicator">
            <button
              onClick={this.triggerActiveContent}
              data-content="sidecar-joining-request-manager"
              type="button"
            >
              <span role="img" aria-label="emoji">
                👋
              </span>
              {' '}
              New Requests
            </button>
          </div>
        );
      }
      if (state.expanded) {
        return (
          <div className="chat__channels chat__channels--expanded">
            {notificationsButton}
            <button
              className="chat__channelstogglebutt"
              onClick={this.toggleExpand}
              type="button"
              title="Collapse channels"
            >
              {'<'}
            </button>
            {state.searchShowing ? (
              <input
                placeholder="Search Channels"
                onKeyUp={this.debouncedChannelFilter}
                id="chatchannelsearchbar"
                className="crayons-textfield"
                aria-label="Search Channels"
              />
            ) : (
              ''
            )}
            {invitesButton}
            {joiningRequestButton}
            <div className="chat__channeltypefilter">
              <button
                className="chat__channelssearchtoggle"
                onClick={this.toggleSearchShowing}
                aria-label="Toggle channel search"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  width="17"
                  height="17"
                >
                  <path fill="none" d="M0 0h24v24H0z" />
                  <path d="M18.031 16.617l4.283 4.282-1.415 1.415-4.282-4.283A8.96 8.96 0 0 1 11 20c-4.968 0-9-4.032-9-9s4.032-9 9-9 9 4.032 9 9a8.96 8.96 0 0 1-1.969 5.617zm-2.006-.742A6.977 6.977 0 0 0 18 11c0-3.868-3.133-7-7-7-3.868 0-7 3.132-7 7 0 3.867 3.132 7 7 7a6.977 6.977 0 0 0 4.875-1.975l.15-.15z" />
                </svg>
              </button>
              {this.renderChannelFilterButton(
                'all',
                'all',
                state.channelTypeFilter,
              )}
              {this.renderChannelFilterButton(
                'direct',
                'direct',
                state.channelTypeFilter,
              )}
              {this.renderChannelFilterButton(
                'invite_only',
                'group',
                state.channelTypeFilter,
              )}
            </div>
            <Channels
              activeChannelId={state.activeChannelId}
              chatChannels={state.chatChannels}
              unopenedChannelIds={state.unopenedChannelIds}
              handleSwitchChannel={this.handleSwitchChannel}
              channelsLoaded={state.channelsLoaded}
              filterQuery={state.filterQuery}
              expanded={state.expanded}
              aria-expanded={state.expanded}
              currentUserId={state.currentUserId}
              triggerActiveContent={this.triggerActiveContent}
            />
            {notificationsState}
          </div>
        );
      }
      return (
        <div className="chat__channels">
          {notificationsButton}
          <button
            className="chat__channelstogglebutt"
            onClick={this.toggleExpand}
            style={{ width: '100%' }}
            type="button"
            title="Expand channels"
          >
            {'>'}
          </button>
          <Channels
            activeChannelId={state.activeChannelId}
            chatChannels={state.chatChannels}
            unopenedChannelIds={state.unopenedChannelIds}
            handleSwitchChannel={this.handleSwitchChannel}
            channelsLoaded={state.channelsLoaded}
            filterQuery={state.filterQuery}
            expanded={state.expanded}
            currentUserId={state.currentUserId}
            triggerActiveContent={this.triggerActiveContent}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  handleMessageScroll = () => {
    const {
      allMessagesLoaded,
      messages,
      activeChannelId,
      messageOffset,
    } = this.state;

    if (!messages[activeChannelId]) {
      return;
    }

    const jumpbackButton = document.getElementById('jumpback_button');

    if (this.scroller) {
      const scrolledRatio =
        (this.scroller.scrollTop + this.scroller.clientHeight) /
        this.scroller.scrollHeight;

      if (scrolledRatio < 0.5) {
        jumpbackButton.classList.remove('chatchanneljumpback__hide');
      } else if (scrolledRatio > 0.6) {
        jumpbackButton.classList.add('chatchanneljumpback__hide');
      }

      if (this.scroller.scrollTop === 0 && !allMessagesLoaded) {
        getAllMessages(
          activeChannelId,
          messageOffset + messages[activeChannelId].length,
          this.addMoreMessages,
        );
        const curretPosition = this.scroller.scrollHeight;
        this.setState({ currentMessageLocation: curretPosition });
      }
    }
  };

  addMoreMessages = (res) => {
    const { chatChannelId, messages } = res;

    if (messages.length > 0) {
      this.setState((prevState) => ({
        messages: {
          [chatChannelId]: [...messages, ...prevState.messages[chatChannelId]],
        },
      }));
    } else {
      this.setState({ allMessagesLoaded: true });
    }
  };

  jumpBacktoBottom = () => {
    scrollToBottom();
    document
      .getElementById('jumpback_button')
      .classList.remove('chatchanneljumpback__hide');
  };

  renderActiveChatChannel = (channelHeader) => {
    const { state, props } = this;

    return (
      <div className="activechatchannel">
        <div className="activechatchannel__conversation">
          {channelHeader}
          <div
            className="activechatchannel__messages"
            onScroll={this.handleMessageScroll}
            ref={(scroller) => {
              this.scroller = scroller;
            }}
            id="messagelist"
          >
            {this.renderMessages()}
            <div className="messagelist__sentinel" id="messagelist__sentinel" />
          </div>
          <div
            className="chatchanneljumpback chatchanneljumpback__hide"
            id="jumpback_button"
          >
            <div
              role="button"
              className="chatchanneljumpback__messages"
              onClick={this.jumpBacktoBottom}
              tabIndex="0"
              onKeyUp={(e) => {
                if (e.keyCode === 13) this.jumpBacktoBottom();
              }}
            >
              Scroll to Bottom
            </div>
          </div>
          {this.renderDeleteModal()}
          <div className="activechatchannel__alerts">
            <Alert showAlert={state.showAlert} />
          </div>
          {this.renderChannelMembersList()}
          <div className="activechatchannel__form">
            <Compose
              handleSubmitOnClick={this.handleSubmitOnClick}
              handleKeyDown={this.handleKeyDown}
              handleSubmitOnClickEdit={this.handleSubmitOnClickEdit}
              handleMention={this.handleMention}
              handleKeyUp={this.handleKeyUp}
              handleKeyDownEdit={this.handleKeyDownEdit}
              activeChannelId={state.activeChannelId}
              startEditing={state.startEditing}
              markdownEdited={state.markdownEdited}
              editMessageMarkdown={state.activeEditMessage.markdown}
              handleEditMessageClose={this.handleEditMessageClose}
            />
          </div>
        </div>
        <Content
          onTriggerContent={this.triggerActiveContent}
          resource={state.activeContent[state.activeChannelId]}
          activeChannel={state.activeChannel}
          githubToken={props.githubToken}
          fullscreen={state.fullscreenContent === 'sidecar'}
        />
        <VideoContent
          videoPath={state.videoPath}
          onTriggerVideoContent={this.onTriggerVideoContent}
          fullscreen={state.fullscreenContent === 'video'}
        />
      </div>
    );
  };

  onTriggerVideoContent = (e) => {
    if (e.target.dataset.content === 'exit') {
      this.setState({
        videoPath: null,
        fullscreenContent: null,
        expanded: window.innerWidth > 600,
      });
    } else if (this.state.fullscreenContent === 'video') {
      this.setState({ fullscreenContent: null });
    } else {
      this.setState({
        fullscreenContent: 'video',
        expanded: window.innerWidth > 1600,
      });
    }
  };

  handleMention = (e) => {
    const { activeChannel } = this.state;
    const mention = e.keyCode === 64;
    if (mention && activeChannel.channel_type !== 'direct') {
      this.setState({ showMemberlist: true });
    }
  };

  handleKeyUp = (e) => {
    const { startEditing, activeChannel, showMemberlist } = this.state;
    const enterPressed = e.keyCode === 13;
    if (enterPressed && showMemberlist)
      this.setState({ showMemberlist: false });
    if (activeChannel.channel_type !== 'direct') {
      if (startEditing) {
        this.setState({ markdownEdited: true });
      }
      if (!e.target.value.includes('@') && showMemberlist) {
        this.setState({ showMemberlist: false });
      } else {
        this.setQuery(e.target);
        this.listHighlightManager(e.keyCode);
      }
    }
  };

  setQuery = (e) => {
    const { showMemberlist } = this.state;
    if (showMemberlist) {
      const before = e.value.substring(0, e.selectionStart);
      const query = before.substring(
        before.lastIndexOf('@') + 1,
        e.selectionStart,
      );

      if (query.includes(' ') || before.lastIndexOf('@') < 0)
        this.setState({ showMemberlist: false });
      else {
        this.setState({ showMemberlist: true });
        this.setState({ memberFilterQuery: query });
      }
    }
  };

  addUserName = (e) => {
    const name =
      e.target.dataset.content || e.target.parentElement.dataset.content;
    const el = document.getElementById('messageform');
    const start = el.selectionStart;
    const end = el.selectionEnd;
    const text = el.value;
    let before = text.substring(0, start);
    before = text.substring(0, before.lastIndexOf('@') + 1);
    const after = text.substring(end, text.length);
    el.value = `${before + name} ${after}`;
    el.selectionStart = start + name.length + 1;
    el.selectionEnd = start + name.length + 1;
    el.focus();
    this.setState({ showMemberlist: false });
  };

  listHighlightManager = (keyCode) => {
    const mentionList = document.getElementById('mentionList');
    const activeElement = document.querySelector('.active__message__list');
    if (mentionList.children.length > 0) {
      if (keyCode === 40 && activeElement) {
        if (activeElement.nextElementSibling) {
          activeElement.classList.remove('active__message__list');
          activeElement.nextElementSibling.classList.add(
            'active__message__list',
          );
        }
      } else if (keyCode === 38 && activeElement) {
        if (activeElement.previousElementSibling) {
          activeElement.classList.remove('active__message__list');
          activeElement.previousElementSibling.classList.add(
            'active__message__list',
          );
        }
      } else {
        mentionList.children[0].classList.add('active__message__list');
      }
    }
  };

  getMentionedUsers = (message) => {
    const { channelUsers, activeChannelId, activeChannel } = this.state;
    if (channelUsers[activeChannelId]) {
      if (message.includes('@all') && activeChannel.channel_type !== 'open') {
        return Array.from(
          Object.values(channelUsers[activeChannelId]).filter(
            (user) => user.id,
          ),
          (user) => user.id,
        );
      }
      return Array.from(
        Object.values(channelUsers[activeChannelId]).filter((user) =>
          message.includes(user.username),
        ),
        (user) => user.id,
      );
    }
    return null;
  };

  renderChannelMembersList = () => {
    const {
      showMemberlist,
      activeChannelId,
      channelUsers,
      memberFilterQuery,
    } = this.state;
    const filterRegx = new RegExp(memberFilterQuery, 'gi');
    return (
      <div
        className={
          showMemberlist ? 'mention__list mention__visible' : 'mention__list'
        }
        id="mentionList"
      >
        {showMemberlist
          ? Object.values(channelUsers[activeChannelId])
              .filter((user) => user.username.match(filterRegx))
              .map((user) => (
                <div
                  key={user.username}
                  className="mention__user"
                  role="button"
                  onClick={this.addUserName}
                  tabIndex="0"
                  data-content={user.username}
                  onKeyUp={(e) => {
                    if (e.keyCode === 13) this.addUserName();
                  }}
                >
                  <img
                    className="mention__user__image"
                    src={user.profile_image}
                    alt={user.name}
                    style={!user.profile_image ? { display: 'none' } : ' '}
                  />
                  <span
                    style={{
                      padding: '3px 0px',
                      'font-size': '16px',
                    }}
                  >
                    {'@'}
                    {user.username}
                    <p>{user.name}</p>
                  </span>
                </div>
              ))
          : ' '}
      </div>
    );
  };

  handleEditMessageClose = () => {
    const textarea = document.getElementById('messageform');
    this.setState({
      startEditing: false,
      markdownEdited: false,
      activeEditMessage: { message: '', markdown: '' },
    });
    textarea.value = '';
  };

  renderDeleteModal = () => {
    const { showDeleteModal } = this.state;
    return (
      <div
        id="message"
        className={
          showDeleteModal
            ? 'message__delete__modal crayons-modal crayons-modal--s absolute'
            : 'message__delete__modal message__delete__modal__hide crayons-modal crayons-modal--s absolute'
        }
        aria-hidden={showDeleteModal}
        role="dialog"
      >
        <div className="crayons-modal__box">
          <div className="crayons-modal__box__body">
            <h3>Are you sure, you want to delete this message ?</h3>
            <div className="delete-actions__container">
              <div
                role="button"
                className="crayons-btn crayons-btn--danger message__delete__button"
                onClick={this.handleMessageDelete}
                tabIndex="0"
                onKeyUp={(e) => {
                  if (e.keyCode === 13) this.handleMessageDelete();
                }}
              >
                {' '}
                Delete
              </div>
              <div
                role="button"
                className="crayons-btn crayons-btn--secondary message__cancel__button"
                onClick={this.handleCloseDeleteModal}
                tabIndex="0"
                onKeyUp={(e) => {
                  if (e.keyCode === 13) this.handleCloseDeleteModal();
                }}
              >
                {' '}
                Cancel
              </div>
            </div>
          </div>
        </div>
        <div className="crayons-modal__overlay" />
      </div>
    );
  };

  handleCloseDeleteModal = () => {
    this.setState({ showDeleteModal: false, messageDeleteId: null });
  };

  handleMessageDelete = () => {
    const { messageDeleteId } = this.state;
    deleteMessage(messageDeleteId);
    this.setState({ showDeleteModal: false });
  };

  handleJoiningRequest = (e) => {
    sendChannelRequest(
      e.target.dataset.channelId,
      this.handleJoiningRequestSuccess,
      null,
    );
  };

  handleJoiningManagerSuccess = (membershipId) => {
    const { activeChannelId } = this.state;
    this.setState({
      joiningRequests: this.state.joiningRequests.filter(
        (req) => req.membership_id !== parseInt(membershipId, 10),
      ),
    });
    this.setActiveContentState(activeChannelId, null);
    this.setState({ fullscreenContent: null });
  };

  handleJoiningRequestSuccess = () => {
    const { activeChannelId } = this.state;
    this.setActiveContentState(activeChannelId, null);
    this.setState({ fullscreenContent: null });
    this.toggleSearchShowing();
  };

  renderChannelHeaderInner = () => {
    const { activeChannel } = this.state;
    if (activeChannel.channel_type === 'direct') {
      return (
        <a
          href={`/${activeChannel.channel_username}`}
          className="active-channel__title"
          onClick={this.triggerActiveContent}
          data-content="sidecar-user"
        >
          {activeChannel.channel_modified_slug}
        </a>
      );
    }
    return (
      <a
        href="#/"
        onClick={this.triggerActiveContent}
        data-content="chat_channel_setting"
      >
        {activeChannel.channel_name}
      </a>
    );
  };

  renderChannelConfigImage = () => {
    const { activeContent, activeChannel, activeChannelId } = this.state;
    if (
      activeContent[activeChannelId] &&
      activeContent[activeChannelId].type_of
    ) {
      return '';
    }

    const path =
      activeChannel.channel_type === 'direct'
        ? `/${activeChannel.channel_username}`
        : `#`;

    const dataContent =
      activeChannel.channel_type === 'direct'
        ? 'sidecar-user'
        : `chat_channel_setting`;

    return (
      <a
        className="crayons-btn crayons-btn--icon-rounded crayons-btn--secondary"
        onClick={this.triggerActiveContent}
        onKeyUp={(e) => {
          if (e.keyCode === 13) this.triggerActiveContent(e);
        }}
        tabIndex="0"
        href={path}
        data-content={dataContent}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width="24"
          height="24"
          className="crayons-icon"
        >
          <path d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM11 7h2v2h-2V7zm0 4h2v6h-2v-6z" />
        </svg>
      </a>
    );
  };

  render() {
    const { state } = this;
    const detectIOSSafariClass =
      navigator.userAgent.match(/iPhone/i) &&
      !navigator.userAgent.match('CriOS')
        ? ' chat--iossafari'
        : '';
    let channelHeader = <div className="active-channel__header">&nbsp;</div>;
    if (state.activeChannel) {
      channelHeader = (
        <div className="active-channel__header">
          {this.renderChannelHeaderInner()}
          {this.renderChannelConfigImage()}
        </div>
      );
    }
    let fullscreenMode = '';
    if (state.fullscreenContent === 'sidecar') {
      fullscreenMode = 'chat--content-visible-full';
    } else if (state.fullscreenContent === 'video') {
      fullscreenMode = 'chat--video-visible-full';
    }
    return (
      <div
        data-testid="chat"
        className={`chat chat--${
          state.expanded ? 'expanded' : 'contracted'
        }${detectIOSSafariClass} chat--${
          state.videoPath ? 'video-visible' : 'video-not-visible'
        } chat--${
          state.activeContent[state.activeChannelId]
            ? 'content-visible'
            : 'content-not-visible'
        } ${fullscreenMode}`}
        data-no-instant
        aria-expanded={state.expanded}
      >
        {this.renderChatChannels()}
        <div data-testid="active-chat" className="chat__activechat">
          {this.renderActiveChatChannel(channelHeader)}
        </div>
      </div>
    );
  }
}
