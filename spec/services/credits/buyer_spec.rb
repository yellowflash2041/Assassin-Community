require "rails_helper"

RSpec.describe Credits::Buyer do
  let(:user) { create(:user) }
  let(:org) { create(:organization) }
  let(:listing) { create(:classified_listing, user: user) }

  context "when not enough credits are available" do
    it "does not spend credits for the user" do
      create(:credit, user: user)
      expect do
        res = described_class.call(purchaser: user, purchase: listing, cost: 2)
        expect(res).to be(false)
      end.not_to change(user.credits.spent, :count)
    end

    it "does not spend credits for the organization" do
      create(:credit, organization: org)
      expect do
        res = described_class.call(purchaser: org, purchase: listing, cost: 2)
        expect(res).to be(false)
      end.not_to change(org.credits.spent, :count)
    end
  end

  context "when enough credits are available" do
    it "spends credits for the user" do
      create_list(:credit, 2, user: user)
      expect do
        res = described_class.call(purchaser: user, purchase: listing, cost: 2)
        expect(res).to be(true)
      end.to change(user.credits.spent, :count)
    end

    it "spends credits for the organization" do
      create_list(:credit, 2, organization: org)
      expect do
        res = described_class.call(purchaser: org, purchase: listing, cost: 2)
        expect(res).to be(true)
      end.to change(org.credits.spent, :count)
    end

    it "updates the updated_at of the user" do
      create_list(:credit, 2, user: user)
      Timecop.freeze(Time.current) do
        described_class.call(purchaser: user, purchase: listing, cost: 2)
        expect(user.reload.updated_at.to_i >= Time.current.to_i).to be(true)
      end
    end

    it "updates the updated_at of the organization" do
      create_list(:credit, 2, organization: org)
      Timecop.freeze(Time.current) do
        described_class.call(purchaser: org, purchase: listing, cost: 2)
        expect(org.reload.updated_at.to_i >= Time.current.to_i).to be(true)
      end
    end
  end
end
