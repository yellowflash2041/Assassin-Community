require "rails_helper"

RSpec.describe "/listings", type: :request do
  let_it_be_readonly(:edu_category) do
    create(:listing_category, cost: 1)
  end
  let(:user) { create(:user) }
  let(:listing_params) do
    {
      listing: {
        title: "something",
        body_markdown: "something else",
        listing_category_id: edu_category.id,
        tag_list: "",
        contact_via_connect: true
      }
    }
  end
  let(:draft_params) do
    {
      listing: {
        title: "this a draft",
        body_markdown: "something draft",
        listing_category_id: edu_category.id,
        tag_list: "",
        contact_via_connect: true,
        action: "draft"
      }
    }
  end

  describe "GET /listings" do
    let(:listing) { create(:listing, user: user) }
    let(:expired_listing) { create(:listing, user: user) }

    before do
      sign_in user
      create_list(:credit, 25, user: user)
    end

    it "returns text/html and has status 200" do
      get "/listings"
      expect(response.content_type).to eq("text/html")
      expect(response).to have_http_status(:ok)
    end

    context "when the user has no params" do
      it "shows all active listings" do
        get "/listings"
        expect(response.body).to include("listings-container")
      end
    end

    context "when the user has category and slug params for active listing" do
      it "shows that direct listing" do
        get "/listings", params: { category: listing.category, slug: listing.slug }
        expect(response.body).to include(CGI.escapeHTML(listing.title))
      end
    end

    context "when the user has category and slug params for expired listing" do
      it "shows only active listings from that category" do
        expired_listing.published = false
        expired_listing.save
        get "/listings", params: { category: expired_listing.category, slug: expired_listing.slug }
        expect(response.body).not_to include(CGI.escapeHTML(expired_listing.title))
      end
    end

    context "when view is moderate" do
      it "redirects to internal/listings/:id/edit" do
        get "/listings", params: { view: "moderate", slug: listing.slug }
        expect(response.redirect_url).to include("/internal/listings/#{listing.id}/edit")
      end

      it "without a slug raises an ActiveRecord::RecordNotFound error" do
        expect do
          get "/listings", params: { view: "moderate" }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /listings/new" do
    before { sign_in user }

    it "shows the option to create draft" do
      get "/listings/new"
      expect(response.body).to include "You will not be charged credits to save a draft."
    end

    context "when the user has no credits" do
      it "shows the proper messages" do
        get "/listings/new"
        expect(response.body).to include "Listings Require Credits"
        expect(response.body).to include "You need at least one credit to create a listing."
      end
    end

    context "when the user has credits" do
      it "shows the number of credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "You have #{random_number} credits available"
      end
    end

    context "when the user has no credits and belongs to an organization" do
      let(:organization) { create(:organization) }

      before { create(:organization_membership, user_id: user.id, organization_id: organization.id) }

      it "shows the proper message when both user and org have no credits" do
        get "/listings/new"
        expect(response.body).to include "Listings Require Credits"
      end

      it "shows the number of credits of the user if the user has credits but the org has no credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "You have #{random_number} credits available"
      end

      it "shows the number of credits of the organization if the org has credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        get "/listings/new"
        expect(response.body).to include "has <span id=\"org-credits-number\">#{random_number}</span> credits"
      end

      it "shows the number of credits of both the user and the organization if they both have credits" do
        random_number = rand(2..100)
        create_list(:credit, random_number, organization: organization)
        create_list(:credit, random_number, user: user)
        get "/listings/new"
        expect(response.body).to include "has <span id=\"org-credits-number\">#{random_number}</span> credits"
        expect(response.body).to include "You have #{random_number} credits available"
      end
    end
  end

  describe "POST /listings" do
    before do
      sign_in user
      create_list(:credit, 25, user: user)
    end

    let_it_be_readonly(:cfp_category) { create(:listing_category, :cfp) }

    context "when the listing is invalid" do
      let(:invalid_params) do
        {
          listing: {
            title: "nothing",
            body_markdown: "",
            listing_category_id: cfp_category.id,
            tag_list: ""
          }
        }
      end

      it "renders errors with the listing" do
        post "/listings", params: invalid_params
        expect(response.body).to include("prohibited this listing from being saved")
      end

      it "does not subtract credits or create a listing if the listing is not valid" do
        expect do
          post "/listings", params: invalid_params
        end.to change(Listing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end
    end

    context "when the listing is valid" do
      it "redirects if the user does not have enough credits" do
        Credit.delete_all
        post "/listings", params: listing_params
        expect(response.body).to redirect_to("/credits")
      end

      it "redirects if the org does not have enough credits" do
        org_admin = create(:user, :org_admin)
        listing_params[:listing][:post_as_organization] = "1"
        sign_in org_admin
        post "/listings", params: listing_params
        expect(response.body).to redirect_to("/credits")
      end

      it "redirects to /listings/dashboard for listing draft" do
        post "/listings", params: draft_params
        expect(response).to redirect_to "/listings/dashboard"
      end

      it "redirects to /listings" do
        post "/listings", params: listing_params
        expect(response).to redirect_to "/listings"
      end

      it "properly deducts the amount of credits" do
        expect do
          post "/listings", params: listing_params
        end.to change { user.credits.spent.size }.by(edu_category.cost)
      end

      it "creates a listing draft under the org" do
        org_admin = create(:user, :org_admin)
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        draft_params[:listing][:organization_id] = org_id
        sign_in org_admin
        post "/listings", params: draft_params
        expect(Listing.first.organization_id).to eq org_id
      end

      it "creates a listing under the org" do
        org_admin = create(:user, :org_admin)
        org_id = org_admin.organizations.first.id
        Credit.create(organization_id: org_id)
        listing_params[:listing][:organization_id] = org_id
        sign_in org_admin
        post "/listings", params: listing_params
        expect(Listing.first.organization_id).to eq org_id
      end

      it "does not create a listing draft for an org not belonging to the user" do
        org = create(:organization)
        draft_params[:listing][:organization_id] = org.id
        expect { post "/listings", params: draft_params }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not create a listing for an org not belonging to the user" do
        org = create(:organization)
        listing_params[:listing][:organization_id] = org.id
        expect { post "/listings", params: listing_params }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "assigns the spent credits to the listing" do
        post "/listings", params: listing_params
        spent_credit = user.credits.spent.last
        expect(spent_credit.purchase_type).to eq("Listing")
        expect(spent_credit.spent_at).not_to be_nil
      end

      it "creates listing draft and does not subtract credits" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post "/listings", params: draft_params
        end.to change(Listing, :count).by(1).
          and change(user.credits.spent, :size).by(0)
      end

      it "does not create a listing or subtract credits if the purchase does not go through" do
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          post "/listings", params: listing_params
        end.to change(Listing, :count).by(0).
          and change(user.credits.spent, :size).by(0)
      end
    end

    context "when user is banned" do
      it "raises error" do
        user.add_role_synchronously(:banned)
        expect do
          post "/listings", params: listing_params
        end.to raise_error("SUSPENDED")
      end
    end
  end

  describe "PUT /listings/:id" do
    let(:listing) { create(:listing, user: user) }
    let(:listing_draft) { create(:listing, user: user) }
    let(:organization) { create(:organization) }
    let(:org_listing) { create(:listing, user: user, organization: organization) }
    let(:org_listing_draft) { create(:listing, user: user, organization: organization) }

    before do
      sign_in user
      listing_draft.update_columns(bumped_at: nil, published: false)
      org_listing_draft.update_columns(bumped_at: nil, published: false)
    end

    context "when the bump action is called" do
      let(:params) { { listing: { action: "bump" } } }

      it "does not bump the user listing and redirects to credits if the user has not enough credits" do
        previous_bumped_at = listing.bumped_at
        put "/listings/#{listing.id}", params: params
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
        expect(response.body).to redirect_to("/credits")
      end

      it "does not subtract spent credits if the user has not enough credits" do
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
      end

      it "does not bump the listing or subtract credits if the purchase does not go through" do
        previous_bumped_at = listing.bumped_at
        allow(Credits::Buyer).to receive(:call).and_raise(ActiveRecord::Rollback)
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
        expect(listing.reload.bumped_at.to_i).to eq(previous_bumped_at.to_i)
      end

      it "bumps the listing and subtract credits" do
        cost = listing.cost
        create_list(:credit, cost, user: user)
        previous_bumped_at = listing.bumped_at
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(cost)
        expect(listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using org credits before user credits" do
        cost = org_listing.cost
        create_list(:credit, cost, organization: organization)
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put "/listings/#{org_listing.id}", params: params
        end.to change(organization.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end

      it "bumps the org listing using user credits if org credits insufficient and user credits are" do
        cost = org_listing.cost
        create_list(:credit, cost, user: user)
        previous_bumped_at = org_listing.bumped_at
        expect do
          put "/listings/#{org_listing.id}", params: params
        end.to change(user.credits.spent, :size).by(cost)
        expect(org_listing.reload.bumped_at >= previous_bumped_at).to eq(true)
      end
    end

    context "when the publish action is called" do
      let(:params) { { listing: { action: "publish" } } }

      it "publishes a draft and charges user credits if first publish" do
        cost = listing_draft.cost
        create_list(:credit, cost, user: user)
        expect do
          put "/listings/#{listing_draft.id}", params: params
        end.to change(user.credits.spent, :size).by(cost)
      end

      it "publishes a draft and ensures published column is true" do
        cost = listing_draft.cost
        create_list(:credit, cost, user: user)
        put "/listings/#{listing_draft.id}", params: params
        expect(listing_draft.reload.published).to eq(true)
      end

      it "publishes an org draft and charges org credits if first publish" do
        cost = org_listing_draft.cost
        create_list(:credit, cost, organization: organization)
        expect do
          put "/listings/#{org_listing_draft.id}", params: params
        end.to change(organization.credits.spent, :size).by(cost)
      end

      it "publishes an org draft and ensures published column is true" do
        cost = org_listing_draft.cost
        create_list(:credit, cost, organization: organization)
        put "/listings/#{org_listing_draft.id}", params: params
        expect(org_listing_draft.reload.published).to eq(true)
      end

      it "publishes a draft that was charged and is within 30 days of bump doesn't charge credits" do
        listing.update_column(:published, false)
        expect do
          put "/listings/#{listing.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
      end

      it "publishes a draft that was charged and is within 30 days of bump and successfully sets published as true" do
        listing.update_column(:published, false)
        put "/listings/#{listing.id}", params: params
        expect(listing.reload.published).to eq(true)
      end

      it "fails to publish draft and doesn't charge credits" do
        expect do
          put "/listings/#{listing_draft.id}", params: params
        end.to change(user.credits.spent, :size).by(0)
      end

      it "fails to publish draft and published remains false" do
        put "/listings/#{listing_draft.id}", params: params
        expect(listing_draft.reload.published).to eq(false)
      end
    end

    context "when the unpublish action is called" do
      let(:params) { { listing: { action: "unpublish" } } }

      it "unpublishes a published listing" do
        put "/listings/#{listing.id}", params: params
        expect(listing.reload.published).to eq(false)
      end
    end

    context "when an update is attempted" do
      it "does not update with an empty body markdown" do
        put "/listings/#{listing.id}", params: { listing: { body_markdown: "" } }
        expect(response.body).to include(CGI.escapeHTML("can't be blank"))
        expect(listing.reload.body_markdown).not_to be_empty
      end
    end
  end

  describe "DEL /listings/:id" do
    let!(:listing) { create(:listing, user: user) }
    let!(:listing_draft) { create(:listing, user: user, bumped_at: nil, published: false) }
    let(:organization) { create(:organization) }
    let!(:org_listing) { create(:listing, user: user, organization: organization) }
    let!(:org_listing_draft) do
      create(:listing, user: user, organization: organization, bumped_at: nil, published: false)
    end

    before do
      sign_in user
    end

    context "when deleting draft" do
      it "redirect to dashboard" do
        delete "/listings/#{listing_draft.id}"
        expect(response).to redirect_to("/listings/dashboard")
      end

      it "have status 302 found" do
        delete "/listings/#{listing_draft.id}"
        expect(response).to have_http_status(:found)
      end

      it "decrease total listings count by 1" do
        expect do
          delete "/listings/#{listing_draft.id}"
        end.to change(Listing, :count).by(-1)
      end
    end

    context "when deleting listing" do
      it "redirect to dashboard" do
        delete "/listings/#{listing.id}"
        expect(response).to redirect_to("/listings/dashboard")
      end

      it "have status 302 found" do
        delete "/listings/#{listing.id}"
        expect(response).to have_http_status(:found)
      end

      it "decrease total listings count by 1" do
        expect do
          delete "/listings/#{listing.id}"
        end.to change(Listing, :count).by(-1)
      end
    end

    context "when deleting draft org listing" do
      it "redirect to dashboard" do
        delete "/listings/#{org_listing_draft.id}"
        expect(response).to redirect_to("/listings/dashboard")
      end

      it "have status 302 found" do
        delete "/listings/#{org_listing_draft.id}"
        expect(response).to have_http_status(:found)
      end

      it "decrease total listings count by 1" do
        expect do
          delete "/listings/#{org_listing_draft.id}"
        end.to change(Listing, :count).by(-1)
      end
    end

    context "when deleting org listing" do
      it "redirect to dashboard" do
        delete "/listings/#{org_listing.id}"
        expect(response).to redirect_to("/listings/dashboard")
      end

      it "have status 302 found" do
        delete "/listings/#{org_listing.id}"
        expect(response).to have_http_status(:found)
      end

      it "decrease total listings count by 1" do
        expect do
          delete "/listings/#{org_listing.id}"
        end.to change(Listing, :count).by(-1)
      end
    end
  end

  describe "GET /delete_confirm" do
    let!(:listing) { create(:listing, user: user) }

    before { sign_in user }

    context "without listing" do
      it "renders not_found" do
        expect do
          get "/listings/#{listing.category}/#{listing.slug}_1/delete_confirm"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

# TODO: [thepracticaldev/oss] We used to have 2 request spec files, listing_spec.rb
# and classified_listing_spec.rb. This context contains the specs of the former,
# but we should eventually unify them into one set to remove some redundancy.
context "when running the specs that were previously in another file" do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:cl_category) { create(:listing_category, cost: 1) }

  let(:params) do
    {
      listing: {
        title: "Hey",
        listing_category_id: cl_category.id,
        body_markdown: "hey hey my my",
        tag_list: "ruby, rails, go"
      }
    }
  end

  describe "GET /listings" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("listing-filters")
    end

    it "has page content for category page" do
      get "/listings/saas"
      expect(response.body).to include("listing-filters")
    end
  end

  describe "GETS /listings/new" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("listing-filters")
    end
  end

  describe "POST /listings" do
    before do
      create_list(:credit, 20, user_id: user.id)
      sign_in user
    end

    it "creates proper listing if credits are available" do
      post "/listings", params: params
      expect(Listing.last.processed_html).to include("hey my")
    end

    it "spends credits" do
      num_credits = Credit.where(spent: true).size
      post "/listings", params: params
      expect(Credit.where(spent: true).size).to be > num_credits
    end

    it "adds tags" do
      post "/listings", params: params
      expect(Listing.last.cached_tag_list).to include("rails")
    end

    it "creates the listing under the user" do
      post "/listings", params: params
      expect(Listing.last.user_id).to eq user.id
    end

    it "creates the listing for the user if no organization_id is selected" do
      create(:organization_membership, user_id: user.id, organization_id: organization.id)
      post "/listings", params: params
      expect(Listing.last.organization_id).to eq nil
      expect(Listing.last.user_id).to eq user.id
    end

    it "creates the listing for the organization" do
      create(:organization_membership, user_id: user.id, organization_id: organization.id)
      params[:listing][:organization_id] = organization.id
      post "/listings", params: params
      expect(Listing.last.organization_id).to eq(organization.id)
    end

    it "does not create an org listing if a different org member doesn't belong to the org" do
      another_org = create(:organization)
      create(:organization_membership, user_id: user.id, organization_id: another_org.id)
      params[:listing][:organization_id] = organization.id
      expect do
        post "/listings", params: params
      end.to raise_error Pundit::NotAuthorizedError
    end

    context "when rate limiting" do
      let(:rate_limiter) { RateLimitChecker.new(user) }

      before do
        allow(RateLimitChecker).to receive(:new).and_return(rate_limiter)
        sign_in user
      end

      it "increments rate limit for listing_creation" do
        allow(rate_limiter).to receive(:track_limit_by_action)
        post "/listings", params: params

        expect(rate_limiter).to have_received(:track_limit_by_action).with(:listing_creation)
      end

      it "returns a 429 status when rate limit is reached" do
        allow(rate_limiter).to receive(:limit_by_action).and_return(true)
        post "/listings", params: params

        expect(response.status).to eq(429)
      end
    end
  end

  describe "GET /listings/edit" do
    let(:listing) { create(:listing, user_id: user.id) }

    before do
      create_list(:credit, 20, user_id: user.id)
      sign_in user
    end

    it "has page content" do
      get "/listings/#{listing.id}/edit"
      expect(response.body).to include("You can bump your listing")
    end
  end

  describe "PUT /listings/:id" do
    let(:listing) { create(:listing, user_id: user.id) }

    before do
      create_list(:credit, 20, user_id: user.id)
      sign_in user
    end

    it "updates bumped_at if action is bump" do
      put "/listings/#{listing.id}", params: {
        listing: { action: "bump" }
      }
      expect(Listing.last.bumped_at).to be > 10.seconds.ago
    end

    it "updates publish if action is unpublish" do
      put "/listings/#{listing.id}", params: {
        listing: { action: "unpublish" }
      }
      expect(Listing.last.published).to eq(false)
    end

    it "updates body_markdown" do
      put "/listings/#{listing.id}", params: {
        listing: { body_markdown: "hello new markdown" }
      }
      expect(Listing.last.body_markdown).to eq("hello new markdown")
    end

    it "does not update body_markdown if not bumped/created recently" do
      listing.update_column(:bumped_at, 50.hours.ago)
      put "/listings/#{listing.id}", params: {
        listing: { body_markdown: "hello new markdown" }
      }
      expect(Listing.last.body_markdown).not_to eq("hello new markdown")
    end

    it "updates other fields" do
      put "/listings/#{listing.id}", params: {
        listing: { body_markdown: "hello new markdown", title: "New title!", tag_list: "new, tags, hey" }
      }
      expect(Listing.last.title).to eq("New title!")
      expect(Listing.last.cached_tag_list).to include("hey")
    end

    it "does not update other fields" do
      listing.update_column(:bumped_at, 50.hours.ago)
      put "/listings/#{listing.id}", params: {
        listing: { body_markdown: "hello new markdown", title: "New title!", tag_list: "new, tags, hey" }
      }
      expect(Listing.last.title).not_to eq("New title!")
      expect(Listing.last.cached_tag_list).not_to include("hey")
    end
  end
end
