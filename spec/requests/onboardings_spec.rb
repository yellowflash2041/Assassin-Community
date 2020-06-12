require "rails_helper"

RSpec.describe "Onboardings", type: :request do
  let(:user) { create(:user, saw_onboarding: false) }

  describe "GET /onboarding" do
    it "redirects user if unauthenticated" do
      get onboarding_url
      expect(response).to redirect_to("/enter")
    end

    it "return 200 when authentidated" do
      sign_in user
      get onboarding_url
      expect(response).to have_http_status(:ok)
    end

    it "contains proper data attribute keys" do
      sign_in user
      get onboarding_url
      expect(response.body).to include("data-community-description")
      expect(response.body).to include("data-community-logo")
      expect(response.body).to include("data-community-background")
      expect(response.body).to include("data-community-name")
    end

    it "contains proper data attribute values" do
      sign_in user
      get onboarding_url
      expect(response.body).to include(SiteConfig.community_description)
      expect(response.body).to include(SiteConfig.onboarding_logo_image)
      expect(response.body).to include(SiteConfig.onboarding_background_image)
    end
  end
end
