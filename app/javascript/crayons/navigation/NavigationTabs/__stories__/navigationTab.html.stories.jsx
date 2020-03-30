import { h } from 'preact';

import '../../../storybook-utiltiies/designSystem.scss';

export default { title: 'Components/Navigation/Tabs/HTML' };

export const Default = () => (
  <div className="crayons-tabs">
    <a href="/" className="crayons-tabs__item crayons-tabs__item--current">
      Feed
    </a>
    <a href="/" className="crayons-tabs__item">
      Popular
    </a>
    <a href="/" className="crayons-tabs__item">
      Latest
    </a>
  </div>
);

Default.story = {
  name: 'default',
};
