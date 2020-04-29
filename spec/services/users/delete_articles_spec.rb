require "rails_helper"

RSpec.describe Users::DeleteArticles, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:article) { create(:article, user: user) }
  let!(:article2) { create(:article, user: user) }
  let!(:article3) { create(:article, user: user2) }

  it "deletes articles" do
    described_class.call(user)
    expect(Article.find_by(id: article.id)).to be_nil
    expect(Article.find_by(id: article2.id)).to be_nil
    expect(Article.find(article3.id)).to be_present
  end

  it "removes article from Elasticsearch" do
    sidekiq_perform_enqueued_jobs
    expect(article.elasticsearch_doc).not_to be_nil

    sidekiq_perform_enqueued_jobs { described_class.call(user) }
    expect { article.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
  end

  context "with comments" do
    let(:buster) { double }

    before do
      allow(buster).to receive(:bust_comment)
      allow(buster).to receive(:bust_article)
      allow(buster).to receive(:bust_user)

      create_list(:comment, 2, commentable: article, user: user2)
    end

    it "deletes articles' comments" do
      described_class.call(user)
      expect(Comment.where(commentable_id: article.id, commentable_type: "Article").any?).to be false
    end

    it "deletes articles' buffer updates" do
      BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")

      described_class.call(user)

      expect(BufferUpdate.where(article_id: article.id).any?).to be false
    end

    it "busts cache" do
      described_class.call(user, buster)
      expect(buster).to have_received(:bust_comment).with(article).twice
      expect(buster).to have_received(:bust_user).with(user2).at_least(:once)
      expect(buster).to have_received(:bust_article).with(article)
    end

    it "removes comments from Elasticsearch", :aggregate_failures do
      sidekiq_perform_enqueued_jobs
      comments = article.comments
      comments.each { |comment| expect(comment.elasticsearch_doc).not_to be_nil }
      sidekiq_perform_enqueued_jobs(only: Search::RemoveFromIndexWorker) do
        described_class.call(user)
      end

      comments.each do |comment|
        expect { comment.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
      end
    end
  end
end
