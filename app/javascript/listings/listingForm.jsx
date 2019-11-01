import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import Title from './elements/title';
import BodyMarkdown from './elements/bodyMarkdown';
import Categories from './elements/categories';
import ContactViaConnect from './elements/contactViaConnect';
import ExpireDate from './elements/expireDate';
import Tags from '../shared/components/tags';
import { OrganizationPicker } from '../organization/OrganizationPicker';

export default class ListingForm extends Component {
  constructor(props) {
    super(props);
    const {
      listing,
      categoriesForDetails,
      categoriesForSelect,
      organizations: unparsedOrganizations,
    } = this.props;
    this.listing = JSON.parse(listing);
    this.categoriesForDetails = JSON.parse(categoriesForDetails);
    this.categoriesForSelect = JSON.parse(categoriesForSelect);

    const organizations = JSON.parse(unparsedOrganizations);

    this.url = window.location.href;

    this.state = {
      id: this.listing.id || null,
      title: this.listing.title || '',
      category: this.listing.category || '',
      tagList: this.listing.cached_tag_list || '',
      bodyMarkdown: this.listing.body_markdown || '',
      categoriesForSelect: this.categoriesForSelect,
      categoriesForDetails: this.categoriesForDetails,
      organizations,
      organizationId: null, // change this for /edit later
      contactViaConnect: this.listing.contact_via_connect || 'checked',
      expireDate: this.listing.expires_at || '',
    };
  }

  handleOrgIdChange = e => {
    const organizationId = e.target.selectedOptions[0].value;
    this.setState({ organizationId });
  };

  render() {
    const {
      id,
      title,
      bodyMarkdown,
      tagList,
      category,
      categoriesForDetails,
      categoriesForSelect,
      organizations,
      organizationId,
      contactViaConnect,
      expireDate,
    } = this.state;

    const selectOrg =
      organizations && organizations.length > 0 ? (
        <div className="field">
          <label htmlFor="organizationId">Post under an organization:</label>
          <OrganizationPicker
            name="classified_listing[organization_id]"
            id="listing_organization_id"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={this.handleOrgIdChange}
          />
          <p>
            <em>Posting on behalf of org spends org credits.</em>
          </p>
        </div>
      ) : null;

    if (id === null) {
      return (
        <div>
          <Title defaultValue={title} onChange={linkState(this, 'title')} />
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <Categories
            categoriesForSelect={categoriesForSelect}
            categoriesForDetails={categoriesForDetails}
            onChange={linkState(this, 'category')}
            category={category}
          />
          <Tags
            defaultValue={tagList}
            category={category}
            onInput={linkState(this, 'tagList')}
            classPrefix="listingform"
            maxTags={8}
            autocomplete="off"
            listing
          />
          <ExpireDate
            defaultValue={expireDate}
            onChange={linkState(this, 'expireDate')}
          />
          {selectOrg}
          <ContactViaConnect
            checked={contactViaConnect}
            onChange={linkState(this, 'contactViaConnect')}
          />
        </div>
      );
    }
    // WIP code for edit
    return (
      <div>
        <Title defaultValue={title} onChange={linkState(this, 'title')} />
        <BodyMarkdown
          defaultValue={bodyMarkdown}
          onChange={linkState(this, 'bodyMarkdown')}
        />
        <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
        {selectOrg}
        <ContactViaConnect
          checked={contactViaConnect}
          onChange={linkState(this, 'contactViaConnect')}
        />
      </div>
    );
  }
}

ListingForm.propTypes = {
  listing: PropTypes.string.isRequired,
  categoriesForDetails: PropTypes.string.isRequired,
  categoriesForSelect: PropTypes.string.isRequired,
  organizations: PropTypes.string.isRequired,
};
