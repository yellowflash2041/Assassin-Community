import { h, render, Component } from 'preact';
import setupPusher from './pusher';



class UnopenedChannelNotice extends Component {
  constructor(props) {
    super(props);
    const unopenedChannels = this.props.unopenedChannels;
    const visible = unopenedChannels.length > 0 ? true : false;
    this.state = {
      visible: visible,
      unopenedChannels }
  }

  componentDidMount() {
    setupPusher(this.props.pusherKey, {
      channelId: `private-message-notifications-${window.currentUser.id}`,
      messageCreated: this.receiveNewMessage,
    });
    const component = this;
    document.getElementById("connect-link").onclick = function(){
      //Hack, should probably be its own component in future
      document.getElementById("connect-number").classList.remove("showing");
      component.setState({visible: false});
    }
  }

  receiveNewMessage = e => {
    if (location.pathname.startsWith("/connect")) {
      return
    }
    let channels = this.state.unopenedChannels;
    const newObj = {adjusted_slug: e.chat_channel_adjusted_slug}
    if(channels.filter(obj => obj.adjusted_slug === newObj.adjusted_slug).length === 0 &&
      newObj.adjusted_slug != `@${window.currentUser.username}`) {
      channels.push(newObj);
    }
    this.setState({
      visible: (channels.length > 0 && e.user_id != window.currentUser.id),
      unopenedChannels: channels
    })

    const number = document.getElementById("connect-number")
    number.classList.add("showing")
    number.innerHTML = channels.length
    const component = this;
    if (channels.length === 0) {
      number.classList.remove("showing")
    } else {
      document.getElementById("connect-link").href = `/connect/${channels[0].adjusted_slug}`
    }
    setTimeout(function(){
      component.setState({visible: false});
    }, 7500)
  }

  handleClick = e => {
    document.getElementById("connect-number").classList.remove("showing");
    this.setState({visible: false})
  }
  render() {
    if (this.state.visible) {
      const channels = this.state.unopenedChannels.map(channel => {
        return <a
          href={"/connect/"+channel.adjusted_slug}
          style={{
          background: "#66e2d5",
          color: "black",
          border: "1px solid black",
          padding: "2px 7px",
          display: "inline-block",
          margin: "3px 6px",
          borderRadius: "3px"}}>{channel.adjusted_slug}</a>
      });
      return (
        <a
          onClick={this.handleClick}
          href={"/connect/"+this.state.unopenedChannels[0].adjusted_slug}
          style={{
          position: 'fixed',
          zIndex: '200',
          top: '44px',
          right: 0,
          left: 0,
          background: '#66e2d5',
          borderBottom: '1px solid black',
          color: 'black',
          fontWeight: 'bold',
          textAlign: 'center',
          fontSize: '17px',
          opacity: '0.94',
          padding: '19px 5px 14px'}}>
          New Message from {channels}
        </a>
      );
    }
  }
}

export default function getUnopenedChannels(user, successCb) {
  render(<UnopenedChannelNotice unopenedChannels={[]} pusherKey={document.body.dataset.pusherKey} />, document.getElementById('message-notice'));
  if (location.pathname.startsWith("/connect")) {
    return
  }
  fetch('/chat_channels?state=unopened', {
    method: 'GET',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      const number = document.getElementById("connect-number")
      if (json.length > 0) {
        number.classList.add("showing")
        number.innerHTML = json.length
        document.getElementById("connect-link").href = `/connect/${json[0].adjusted_slug}`  // Jump the user directly to the channel where appropriate
      } else {
        number.classList.remove("showing")
      }
    })
    .catch(error => {
      console.log(error);
    });
}
