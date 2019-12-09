require "rails_helper"

RSpec.describe Credit, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:organization).optional }
  it { is_expected.to belong_to(:purchase).optional }

  context "when caching counters" do
    let_it_be(:user_credits) { create_list(:credit, 2, user: user) }
    let_it_be(:org_credits) { create_list(:credit, 1, organization: organization) }

    describe "#credits_count" do
      it "counts credits for user" do
        # See https://github.com/magnusvk/counter_culture/issues/259
        described_class.counter_culture_fix_counts
        expect(user.reload.credits_count).to eq(user.credits.size)
      end

      it "counts credits for organization" do
        described_class.counter_culture_fix_counts
        expect(organization.reload.credits_count).to eq(organization.credits.size)
      end
    end

    describe "#unspent_credits_count" do
      it "counts the number of unspent credits for a user" do
        expect(user.reload.unspent_credits_count).to eq(user.credits.unspent.size)
      end

      it "counts the number of unspent credits for an organization" do
        expect(organization.reload.unspent_credits_count).to eq(organization.credits.unspent.size)
      end
    end

    describe "#spent_credits_count" do
      it "counts the number of spent credits for a user" do
        create_list(:credit, 1, user: user, spent: true)
        expect(user.reload.spent_credits_count).to eq(user.credits.spent.size)
      end

      it "counts the number of spent credits for an organization" do
        create_list(:credit, 1, organization: organization, spent: true)
        expect(organization.reload.spent_credits_count).to eq(organization.credits.spent.size)
      end
    end
  end

  describe "#purchase" do
    let_it_be(:credit) { build(:credit) }

    it "is valid with a purchase" do
      credit.purchase = build(:classified_listing)
      expect(credit).to be_valid
    end

    it "is valid without a purchase" do
      credit.purchase = nil
      expect(credit).to be_valid
    end
  end
end
