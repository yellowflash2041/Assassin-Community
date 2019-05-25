require "rails_helper"

RSpec.describe "ReadingListItems", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:reaction) { create(:reaction, reactable_id: article.id, user_id: user.id) }

  before do
    sign_in user
  end

  describe "GET reading list" do
    it "returns reading list page" do
      get "/readinglist"
      expect(response.body).to include("Reading List")
    end
  end

  describe "PUT reading_list_items/:id" do
    it "returns archives item if no param" do
      put "/reading_list_items/#{reaction.id}"
      expect(reaction.reload.status).to eq("archived")
    end

    it "unarchives an item if current_status is passed as archived" do
      put "/reading_list_items/#{reaction.id}", params: { current_status: "archived" }
      expect(reaction.reload.status).to eq("valid")
    end
  end
end
