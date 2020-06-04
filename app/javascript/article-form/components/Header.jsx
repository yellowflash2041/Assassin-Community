import { h } from 'preact';
import PropTypes from 'prop-types';
import { Close } from './Close';
import { Tabs } from './Tabs';
import { PageTitle } from './PageTitle';

export const Header = ({onPreview, previewShowing, organizations, organizationId, onToggle}) => {
  return (
    <div className="crayons-article-form__header">
      <a href="/" className="crayons-article-form__logo" aria-label="Home">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          version="1"
          width="20%"
          height="20%"
          viewBox="0 0 132.000000 65.000000"
          className="logo"
          role="img"
          aria-labelledby="aokj84btta17w7mvt93i94l82beye8ez"
        >
          <title id="aokj84btta17w7mvt93i94l82beye8ez">App logo</title>
          <path d="M0 33v32h11.3c12.5 0 17.7-1.6 21.5-6.5 3.8-4.8 4.4-9 4-28-.3-16.8-.5-18.2-2.7-21.8C30.3 2.5 26.1 1 12 1H0v32zm23.1-19.1c2.3 1.9 2.4 2.3 2.4 18.5 0 15.7-.1 16.7-2.2 18.8-1.7 1.6-3.5 2.2-7 2.2l-4.8.1-.3-20.8L11 12h4.9c3.3 0 5.6.6 7.2 1.9zM46.1 3.6c-2 2.6-2.1 3.9-2.1 29.6v26.9l2.5 2.4c2.3 2.4 2.9 2.5 16 2.5H76V54.1l-10.2-.3-10.3-.3v-15l6.3-.3 6.2-.3V27H55V12h21V1H62.1c-13.9 0-14 0-16 2.6zM87 15.2c2.1 7.9 5.5 20.8 7.6 28.8 3.2 12.3 4.3 15 7 17.7 1.9 2 4.2 3.3 5.7 3.3 3.1 0 7.1-3.1 8.5-6.7 1-2.6 15.2-55.6 15.2-56.8 0-.3-2.8-.5-6.2-.3l-6.3.3-5.6 21.5c-3.5 13.6-5.8 20.8-6.2 19.5C105.9 40 96 1.9 96 1.4c0-.2-2.9-.4-6.4-.4h-6.4L87 15.2z"></path>
        </svg>
      </a>
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />
      <Tabs 
        onPreview={onPreview} 
        previewShowing={previewShowing} 
      />
      <Close />
    </div>
  );
};

Header.propTypes = {
  onPreview: PropTypes.func.isRequired,
  previewShowing: PropTypes.bool.isRequired,
  organizations: PropTypes.string.isRequired,
  organizationId: PropTypes.string.isRequired,
  onToggle: PropTypes.string.isRequired,
};

Header.displayName = 'Header';
