require "rails_helper"

RSpec.describe "UsersOnboarding", type: :request do
  let(:user) { create(:user, saw_onboarding: false, location: "Llama Town") }

  describe "PATCH /onboarding_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding_update.json", params: {}
        expect(user.saw_onboarding).to eq(true)
      end

      it "updates the user's last_onboarding_page attribute" do
        params = { user: { last_onboarding_page: "v2: personal info form" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.to change(user, :last_onboarding_page)
      end

      it "does not update the user's last_onboarding_page if it is empty" do
        params = { user: { last_onboarding_page: "" } }
        expect do
          patch "/onboarding_update.json", params: params
        end.not_to change(user, :last_onboarding_page)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding_update.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end

  describe "PATCH /onboarding_checkbox_update" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding_checkbox_update.json", params: {}
        expect(user.saw_onboarding).to eq(true)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding_checkbox_update.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end
end
