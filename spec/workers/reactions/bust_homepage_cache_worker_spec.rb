require "rails_helper"

RSpec.describe Reactions::BustHomepageCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, featured: true) }
    let(:worker) { subject }

    it "busts the homepage cache when reactable is an Article" do
      reaction = create(:reaction, reactable: article, user: user)
      allow(CacheBuster).to receive(:bust)

      worker.perform(reaction.id)

      expect(CacheBuster).to have_received(:bust).exactly(4)
    end

    it "doesn't bust the homepage cache when reactable is a Comment" do
      comment = create(:comment, commentable: article)
      comment_reaction = create(:reaction, reactable: comment, user: user)
      allow(CacheBuster).to receive(:bust)

      worker.perform(comment_reaction.id)

      expect(CacheBuster).not_to have_received(:bust)
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
