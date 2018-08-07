require "rails_helper"

RSpec.describe ReactionPolicy do
  subject { described_class.new(user, reaction) }

  let(:reaction) { build(:reaction) }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in" do
    let(:user) { build(:user) }

    it { is_expected.to permit_actions(%i[index create]) }
    context "when user is banned" do
      let(:user) { build(:user, :banned) }

      it { is_expected.to permit_actions(%i[index]) }
      it { is_expected.to forbid_actions(%i[create]) }
    end
  end
end
