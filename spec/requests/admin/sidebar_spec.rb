require "rails_helper"

RSpec.describe "admin sidebar", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
  end

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

  describe "data update script admin feature flag" do
    it "shows the option in the sidebar when the feature flag is enabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(true)

      get admin_articles_path

      expect(response.body).to include("Tech Resources")
      expect(response.body).to include("Data Update Scripts")
    end

    it "does not show the option in the sidebar when the feature flag is disabled" do
      allow(FeatureFlag).to receive(:enabled?).with(:data_update_scripts).and_return(false)

      get admin_articles_path

      expect(response.body).not_to include("Data Update Scripts")
    end
  end
end
