import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import AllListings from '../components/AllListings';

const firstListing = {
  id: 20,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-htyashsayas-5hk7',
  title: 'Mentor wanted',
  tags: ['go', 'git'],
  user_id: 1,
  author: {
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const secondListing = {
  id: 21,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-ereerr-5hk7',
  title: 'This is an awesome listing',
  tags: ['functional', 'clojure'],
  user_id: 1,
  author: {
    name: 'Mr. Rogers',
    username: 'fred',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const thirdListing = {
  id: 22,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eBobby says hello. Eius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-fss-ssasas-5hk7',
  title: 'Illo iure quos perspiciatis',
  tags: ['twitter', 'learning'],
  user_id: 1,
  author: {
    name: 'Mrs. John Mack',
    username: 'mrsjohnmack',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const listings = [firstListing, secondListing, thirdListing];

const getProps = () => ({
  listings,
  onAddTag: () => {
    return 'onAddTag';
  },
  onChangeCategory: () => {
    return 'onChangeCategory';
  },
  currentUserId: 1,
  message: 'Something',
  onOpenModal: () => {
    return 'onSubmit;';
  },
});

const renderAllListings = () => render(<AllListings {...getProps()} />);

describe('<AllListings />', () => {
  it('should have no a11y violations', async () => {
    const { container } = renderAllListings();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the given listings', async () => {
    const { getByTestId, getByText } = renderAllListings();

    // Ensure each listing is present
    const titleOptions = {
      selector: 'h3 > a',
    };

    // 1st listings
    getByTestId('single-listing-20');

    // listing title
    const listing1Title = getByText('Mentor wanted', titleOptions);

    expect(listing1Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-quos-htyashsayas-5hk7',
    );

    // listing body
    getByText(/Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-20"] *',
    });

    // listing tags
    const goTag = getByText('go', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(goTag.getAttribute('href')).toEqual('/listings?t=go');

    const gitTag = getByText('git', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(gitTag.getAttribute('href')).toEqual('/listings?t=git');

    // listing author
    const listing1Author = getByText('Mrs. Yoko Christiansen', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(listing1Author.getAttribute('href')).toEqual('/mrschristiansenyoko');

    // 2nd listing
    getByTestId('single-listing-21');

    // listing title
    const listing2Title = getByText('This is an awesome listing', titleOptions);

    expect(listing2Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-quos-ereerr-5hk7',
    );

    // listing body
    getByText(/Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-21"] *',
    });

    // listing tags
    const functionalTag = getByText('functional', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(functionalTag.getAttribute('href')).toEqual(
      '/listings?t=functional',
    );

    const clojureTag = getByText('clojure', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(clojureTag.getAttribute('href')).toEqual('/listings?t=clojure');

    // listing author
    const listing2Author = getByText('Mr. Rogers', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(listing2Author.getAttribute('href')).toEqual('/fred');

    // 3rd listing
    getByTestId('single-listing-22');

    // listing title
    const listing3Title = getByText(
      'Illo iure quos perspiciatis',
      titleOptions,
    );

    expect(listing3Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-fss-ssasas-5hk7',
    );

    // listing body
    getByText(/Bobby says hello. Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-22"] *',
    });

    // listing tags
    const twitterTag = getByText('twitter', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(twitterTag.getAttribute('href')).toEqual('/listings?t=twitter');

    const learningTag = getByText('learning', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(learningTag.getAttribute('href')).toEqual('/listings?t=learning');

    const listing3Author = getByText('Mrs. John Mack', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(listing3Author.getAttribute('href')).toEqual('/mrsjohnmack');
  });
});
