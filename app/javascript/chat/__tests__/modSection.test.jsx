import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ModSection from '../ChatChannelSettings/ModSection';

describe('<ModSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ModSection currentMembershipRole="mod" />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render if the membership role is a moderator', () => {
    const { getByTestId } = render(<ModSection currentMembershipRole="mod" />);

    // the <InviteForm /> and <SettingsForm /> have their own tests.
    getByTestId('invite-form');
    getByTestId('settings-form');
  });
});
