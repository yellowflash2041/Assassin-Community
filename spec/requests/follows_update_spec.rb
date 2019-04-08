require "rails_helper"

RSpec.describe "Following/Unfollowing", type: :request do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }
  let(:tag) { create(:tag) }

  before do
    login_as user
  end

  describe "PUT follows/:id" do
    it "updates user to offer mentorship" do
      user.follow(tag)
      put "/follows/#{Follow.last.id}",
          params: { follow: { points: 3.0 } }
      expect(Follow.last.points).to eq(3.0)
    end

    it "does not update if follow does not belong to user" do
      user_2.follow(tag)
      expect do
        put "/follows/#{Follow.last.id}",
            params: { follow: { points: 3.0 } }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
