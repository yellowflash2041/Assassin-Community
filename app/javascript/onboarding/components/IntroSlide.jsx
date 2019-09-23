import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import SlideContent from './SlideContent';
import { getContentOfToken } from '../utilities';

class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.onSubmit = this.onSubmit.bind(this);
  }

  selectVariant(variantId) {
    const defaultVariant = (
      <div>
        <p>DEV is where programmers share ideas and help each other grow. 🤓</p>
        <p>
          Ask questions, leave helpful comments, encourage others, and have fun!
          🙌
        </p>
        <p>
          A few <strong>quick questions</strong> for you before you get
          started...
        </p>
      </div>
    );
    const variants = [
      <SlideContent
        imageSource={`https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif`}
        imageAlt={`hello cat`}
      />,
      <SlideContent
        imageSource={`https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif`}
        imageAlt={`hello cat`}
        content={<p>We have a few quick questions to fill out your profile</p>}
      />,
      <SlideContent
        imageSource={`https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif`}
        imageAlt={`hello`}
        content={
          <p>
            The more you get involved in community, the better developer you
            will be.
          </p>
        }
        style={{ textAlign: 'center', fontSize: '0.9em' }}
      />,
      <SlideContent
        imageSource={`https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif`}
        imageAlt={`hello`}
        content={<p>You just made a great choice for your dev career.</p>}
        style={{ textAlign: 'center', fontSize: '1.1em' }}
      />,
    ];
    return variants[variantId - 1] || defaultVariant;
  }

  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { last_onboarding_page: 'intro slide' } }),
      credentials: 'same-origin',
    });
  }

  onSubmit() {
    const { next } = this.props;
    next();
  }

  render() {
    const { prev, variant } = this.props;
    const onboardingBody = this.selectVariant(variant);

    return (
      <div className="onboarding-main">
        <div className="onboarding-content">
          <h1>
            <span>Welcome to the </span>
            <img
              src="/assets/purple-dev-logo.png"
              className="sticker-logo"
              alt="DEV"
            />
            <span>community!</span>
          </h1>
          {onboardingBody}
        </div>
        <Navigation prev={prev} next={this.onSubmit} hidePrev />
      </div>
    );
  }
}

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  variant: PropTypes.string.isRequired,
};

export default IntroSlide;
