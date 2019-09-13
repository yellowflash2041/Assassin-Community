require "rails_helper"

RSpec.describe FollowPolicy, type: :policy do
  subject { described_class.new(user, Follow) }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in" do
    let(:user) { build_stubbed(:user) }

    it { is_expected.to permit_actions(%i[create]) }

    context "when user is banned" do
      before { user.add_role(:banned) }

      it { is_expected.to forbid_actions(%i[create]) }
    end
  end
end
