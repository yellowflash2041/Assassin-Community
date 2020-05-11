require "rails_helper"

RSpec.describe "internal/organizations", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { Organization.first }

  before do
    create_list :organization, 5
    sign_in(admin)
  end

  describe "GETS /internal/organizations" do
    let(:organizations) { Organization.pluck(:name).map { |n| CGI.escapeHTML(n) } }
    let(:another_organization) { create(:organization, name: "T-800") }

    it "lists all organizations" do
      get "/internal/organizations"
      expect(response.body).to include(*organizations)
    end

    it "allows searching" do
      get "/internal/organizations?search=#{organization.name}"
      expect(response.body).to include(CGI.escapeHTML(organization.name))
      expect(response.body).not_to include(CGI.escapeHTML(another_organization.name))
    end
  end

  describe "GET /internal/orgnaizations/:id" do
    it "renders the correct organization" do
      get "/internal/organizations/#{organization.id}"
      expect(response.body).to include(CGI.escapeHTML(organization.name))
    end
  end

  describe "PATCH /internal" do
    let(:organization) { create(:organization) }

    it "adds credits to an organization" do
      params = { credits: 1, credit_action: :add }

      expect do
        patch update_org_credits_internal_organization_path(organization),
              params: params
      end.to change { organization.reload.unspent_credits_count }.by(1)
    end

    it "removes credits to an organization" do
      Credit.add_to_org(organization, 1)
      params = { credits: 1, credit_action: :remove }

      expect do
        patch update_org_credits_internal_organization_path(organization),
              params: params
      end.to change { organization.reload.unspent_credits_count }.by(-1)
    end
  end
end
