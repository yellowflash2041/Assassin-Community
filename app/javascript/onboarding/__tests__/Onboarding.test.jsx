import { h } from 'preact';
import { deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import { axe, toHaveNoViolations } from 'jest-axe';

import Onboarding from '../Onboarding';
import ProfileForm from '../components/ProfileForm';
import FollowTags from '../components/FollowTags';
import FollowUsers from '../components/FollowUsers';

global.fetch = fetch;
function flushPromises() {
  return new Promise((resolve) => setImmediate(resolve));
}

function initializeSlides(currentSlide, userData = null, mockData = null) {
  document.body.setAttribute('data-user', userData);
  const onboardingSlides = deep(<Onboarding />);

  if (mockData) {
    fetch.once(mockData);
  }

  onboardingSlides.setState({ currentSlide });

  return onboardingSlides;
}

describe('<Onboarding />', () => {
  beforeAll(() => {
    expect.extend(toHaveNoViolations);
  });
  beforeEach(() => {
    fetch.resetMocks();
  });

  const fakeTagsResponse = JSON.stringify([
    {
      bg_color_hex: '#000000',
      id: 715,
      name: 'discuss',
      text_color_hex: '#ffffff',
    },
    {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
    },
    {
      bg_color_hex: '#2a2566',
      id: 630,
      name: 'career',
      text_color_hex: '#ffffff',
    },
  ]);
  const fakeUsersResponse = JSON.stringify([
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'ben.jpg',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
    },
  ]);
  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });

  describe('IntroSlide', () => {
    let onboardingSlides;
    const codeOfConductCheckEvent = {
      target: {
        value: 'checked_code_of_conduct',
        name: 'checked_code_of_conduct',
      },
    };
    const termsAndConditionsCheckEvent = {
      target: {
        value: 'checked_terms_and_conditions',
        name: 'checked_terms_and_conditions',
      },
    };

    const updateCodeOfConduct = () => {
      onboardingSlides
        .find('#checked_code_of_conduct')
        .simulate('change', codeOfConductCheckEvent);
    };
    const updateTermsAndConditions = () => {
      onboardingSlides
        .find('#checked_terms_and_conditions')
        .simulate('change', termsAndConditionsCheckEvent);
    };

    beforeEach(() => {
      onboardingSlides = initializeSlides(0, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should advance if required boxes are checked', async () => {
      fetch.once({});
      expect(onboardingSlides.state().currentSlide).toBe(0);

      updateCodeOfConduct();
      updateTermsAndConditions();

      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });

    test('should not have basic a11y violations', async () => {
      const results = await axe(onboardingSlides.toString());

      expect(results).toHaveNoViolations();
    });
  });

  describe('ProfileForm', () => {
    let onboardingSlides;
    const meta = document.createElement('meta');

    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);

    beforeEach(() => {
      onboardingSlides = initializeSlides(1, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should allow user to fill forms and advance', async () => {
      fetch.once({});
      const profileForm = onboardingSlides.find(<ProfileForm />);
      const summaryEvent = { target: { value: 'my bio', name: 'summary' } };
      const locationEvent = {
        target: { value: 'my location', name: 'location' },
      };
      const titleEvent = {
        target: { value: 'my title', name: 'employment_title' },
      };
      const employerEvent = {
        target: { value: 'my employer name', name: 'employer_name' },
      };

      onboardingSlides.find('textarea').simulate('change', summaryEvent);
      onboardingSlides.find('#location').simulate('change', locationEvent);
      onboardingSlides.find('#employment_title').simulate('change', titleEvent);
      onboardingSlides.find('#employer_name').simulate('change', employerEvent);

      expect(profileForm.state('summary')).toBe(summaryEvent.target.value);
      expect(profileForm.state('location')).toBe(locationEvent.target.value);
      expect(profileForm.state('employment_title')).toBe(
        titleEvent.target.value,
      );
      expect(profileForm.state('employer_name')).toBe(
        employerEvent.target.value,
      );

      profileForm.find('.next-button').simulate('click');
      fetch.once(fakeTagsResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(2);
    });

    it('should step backward', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(0);
    });
  });

  describe('FollowTags', () => {
    let onboardingSlides;

    beforeEach(async () => {
      onboardingSlides = initializeSlides(2, getUserData(), fakeTagsResponse);
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should render three tags', async () => {
      expect(onboardingSlides.find('.onboarding-tags__item').length).toBe(3);
    });

    test('should allow a user to add a tag and advance', async () => {
      fetch.once({});
      const followTags = onboardingSlides.find(<FollowTags />);
      const firstButton = onboardingSlides
        .find('.onboarding-tags__button')
        .first();

      firstButton.simulate('click');
      expect(followTags.state('selectedTags').length).toBe(1);

      onboardingSlides.find('.next-button').simulate('click');
      fetch.once(fakeUsersResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(3);
    });

    it('should step backward', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });
  });

  describe('FollowUsers', () => {
    let onboardingSlides;

    beforeEach(async () => {
      onboardingSlides = initializeSlides(3, getUserData(), fakeUsersResponse);
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should render three users', async () => {
      expect(onboardingSlides.find('.user').length).toBe(3);
    });

    test('should allow a user to select and advance', async () => {
      fetch.once({});
      const followUsers = onboardingSlides.find(<FollowUsers />);

      onboardingSlides.find('.user').first().simulate('click');
      expect(onboardingSlides.find('p').last().text()).toBe(
        "You're following 1 person",
      );
      onboardingSlides.find('.user').last().simulate('click');
      expect(onboardingSlides.find('p').last().text()).toBe(
        "You're following 2 people",
      );
      expect(followUsers.state('selectedUsers').length).toBe(2);
      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(4);
    });

    test('should have a functioning select-all toggle', async () => {
      fetch.once({});
      const followUsers = onboardingSlides.find(<FollowUsers />);

      expect(onboardingSlides.find('button').last().text()).toBe(
        'Select all 3 people',
      );
      onboardingSlides.find('button').last().simulate('click');
      expect(onboardingSlides.find('button').last().text()).toBe(
        'Deselect all',
      );
      expect(followUsers.state('selectedUsers').length).toBe(3);
    });

    it('should step backward', async () => {
      fetch.once(fakeTagsResponse);
      onboardingSlides.find('.back-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(2);
    });
  });

  describe('EmailPreferencesForm', () => {
    let onboardingSlides;

    beforeEach(() => {
      onboardingSlides = initializeSlides(4, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should allow user to advance', async () => {
      fetch.once({});

      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(5);
    });

    it('should step backward', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(3);
    });
  });

  describe('ClosingSlide', () => {
    let onboardingSlides;

    beforeEach(() => {
      onboardingSlides = initializeSlides(5, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });
  });
});
