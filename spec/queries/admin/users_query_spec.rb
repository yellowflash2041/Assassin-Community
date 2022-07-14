require "rails_helper"

RSpec.describe Admin::UsersQuery, type: :query do
  subject do
    described_class.call(search: search, role: role, roles: roles, organizations: organizations,
                         joining_start: joining_start, joining_end: joining_end, date_format: date_format)
  end

  let(:role) { nil }
  let(:roles) { [] }
  let(:organizations) { [] }
  let(:search) { [] }
  let(:joining_start) { nil }
  let(:joining_end) { nil }
  let(:date_format) { "DD/MM/YYYY" }

  let!(:org1) { create(:organization, name: "Org1") }
  let!(:org2) { create(:organization, name: "Org2") }

  let!(:user)  { create(:user, :trusted, name: "Greg", registered_at: "2020-05-06T13:09:47+0000") }
  let!(:user2) { create(:user, :trusted, name: "Gregory", registered_at: "2020-05-08T13:09:47+0000") }
  let!(:user3) { create(:user, :tag_moderator, name: "Paul", registered_at: "2020-05-10T13:09:47+0000") }
  let!(:user4) { create(:user, :admin, name: "Susi", registered_at: "2020-10-05T13:09:47+0000") }
  let!(:user5) { create(:user, :trusted, :admin, name: "Beth", registered_at: "2020-10-07T13:09:47+0000") }
  let!(:user6) { create(:user, :super_admin, name: "Jean", registered_at: "2020-10-08T13:09:47+0000") }
  let!(:user7) do
    create(:user, registered_at: "2020-12-05T13:09:47+0000").tap do |u|
      u.add_role(:single_resource_admin, DataUpdateScript)
    end
  end

  describe ".call" do
    context "when no arguments are given" do
      it "returns all users" do
        expect(described_class.call).to eq([user7, user6, user5, user4, user3, user2, user])
      end
    end

    context "when search is set" do
      let(:search) { "greg" }

      it { is_expected.to eq([user2, user]) }
    end

    context "when role is tag_moderator" do
      let(:role) { "tag_moderator" }

      it { is_expected.to eq([user3]) }
    end

    context "when role is super_admin" do
      let(:role) { "super_admin" }

      it { is_expected.to eq([user6]) }
    end

    context "when role is trusted" do
      let(:role) { "trusted" }

      it { is_expected.to eq([user5, user2, user]) }
    end

    context "when role is admin" do
      let(:role) { "admin" }

      it { is_expected.to eq([user5, user4]) }
    end

    context "when roles is multiple" do
      let(:roles) { ["Admin", "Tech Admin", "Resource Admin: DataUpdateScript"] }

      it { is_expected.to eq([user7, user5, user4]) }
    end

    context "when given multiple single_resource_admin roles" do
      let(:roles) { ["Admin", "Super Admin", "Resource Admin: DataUpdateScript", "Resource Admin: DisplayAd"] }
      let!(:user8) { create(:user).tap { |u| u.add_role(:single_resource_admin, DisplayAd) } }

      it { is_expected.to eq([user8, user7, user6, user5, user4]) }
    end

    context "when given organizations" do
      before do
        create(:organization_membership, user: user, organization: org1, type_of_user: "member")
        create(:organization_membership, user: user2, organization: org2, type_of_user: "member")
      end

      let(:organizations) { [org1.id, org2.id] }

      it { is_expected.to eq([user2, user]) }
    end

    context "when given organizations and roles" do
      before do
        create(:organization_membership, user: user, organization: org1, type_of_user: "member")
        create(:organization_membership, user: user4, organization: org2, type_of_user: "member")
      end

      let(:organizations) { [org1.id, org2.id] }
      let(:roles) { ["Admin"] }

      it { is_expected.to eq([user4]) }
    end

    context "when filtering by joining_start and default DD/MM/YYYY date format" do
      let(:joining_start) { "01/12/2020" }

      it { is_expected.to eq([user7]) }
    end

    context "when filtering by joining_start and alternative MM/DD/YYYY date format" do
      let(:joining_start) { "12/01/2020" }
      let(:date_format) { "MM/DD/YYYY" }

      it { is_expected.to eq([user7]) }
    end

    context "when filtering by joining_end and default DD/MM/YYYY date format" do
      let(:joining_end) { "07/05/2020" }

      it { is_expected.to eq([user]) }
    end

    context "when filtering by joining_end and alternative MM/DD/YYYY date format" do
      let(:joining_end) { "05/07/2020" }
      let(:date_format) { "MM/DD/YYYY" }

      it { is_expected.to eq([user]) }
    end

    context "when filtering by both joining_start and joining_end" do
      let(:joining_start) { "01/05/2020" }
      let(:joining_end) { "31/05/2020" }

      it { is_expected.to eq([user3, user2, user]) }
    end
  end
end
