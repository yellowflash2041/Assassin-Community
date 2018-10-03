require "rails_helper"

RSpec.describe "CommentsUpdate", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }

  before do
    sign_in user
  end

  it "updates ordinary article with proper params" do
    new_body = "NEW TITLE #{rand(100)}"
    put "/comments/#{comment.id}", params: {
      comment: { body_markdown: new_body }
    }
    expect(Comment.last.processed_html).to include(new_body)
  end
end
