require "rails_helper"

RSpec.describe RatingVotes::AssignRatingWorker, type: :worker do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:worker) { subject }

  before do
    allow(CacheBuster).to receive(:bust_podcast)
    user.add_role_synchronously(:trusted)
  end

  describe "#perform" do
    it "assigns explicit score" do
      second_user.add_role_synchronously(:trusted)
      create(:rating_vote, article_id: article.id, user_id: user.id, rating: 3.0)
      create(:rating_vote, article_id: article.id, user_id: second_user.id, rating: 2.0)
      worker.perform(article.id)
      expect(article.reload.experience_level_rating).to eq(2.5)
      expect(article.reload.experience_level_rating_distribution).to eq(1.0)
    end

    it "assigns implicit readinglist_reaction score" do
      create(:rating_vote, article_id: article.id, user_id: user.id, rating: 4.0)
      create(:rating_vote, article_id: article.id, user_id: second_user.id, rating: 2.0, context: "readinglist_reaction")
      worker.perform(article.id)
      expect(article.reload.experience_level_rating).to eq(3.0)
      expect(article.reload.experience_level_rating_distribution).to eq(2.0)
    end

    it "assigns implicit comment score" do
      create(:rating_vote, article_id: article.id, user_id: user.id, rating: 4.0)
      create(:rating_vote, article_id: article.id, user_id: second_user.id, rating: 1.0, context: "comment")
      worker.perform(article.id)
      expect(article.reload.experience_level_rating).to eq(2.5)
      expect(article.reload.experience_level_rating_distribution).to eq(3.0)
    end

    it "updates article in Elasticsearch" do
      create(:rating_vote, article_id: article.id, user_id: user.id, rating: 4.0)
      create(:rating_vote, article_id: article.id, user_id: second_user.id, rating: 1.0, context: "comment")
      worker.perform(article.id)
      expect(article.elasticsearch_doc.dig("_source", "experience_level_rating")).to eq(2.5)
    end
  end
end
