import { h } from 'preact';
import { deep, shallow } from 'preact-render-spy';
import { SingleListing } from '../singleListing';

const listing = {
  id: 22,
  category: 'misc',
  contact_via_connect: true,
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-perspiciatis-5hk7',
  title: 'Illo iure quos perspiciatis.',
  user_id: 7,
  tag_list: ['go', 'git'],
  author: {
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

describe('<SingeListing />', () => {
  it('should load a single user listing', () => {
    const tree = deep(
      <SingleListing
        onAddTag={() => {
          return 'onAddTag';
        }}
        onChangeCategory={() => {
          return 'onChangeCategory';
        }}
        listing={listing}
        currentUserId={1}
        onOpenModal={() => {
          return 'onOpenModal';
        }}
        isOpen={false}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  describe('should load the following elements', () => {
    const context = shallow(
      <SingleListing
        onAddTag={() => {
          return 'onAddTag';
        }}
        onChangeCategory={() => {
          return 'onChangeCategory';
        }}
        listing={listing}
        currentUserId={1}
        onOpenModal={() => {
          return 'onOpenModal';
        }}
        isOpen={false}
      />
    );
    expect(context.find('.single-classified-listing').exists()).toBeTruthy();

    it('for listing title', () => {
      expect(
        context.find('.listing-content')
          .at(0)
          .childAt(0)
          .text()
      ).toEqual('Illo iure quos perspiciatis.');
    });

    it('for listing tags', () => {
      expect(
        context.find('.single-classified-listing-tags')
          .childAt(0)
          .text()
      ).toEqual(listing.tag_list[0]);
    });

    it('for listing category', () => {
      expect(
        context.find('.single-classified-listing-author-info')
          .childAt(0)
          .text()
      ).toEqual(listing.category);
    });

    it('for listing location', () => {
      expect(
        context.find('.single-classified-listing-author-info')
          .childAt(1)
          .text()
      ).toEqual(`・${listing.location}`);
    });

    it('for listing author', () => {
      expect(
        context.find('.single-classified-listing-author-info')
          .childAt(3)
          .text()
      ).toEqual(listing.author.name);
    });

    it('for report abuse button', () => {
      expect(
        context.find('.single-classified-listing-author-info')
          .childAt(4)
          .text()
      ).toEqual('・report abuse');
    });
  });
});
