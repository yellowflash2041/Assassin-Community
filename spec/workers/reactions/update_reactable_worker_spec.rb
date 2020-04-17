require "rails_helper"

RSpec.describe Reactions::UpdateReactableWorker, type: :worker do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment) }
    let(:worker) { subject }

    it " updates the reactable Article" do
      sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker) do
        worker.perform(reaction.id)
      end
    end

    it " updates the reactable Comment" do
      updated_at = 1.day.ago
      comment.update_columns(updated_at: updated_at)
      worker.perform(comment_reaction.id)
      expect(comment.reload.updated_at).to be > updated_at
    end

    it " doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
