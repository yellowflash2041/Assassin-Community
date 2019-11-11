require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  let(:user) { create(:user) }

  it "deletes user" do
    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
  end

  it "busts user profile page" do
    buster = double
    allow(buster).to receive(:bust)
    allow(CacheBuster).to receive(:new).and_return(buster)
    described_class.new(user).call
    expect(buster).to have_received(:bust).with("/#{user.username}")
  end

  it "deletes user's follows" do
    create(:follow, follower: user)
    create(:follow, followable: user)

    expect do
      described_class.call(user)
    end.to change(Follow, :count).by(-2)
  end

  it "deletes user's articles" do
    article = create(:article, user: user)
    described_class.call(user)
    expect(Article.find_by(id: article.id)).to be_nil
  end
end
