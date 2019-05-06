require "rails_helper"

RSpec.describe "Credits", type: :request do
  describe "GET /credits" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    before do
      sign_in user
    end

    it "shows credits page" do
      get "/credits"
      expect(response.body).to include("You have")
    end

    it "shows credits page if user belongs to an org" do
      user.update_column(:organization_id, organization.id)
      get "/credits"
      expect(response.body).to include("You have")
    end

    it "shows credits page if user belongs to an org and is org admin" do
      user.update_columns(organization_id: organization.id, org_admin: true)
      get "/credits"
      expect(response.body).to include(CGI.escapeHTML(organization.name))
    end
  end

  describe "POST credits" do
    let(:user) { create(:user) }
    let(:stripe_helper) { StripeMock.create_test_helper }

    before do
      StripeMock.start
      sign_in user
    end

    after do
      StripeMock.stop
    end

    it "creates unspent credits" do
      post "/credits", params: {
        credit: {
          number_to_purchase: 20
        },
        stripe_token: stripe_helper.generate_card_token
      }
      expect(user.credits.where(spent: false).size).to eq(20)
    end

    it "makes a valid Stripe charge" do
      post "/credits", params: {
        credit: {
          number_to_purchase: 20
        },
        stripe_token: stripe_helper.generate_card_token
      }
      customer = Stripe::Customer.retrieve(user.stripe_id_code)
      expect(customer.charges.first.amount).to eq 8000
    end

    context "when a user already has a card" do
      before do
        customer = Stripe::Customer.create(email: user.email)
        user.update_column(:stripe_id_code, customer.id)
        customer.sources.create(source: stripe_helper.generate_card_token)
      end

      it "makes a valid Stripe charge" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          selected_card: customer.sources.first.id
        }
        expect(customer.charges.first.amount).to eq 8000
      end

      it "creates unspent credits" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          selected_card: customer.sources.first.id
        }
        expect(user.credits.where(spent: false).size).to eq(20)
      end

      it "charges a new card if given one" do
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        card_id = customer.sources.data.last.id
        expect(customer.charges.first.source.id).to eq card_id
      end
    end

    context "when purchasing as an organization" do
      let(:org_admin) { create(:user, :org_admin) }

      before { sign_in org_admin }

      it "creates unspent credits for the organization" do
        post "/credits", params: {
          user_type: "organization",
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(Credit.where(organization_id: org_admin.organization_id, spent: false).size).to eq 20
      end

      it "makes a valid Stripe charge" do
        post "/credits", params: {
          user_type: "organization",
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        customer = Stripe::Customer.retrieve(org_admin.stripe_id_code)
        expect(customer.charges.first.amount).to eq 8000
      end

      it "does not create unspent credits for the current_user" do
        post "/credits", params: {
          user_type: "organization",
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(org_admin.credits.where(spent: false).size).to eq 0
      end
    end
  end
end
