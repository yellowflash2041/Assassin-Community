import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken, userData, updateOnboarding } from '../utilities';

/* eslint-disable camelcase */
class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.user = userData();

    this.state = {
      checked_code_of_conduct: false,
      checked_terms_and_conditions: false,
      text: null,
    };
  }

  componentDidMount() {
    updateOnboarding('v2: intro, code of conduct, terms & conditions');
  }

  onSubmit() {
    const { next } = this.props;
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_checkbox_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: this.state }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        localStorage.setItem('shouldRedirectToOnboarding', false);
        next();
      }
    });
  }

  handleChange(event) {
    const { name } = event.target;
    this.setState((currentState) => ({
      [name]: !currentState[name],
    }));
  }

  handleShowText(event, id) {
    event.preventDefault();
    this.setState({ text: document.getElementById(id).innerHTML });
  }

  isButtonDisabled() {
    const {
      checked_code_of_conduct,
      checked_terms_and_conditions,
    } = this.state;

    return !checked_code_of_conduct || !checked_terms_and_conditions;
  }

  render() {
    const { prev } = this.props;
    const {
      checked_code_of_conduct,
      checked_terms_and_conditions,
      text,
    } = this.state;

    if (text) {
      return (
        <div className="onboarding-main">
          <div className="onboarding-content terms-and-conditions-wrapper">
            <button type="button" onClick={() => this.setState({ text: null })}>
              Back
            </button>
            <div
              className="terms-and-conditions-content"
              /* eslint-disable react/no-danger */
              dangerouslySetInnerHTML={{ __html: text }}
              /* eslint-enable react/no-danger */
            />
          </div>
        </div>
      );
    }

    return (
      <div className="onboarding-main introduction">
        <div className="onboarding-content">
          <figure>
            <img
              src="/assets/purple-dev-logo.png"
              className="sticker-logo"
              alt="DEV"
            />
          </figure>
          <h1 className="introduction-title">
            {this.user.name}
            {' '}
            &mdash; welcome to DEV!
          </h1>
          <h2 className="introduction-subtitle">
            DEV is where programmers share ideas and help each other grow.
          </h2>
        </div>

        <div className="checkbox-form-wrapper">
          <form className="checkbox-form">
            <fieldset>
              <ul>
                <li className="checkbox-item">
                  <label htmlFor="checked_code_of_conduct">
                    <input
                      type="checkbox"
                      id="checked_code_of_conduct"
                      name="checked_code_of_conduct"
                      checked={checked_code_of_conduct}
                      onChange={this.handleChange}
                    />
                    You agree to uphold our
                    {' '}
                    <a
                      href="/code-of-conduct"
                      data-no-instant
                      onClick={(e) => this.handleShowText(e, 'coc')}
                    >
                      Code of Conduct
                    </a>
                    .
                  </label>
                </li>

                <li className="checkbox-item">
                  <label htmlFor="checked_terms_and_conditions">
                    <input
                      type="checkbox"
                      id="checked_terms_and_conditions"
                      name="checked_terms_and_conditions"
                      checked={checked_terms_and_conditions}
                      onChange={this.handleChange}
                    />
                    You agree to our
                    {' '}
                    <a
                      href="/terms"
                      data-no-instant
                      onClick={(e) => this.handleShowText(e, 'terms')}
                    >
                      Terms and Conditions
                    </a>
                    .
                  </label>
                </li>
              </ul>
            </fieldset>
          </form>
          <Navigation
            disabled={this.isButtonDisabled()}
            className="intro-slide"
            prev={prev}
            next={this.onSubmit}
            hidePrev
          />
        </div>
      </div>
    );
  }
}

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default IntroSlide;

/* eslint-enable camelcase */
