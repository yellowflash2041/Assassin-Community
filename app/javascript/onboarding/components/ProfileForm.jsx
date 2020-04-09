import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { userData, getContentOfToken, updateOnboarding } from '../utilities';

class ProfileForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.user = userData();

    this.state = {
      summary: '',
      location: '',
      employment_title: '',
      employer_name: '',
      last_onboarding_page: 'v2: personal info form',
    };
  }

  componentDidMount() {
    updateOnboarding('bio form');
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { ...this.state } }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        const { next } = this.props;
        next();
      }
    })
  }

  handleChange(e) {
    const { name, value } = e.target;

    this.setState({
      [name]: value,
    });
  }

  render() {
    const { prev } = this.props;
    const { profile_image_90, username, name } = this.user;
    return (
      <div className="onboarding-main">
        <Navigation prev={prev} next={this.onSubmit} />
        <div className="onboarding-content about">
          <header className="onboarding-content-header">
            <h1 className="title">Build your profile</h1>
            <h2 className="subtitle">
              Tell us a little bit about yourself — this is how others will see
              you on DEV. You’ll always be able to edit this later in your
              Settings.
            </h2>
          </header>
          <div className="current-user-info">
            <figure className="current-user-avatar-container">
              <img className="current-user-avatar" alt="profile" src={profile_image_90} />
            </figure>
            <h3>{name}</h3>
            <p>{username}</p>
          </div>
          <form>
            <label htmlFor="summary">
              Bio
              <textarea
                name="summary"
                id="summary"
                placeholder="Tell us about yourself"
                onChange={this.handleChange}
                maxLength="120"
              />
            </label>
            <label htmlFor="location">
              Where are you located?
              <input
                type="text"
                name="location"
                id="location"
                placeholder="e.g. New York, NY"
                onChange={this.handleChange}
                maxLength="60"
              />
            </label>
            <label htmlFor="employment_title">
              What is your title?
              <input
                type="text"
                name="employment_title"
                id="employment_title"
                placeholder="e.g. Software Engineer"
                onChange={this.handleChange}
                maxLength="60"
              />
            </label>
            <label htmlFor="employer_name">
              Where do you work?
              <input
                type="text"
                name="employer_name"
                id="employer_name"
                placeholder="e.g. Company name, self-employed, etc."
                onChange={this.handleChange}
                maxLength="60"
              />
            </label>
          </form>
        </div>
      </div>
    );
  }
}

ProfileForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default ProfileForm;
