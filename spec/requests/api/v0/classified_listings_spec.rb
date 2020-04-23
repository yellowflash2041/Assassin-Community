require "rails_helper"

RSpec.describe "Api::V0::ClassifiedListings", type: :request do
  let_it_be_readonly(:cfp_category) do
    create(:classified_listing_category, :cfp)
  end
  let_it_be_readonly(:edu_category) do
    create(:classified_listing_category)
  end

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:api_secret_org) { create(:api_secret, :org_admin) }
  end

  shared_context "when param list is valid" do
    let(:listing_params) do
      {
        title: "Title",
        body_markdown: "Markdown text",
        classified_listing_category_id: cfp_category.id
      }
    end
    let(:draft_params) do
      {
        title: "Title draft",
        body_markdown: "Markdown draft text",
        classified_listing_category_id: cfp_category.id,
        action: "draft"
      }
    end
  end

  shared_context "when user has enough credit" do
    before do
      create_list(:credit, 25, user: user)
    end
  end

  shared_context "with 7 listings and 2 user" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create_list(:classified_listing, 3, user: user1, classified_listing_category_id: cfp_category.id)
      create_list(:classified_listing, 4, user: user2, classified_listing_category_id: edu_category.id)
    end
  end

  def user_admin_organization(user)
    org = create(:organization)
    create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "admin")
    org
  end

  describe "GET /api/listings" do
    include_context "with 7 listings and 2 user"

    it "returns json response and ok status" do
      get api_classified_listings_path
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "returns listings created" do
      get api_classified_listings_path
      expect(response.parsed_body.size).to eq(7)
      expect(response.parsed_body.first["type_of"]).to eq("classified_listing")
      expect(response.parsed_body.first["slug"]).to eq(ClassifiedListing.last.slug)
      expect(response.parsed_body.first["user"]).to include("username")
      expect(response.parsed_body.first["user"]["username"]).not_to be_empty
    end

    it "supports pagination" do
      get api_classified_listings_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body.length).to eq(2)
      get api_classified_listings_path, params: { page: 4, per_page: 2 }
      expect(response.parsed_body.length).to eq(1)
    end

    it "sets the correct caching headers" do
      get api_classified_listings_path

      expect(response.headers["cache-control"]).to be_present
      expect(response.headers["surrogate-control"]).to match(/max-age/).and(match(/stale-if-error/))
    end

    it "sets the correct edge caching surrogate key" do
      get api_classified_listings_path

      expected_key = (
        ["classified_listings"] +
        user1.classified_listings.map(&:record_key) +
        user2.classified_listings.map(&:record_key)
      ).to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    it "does not return unpublished listings" do
      listing = user1.classified_listings.last
      listing.update(published: false)

      get api_classified_listings_path
      expect(response.parsed_body.detect { |l| l["published"] == false }).to be_nil
    end
  end

  describe "GET /api/listings/category/:category" do
    include_context "with 7 listings and 2 user"

    it "displays only listings from the cfp category" do
      get api_classified_listings_category_path("cfp")
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it "does not return unpublished listings" do
      category = "cfp"
      listing = user1.classified_listings.where(category: category)
      listing.update(published: false)

      get api_classified_listings_category_path(category)
      expect(response.parsed_body.detect { |l| l["published"] == false }).to be_nil
    end
  end

  describe "GET /api/listings/:id" do
    include_context "with 7 listings and 2 user"
    let(:listing) { ClassifiedListing.where(category: "cfp").last }

    context "when unauthenticated" do
      it "returns a published listing" do
        listing.update(published: true)

        get api_classified_listing_path(listing.id)
        expect(response).to have_http_status(:ok)
      end

      it "returns a published listing on behalf of an organization" do
        org = user_admin_organization(listing.user)
        listing.update(published: true, organization: org)

        get api_classified_listing_path(listing.id)
        expect(response).to have_http_status(:ok)
      end

      it "does not return an unpublished listing" do
        listing.update(published: false)

        get api_classified_listing_path(listing.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      let_it_be_readonly(:headers) { { "api-key" => "invalid api key" } }

      it "returns a published listing" do
        listing.update(published: true)

        get api_classified_listing_path(listing.id), headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "does not return an unpublished listing" do
        listing.update(published: false)

        get api_classified_listing_path(listing.id), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authorized" do
      include_context "when user is authorized"

      let(:headers) { { "api-key" => api_secret.secret } }

      it "returns a published listing" do
        listing.update(published: true)

        get api_classified_listing_path(listing.id), headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "does not return an unpublished listing belonging to another user" do
        listing.update(published: false, user: user1)

        get api_classified_listing_path(listing.id), headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns an unpublished listing belonging to the authenticated user" do
        listing.update(published: false, user: api_secret.user)

        get api_classified_listing_path(listing.id), headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns the correct listing format" do
      get api_classified_listing_path(listing.id)

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body["type_of"]).to eq("classified_listing")
      expect(response.parsed_body["slug"]).to eq(listing.slug)
      expect(response.parsed_body["user"]).to include("username")
      expect(response.parsed_body["user"]["username"]).not_to be_empty
    end

    it "sets the correct caching headers" do
      get api_classified_listing_path(listing.id)

      expect(response.headers["cache-control"]).to be_present
      expect(response.headers["surrogate-control"]).to match(/max-age/).and(match(/stale-if-error/))
    end

    it "sets the correct edge caching surrogate key" do
      get api_classified_listing_path(listing.id)

      expected_key = [listing.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "POST /api/listings" do
    def post_classified_listing(key: api_secret.secret, **params)
      headers = { "api-key" => key, "content-type" => "application/json" }
      post api_classified_listings_path, params: { classified_listing: params }.to_json, headers: headers
    end

    describe "user cannot proceed if not properly unauthorized" do
      let(:api_secret) { create(:api_secret) }

      it "fails with no api key" do
        post api_classified_listings_path, headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        post api_classified_listings_path, headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "user must have enough credit to create a classified listing" do
      include_context "when user is authorized"
      include_context "when param list is valid"

      it "fails to create a classified listing if user does not have enough credit" do
        post_classified_listing(listing_params)
        expect(response).to have_http_status(:payment_required)
      end

      it "fails to create a classifiedlisting if the org does not have enough credit" do
        org = user_admin_organization(user)
        post_classified_listing(
          **listing_params,
          organization_id: org.id,
        )
        expect(response).to have_http_status(:payment_required)
      end
    end

    describe "user cannot create a classified with a request lacking mandatory parameters" do
      let(:invalid_params) do
        {
          title: "Title",
          category: "cfp",
          classified_listing_category_id: cfp_category.id
        }
      end

      include_context "when user is authorized"
      include_context "when user has enough credit"

      it "fails if no params are given" do
        post_classified_listing
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if body_markdown is missing" do
        post_classified_listing(invalid_params)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if category is missing" do
        post_classified_listing(title: "Title", body_markdown: "body")
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if category is invalid" do
        post_classified_listing(title: "Title", body_markdown: "body", category: "unknown")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.dig("errors", "category").first).to match(/not a valid category/)
      end

      it "does not subtract credits or create a listing if the listing is not valid" do
        expect do
          post_classified_listing(invalid_params)
        end.to change(ClassifiedListing, :count).by(0).and change(user.credits.spent, :size).by(0)
      end
    end

    describe "user creates classified listings" do
      include_context "when user is authorized"
      include_context "when param list is valid"
      include_context "when user has enough credit"

      it "properly deducts the amount of credits" do
        post_classified_listing(listing_params)
        expect(response).to have_http_status(:created)

        listing_cost = ClassifiedListing.categories_available[:cfp][:cost]
        expect(user.credits.spent.size).to eq(listing_cost)
      end

      it "creates a listing draft under the org" do
        org_admin = api_secret_org.user
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        post_classified_listing(key: api_secret_org.secret, **draft_params.merge(organization_id: org_id))
        expect(ClassifiedListing.first.organization_id).to eq org_id
      end

      it "creates a listing under the org" do
        org = user_admin_organization(user)
        Credit.create(organization_id: org.id)
        post_classified_listing(listing_params.merge(organization_id: org.id))
        expect(ClassifiedListing.first.organization_id).to eq org.id
      end

      it "does not create a listing draft for an org not belonging to the user" do
        org = create(:organization)
        expect do
          post_classified_listing(draft_params.merge(organization_id: org.id))
          expect(response).to have_http_status(:unauthorized)
        end.to change(ClassifiedListing, :count).by(0)
      end

      it "does not create a listing for an org not belonging to the user" do
        org = create(:organization)
        expect do
          post_classified_listing(listing_params.merge(organization_id: org.id))
          expect(response).to have_http_status(:unauthorized)
        end.to change(ClassifiedListing, :count).by(0)
      end

      it "assigns the spent credits to the listing" do
        post_classified_listing(listing_params)
        spent_credit = user.credits.spent.last
        expect(spent_credit.purchase_type).to eq("ClassifiedListing")
        expect(spent_credit.spent_at).not_to be_nil
      end

      it "cannot create a draft due to internal error" do
        allow(Organization).to receive(:find_by)
        post_classified_listing(draft_params.except(:classified_listing_category_id))
        expect(response.parsed_body["errors"]["category"]).to eq(["not a valid category"])
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "creates listing draft and does not subtract credits" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post_classified_listing(draft_params)
        end.to change(ClassifiedListing, :count).by(1).
          and change(user.credits.spent, :size).by(0)
      end

      it "does not create a listing or subtract credits if the purchase does not go through" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post_classified_listing(listing_params)
        end.to change(ClassifiedListing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end

      it "creates a classified listing belonging to the user" do
        expect do
          post_classified_listing(listing_params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).user).to eq(user)
      end

      it "creates a classified listing with a title, a body markdown, a category" do
        expect do
          post_classified_listing(listing_params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)

        listing = ClassifiedListing.find(response.parsed_body["id"])

        expect(listing.title).to eq(listing_params[:title])
        expect(listing.body_markdown).to eq(listing_params[:body_markdown])
        expect(listing.category).to eq(cfp_category.slug)
      end

      it "creates a classified listing with a location" do
        params = listing_params.merge(location: "Frejus")
        expect do
          post_classified_listing(params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)
        expect(ClassifiedListing.find(response.parsed_body["id"]).location).to eq("Frejus")
      end

      it "creates a classified listing with a list of tags and a contact" do
        params = listing_params.merge(tags: %w[discuss javascript], contact_via_connect: true)
        expect do
          post_classified_listing(params)
          expect(response).to have_http_status(:created)
        end.to change(ClassifiedListing, :count).by(1)

        listing = ClassifiedListing.find(response.parsed_body["id"])

        expect(listing.cached_tag_list).to eq("discuss, javascript")
        expect(listing.contact_via_connect).to be(true)
      end
    end

    describe "with oauth token" do
      include_context "when param list is valid"

      it "fails with oauth token" do
        user = create(:user)
        access_token = create(:doorkeeper_access_token, resource_owner_id: user.id)
        headers = { "authorization" => "Bearer #{access_token.token}", "content-type" => "application/json" }

        post api_classified_listings_path, params: { classified_listing: listing_params }.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/listings/:id" do
    def put_classified_listing(id, **params)
      headers = { "api-key" => api_secret.secret, "content-type" => "application/json" }
      put api_classified_listing_path(id), params: { classified_listing: params }.to_json, headers: headers
    end

    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let!(:listing) { create(:classified_listing, user: user) }
    let(:another_user_listing) { create(:classified_listing, user_id: another_user.id) }
    let(:listing_draft) { create(:classified_listing, user: user) }
    let(:organization) { create(:organization) }
    let(:org_listing) { create(:classified_listing, user: user, organization: organization) }
    let(:org_listing_draft) { create(:classified_listing, user: user, organization: organization) }

    before do
      listing_draft.update_columns(bumped_at: nil, published: false)
      org_listing_draft.update_columns(bumped_at: nil, published: false)
    end

    describe "user cannot proceed if not properly unauthorized" do
      let(:api_secret) { create(:api_secret) }

      it "fails with no api key" do
        put api_classified_listing_path(listing.id), headers: { "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "fails with the wrong api key" do
        put api_classified_listing_path(listing.id), headers: { "api-key" => "foobar", "content-type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized user has no credit" do
      include_context "when user is authorized"

      it "fails to bump a classified listing" do
        previous_bumped_at = listing.bumped_at
        put_classified_listing(listing.id, action: "bump")
        expect(response).to have_http_status(:payment_required)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "does not subtract spent credits if the user has not enough credits" do
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(0)
      end
    end

    context "when the bump action is called" do
      include_context "when user is authorized"
      include_context "when user has enough credit"

      let(:params) { { classified_listing: { action: "bump" } } }

      it "does not bump the listing or subtract credits if the purchase does not go through" do
        previous_bumped_at = listing.bumped_at
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(0)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "bumps the listing and subtract credits" do
        cost = listing.cost
        create_list(:credit, cost, user: user)
        previous_bumped_at = listing.bumped_at
        expect do
          put_classified_listing(listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(cost)
        expect(listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using org credits before user credits" do
        cost = org_listing.cost
        create_list(:credit, cost, organization: organization)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put_classified_listing(org_listing.id, action: "bump")
        end.to change(organization.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using user credits if org credits insufficient and user credits are" do
        cost = org_listing.cost
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put_classified_listing(org_listing.id, action: "bump")
        end.to change(user.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end
    end

    context "when the publish action is called" do
      include_context "when user is authorized"

      it "publishes a draft and charges user credits if first publish" do
        cost = listing_draft.cost
        create_list(:credit, cost, user: user)
        expect do
          put_classified_listing(listing_draft.id, action: "publish")
        end.to change(user.credits.spent, :size).by(cost)
      end

      it "publishes a draft and ensures published column is true" do
        cost = listing_draft.cost
        create_list(:credit, cost, user: user)
        put_classified_listing(listing_draft.id, action: "publish")
        expect(listing_draft.reload.published).to eq(true)
      end

      it "publishes an org draft and charges org credits if first publish" do
        cost = org_listing_draft.cost
        create_list(:credit, cost, organization: organization)
        expect do
          put_classified_listing(org_listing_draft.id, action: "publish")
        end.to change(organization.credits.spent, :size).by(cost)
      end

      it "publishes an org draft and ensures published column is true" do
        cost = org_listing_draft.cost
        create_list(:credit, cost, organization: organization)
        put_classified_listing(org_listing_draft.id, action: "publish")
        expect(org_listing_draft.reload.published).to eq(true)
      end

      it "publishes a draft that was charged and is within 30 days of bump doesn't charge credits" do
        listing.update_column(:published, false)
        expect do
          put_classified_listing(listing.id, action: "publish")
        end.to change(user.credits.spent, :size).by(0)
      end

      it "publishes a draft that was charged and is within 30 days of bump and successfully sets published as true" do
        listing.update_column(:published, false)
        put_classified_listing(listing.id, action: "publish")
        expect(listing.reload.published).to eq(true)
      end
    end

    context "when the publish action is called without credit" do
      include_context "when user is authorized"

      it "fails to publish draft and doesn't charge credits" do
        expect do
          put_classified_listing(listing_draft.id, action: "publish")
        end.to change(user.credits.spent, :size).by(0)
      end

      it "fails to publish draft and published remains false" do
        put_classified_listing(listing_draft.id, action: "publish")
        expect(listing_draft.reload.published).to eq(false)
      end
    end

    context "when user is authorized and has credit to update one of his listing" do
      include_context "when user is authorized"
      include_context "when user has enough credit"

      it "fails if no params have been given" do
        put_classified_listing(listing.id)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "fails if category is invalid" do
        max_id = ClassifiedListingCategory.maximum(:id)
        put_classified_listing(listing.id, title: "New title", classified_listing_category_id: max_id + 1)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.dig("errors", "category").first).to match(/not a valid category/)
      end

      it "updates the title of his listing" do
        put_classified_listing(listing.id, title: "This is a new title")
        expect(response).to have_http_status(:ok)
        expect(listing.reload.title).to eq "This is a new title"
      end

      it "updates the tags" do
        put_classified_listing(listing.id, tags: %w[golang api])
        expect(response).to have_http_status(:ok)
        expect(listing.reload.cached_tag_list).to eq "golang, api"
      end

      it "unpublishes the listing" do
        expect do
          put_classified_listing(listing.id, action: "unpublish")
          listing.reload
        end.to change(listing, :published).from(true).to(false)
        expect(response).to have_http_status(:ok)
      end

      it "cannot update another user listing" do
        put_classified_listing(another_user_listing.id, title: "Test for a new title")
        expect(response).to have_http_status(:unauthorized)
      end

      it "updates details if the listing has been bumped in the last 24 hours" do
        listing.update!(bumped_at: 3.minutes.ago)

        new_title = Faker::Book.title

        put_classified_listing(listing.id, title: new_title)
        expect(listing.reload.title).to eq(new_title)
      end

      it "does not update details if the listing hasn't been bumped in the last 24 hours" do
        listing.update!(bumped_at: 24.hours.ago)

        new_title = Faker::Book.title

        put_classified_listing(listing.id, title: new_title)
        expect(listing.reload.title).to eq(listing.title)
      end

      it "does not update a published listing" do
        listing.update!(bumped_at: nil, published: true)

        old_title = listing.title
        new_title = Faker::Book.title

        put_classified_listing(listing.id, title: new_title)
        expect(listing.reload.title).to eq(old_title)
      end
    end
  end
end
