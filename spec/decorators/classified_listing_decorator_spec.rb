require "rails_helper"

RSpec.describe ClassifiedListingDecorator, type: :decorator do
  let_it_be_readonly(:category) { create(:classified_listing_category) }
  let(:decorated_listing) do
    build(:classified_listing, classified_listing_category: category).decorate
  end

  describe "#social_preview_category" do
    it "returns the category name if the social preview category is blank" do
      allow(category).to receive(:social_preview_description).and_return(nil)

      expect(decorated_listing.social_preview_category).to eq(category.name)
    end

    it "returns the category's social preview descripton if available" do
      expect(decorated_listing.social_preview_category).
        to eq(category.social_preview_description)
    end
  end

  describe "#social_preview_color" do
    it "returns the default color if social preview color is blank" do
      allow(category).to receive(:social_preview_color).and_return(nil)

      expect(decorated_listing.social_preview_color).
        to eq(ClassifiedListingDecorator::DEFAULT_COLOR)
    end

    it "returns the category's social preview color if available" do
      expect(decorated_listing.social_preview_color).
        to eq(category.social_preview_color)
    end

    it "can modify the brightness" do
      color = category.social_preview_color

      expect(decorated_listing.social_preview_color(brightness: 0.8)).
        to eq(HexComparer.new([color]).brightness(0.8))
    end
  end
end
