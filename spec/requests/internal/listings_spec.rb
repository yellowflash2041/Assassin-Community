require "rails_helper"

RSpec.describe "/internal/listings", type: :request do
  let_it_be(:admin) { create(:user, :super_admin) }
  let_it_be(:listing) { create(:listing, user_id: admin.id) }

  before do
    allow(CacheBuster).to receive(:bust_listings)
    sign_in admin
  end

  describe "PUT /internal/listings/:id" do
    it "clears listing cache" do
      put internal_listing_path(id: listing.id), params: {
        listing: { title: "updated" }
      }
      sidekiq_perform_enqueued_jobs
      expect(CacheBuster).to have_received(:bust_listings)
    end

    describe "GET /internal/listings" do
      let!(:unpublished_listing) { create(:listing, published: false) }

      it "shows published listings" do
        get internal_listings_path

        expect(response.body).to include(CGI.escapeHTML(listing.title))
      end

      it "filters unpublished listings by default" do
        get internal_listings_path

        expect(response.body).not_to include(CGI.escapeHTML(unpublished_listing.title))
      end

      it "includes unpublished listings when asked to" do
        get internal_listings_path, params: { include_unpublished: "1" }

        expect(response.body).to include(CGI.escapeHTML(unpublished_listing.title))
      end

      it "filters by category" do
        get internal_listings_path(filter: "misc")

        expect(response.body).not_to include(CGI.escapeHTML(listing.title))
      end
    end
  end
end
