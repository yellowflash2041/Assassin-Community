require "rails_helper"

RSpec.describe Internal::UsersQuery, type: :query do
  subject { described_class.call(options: options) }

  let_it_be_readonly(:user)  { create(:user, :trusted, name: "Greg") }
  let_it_be_readonly(:user2) { create(:user, :trusted, name: "Gregory") }
  let_it_be_readonly(:user3) { create(:user, :tag_moderator, name: "Paul") }
  let_it_be_readonly(:user4) { create(:user, :admin, name: "Susi") }
  let_it_be_readonly(:user5) { create(:user, :trusted, :admin, name: "Beth") }
  let_it_be_readonly(:user6) { create(:user, :super_admin, name: "Jean") }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all users" do
        expect(described_class.call).to eq([user6, user5, user4, user3, user2, user])
      end
    end

    context "when search is set" do
      let(:options) { { search: "greg" } }

      it { is_expected.to eq([user2, user]) }
    end

    context "when role is tag_moderator" do
      let(:options) { { role: "tag_moderator" } }

      it { is_expected.to eq([user3]) }
    end

    context "when role is super_admin" do
      let(:options) { { role: "super_admin" } }

      it { is_expected.to eq([user6]) }
    end

    context "when role is trusted" do
      let(:options) { { role: "trusted" } }

      it { is_expected.to eq([user5, user2, user]) }
    end

    context "when role is admin" do
      let(:options) { { role: "admin" } }

      it { is_expected.to eq([user5, user4]) }
    end
  end
end
