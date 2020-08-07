require "rails_helper"

RSpec.describe ProfileImage, type: :labor do
  describe "#get" do
    it "returns user profile_image_url" do
      user = build_stubbed(:user)
      expect(described_class.new(user).get).to eq(user.profile_image_url)
    end

    context "when user has no profile_image" do
      it "returns backup image prefixed with Cloudinary" do
        user = build_stubbed(:user, profile_image: nil)
        correct_prefix = "/c_fill,f_auto,fl_progressive,h_120,q_auto,w_120/"
        expect(described_class.new(user).get).to include(correct_prefix + described_class::BACKUP_LINK)
      end
    end
  end
end
