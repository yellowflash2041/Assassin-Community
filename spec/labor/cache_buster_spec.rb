require "rails_helper"

RSpec.describe CacheBuster do
  let(:cache_buster) { described_class.new }
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }
  let(:organization) { create(:organization) }
  let(:listing) { create(:classified_listing, user_id: user.id, category: "cfp") }
  let(:podcast) { create(:podcast) }
  let(:podcast_episode) { create(:podcast_episode, podcast_id: podcast.id) }

  describe "#bust_comment" do
    it "busts comment" do
      cache_buster.bust_comment(comment.commentable)
    end

    it "busts podcast episode comment" do
      ep_comment = create(:comment, commentable: podcast_episode)
      cache_buster.bust_comment(ep_comment.commentable)
    end
  end

  describe "#bust_article" do
    it "busts article" do
      cache_buster.bust_article(article)
    end

    it "busts featured article" do
      article.update_columns(featured: true)
      cache_buster.bust_article(article)
    end
  end

  describe "#bust_page" do
    it "busts page + slug " do
      cache_buster.bust_page("SlUg")
    end
  end

  describe "#bust_tag" do
    it "busts tag name + tags" do
      cache_buster.bust_tag("cfp")
    end
  end

  describe "#bust_events" do
    it "busts events" do
      cache_buster.bust_events
    end
  end

  describe "#bust_podcast" do
    it "busts podcast" do
      cache_buster.bust_podcast("jsparty/the-story-of-konami-js")
    end
  end

  describe "#bust_organization" do
    before do
      create(:article, organization_id: organization.id)
    end

    it "busts slug + article path" do
      cache_buster.bust_organization(organization, "SlUg")
    end

    it "logs an error from bust_organization" do
      allow(Rails.logger).to receive(:error)
      cache_buster.bust_organization(4, 5)
      expect(Rails.logger).to have_received(:error).once
    end
  end

  describe "#bust_podcast_episode" do
    it "busts podcast episode" do
      cache_buster.bust_podcast_episode(podcast_episode, "/cfp", "-007")
    end

    it "logs an error from bust_podcast_episode" do
      allow(Rails.logger).to receive(:warn)
      allow(described_class).to receive(:new).and_return(cache_buster)
      allow(cache_buster).to receive(:bust).and_raise(StandardError)
      cache_buster.bust_podcast_episode(podcast_episode, 12, "-007")
      expect(Rails.logger).to have_received(:warn).once
    end
  end

  describe "#bust_classified_listings" do
    it "busts classified listings" do
      cache_buster.bust_classified_listings(listing)
    end
  end

  describe "#bust_user" do
    it "busts a user" do
      allow(cache_buster).to receive(:bust)
      cache_buster.bust_user(user)
      expect(cache_buster).to have_received(:bust).with("/" + user.username.to_s)
      expect(cache_buster).to have_received(:bust).with("/" + user.username.to_s + "/comments?i=i")
      expect(cache_buster).to have_received(:bust).with("/feed/" + user.username.to_s)
    end
  end
end
