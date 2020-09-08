require "rails_helper"

RSpec.describe "ProfileFieldGroups", type: :request do
  let(:user) { create(:user) }

  describe "GET /profile_field_groups" do
    let!(:group1) { create(:profile_field_group) }
    let!(:group2) { create(:profile_field_group) }
    let!(:field1) { create(:profile_field, :onboarding, label: "Field 1", profile_field_group: group1) }

    before do
      sign_in user

      create(:profile_field, label: "Field 2", profile_field_group: group1)
      create(:profile_field, label: "Field 3", profile_field_group: group2)
    end

    it "returns a successful response" do
      get profile_field_groups_path
      expect(response.status).to eq 200
    end

    it "returns all groups with all fields by default" do
      get profile_field_groups_path
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:profile_field_groups].size).to eq 2
    end

    it "returns only groups with onboarding fields when onboarding=true" do
      get profile_field_groups_path, params: { onboarding: true }
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:profile_field_groups].size).to eq 1
    end

    it "only returns the onboarding fields in the group", :aggregate_failures do
      get profile_field_groups_path, params: { onboarding: true }
      json_response = JSON.parse(response.body, symbolize_names: true)
      group = json_response[:profile_field_groups].first
      expect(group[:profile_fields].size).to eq 1
      expect(group[:profile_fields].first[:id]).to eq field1.id
    end
  end
end
