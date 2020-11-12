require "rails_helper"

RSpec.describe "admin sidebar", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before { sign_in super_admin }

  describe "profile admin feature flag" do
    it "shows the option in the sidebar when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(true)

      get admin_articles_path

      expect(response.body).to include("Config: Profile Setup")
    end

    it "does not show the option in the sidebar when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:profile_admin).and_return(false)

      get admin_articles_path

      expect(response.body).not_to include("Config: Profile Setup")
    end
  end
end
