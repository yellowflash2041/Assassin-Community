require "rails_helper"

RSpec.describe Admin::ChartsData, type: :service do
  it "returns proper data type" do
    expect(described_class.new.call).to be_an_instance_of(Array)
  end

  it "returns proper entities" do
    expect(described_class.new.call.map(&:first)).to eq(["Posts", "Comments", "Reactions", "New members"])
  end

  it "returns proper previous period number" do
    create_list(:article, 2, published_at: 8.days.ago)
    expect(described_class.new.call.first.third).to eq(2)
  end

  it "returns proper number of days of chart data array" do
    expect(described_class.new(20).call.first.fourth.size).to eq(20)
  end

  describe "current period" do
    it "returns proper number of items" do
      create(:article, published_at: Time.zone.today)
      create_list(:article, 3, published_at: 4.days.ago)
      create_list(:article, 2, published_at: 7.days.ago)
      create(:article, published_at: 8.days.ago)

      expect(described_class.new.call.first.second).to eq(5)
    end

    it "ignores today" do
      create(:article, published_at: Time.zone.today)

      expect(described_class.new.call.first.second).to eq(0)
    end

    it "goes back seven days by default" do
      create(:article, published_at: 7.days.ago)
      create(:article, published_at: 8.days.ago)

      expect(described_class.new.call.first.second).to eq(1)
    end
  end
end
