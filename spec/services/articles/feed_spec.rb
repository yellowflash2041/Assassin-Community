require "rails_helper"

NON_DEFAULT_EXPERIMENTS = %i[
  default_home_feed_with_more_randomness_experiment
  mix_default_and_more_random_experiment
  more_tag_weight_experiment
  more_tag_weight_more_random_experiment
  more_comments_experiment
  more_experience_level_weight_experiment
  more_tag_weight_randomized_at_end_experiment
  more_experience_level_weight_randomized_at_end_experiment
  more_comments_randomized_at_end_experiment
  mix_of_everything_experiment
].freeze

RSpec.describe Articles::Feed, type: :service do
  let(:user) { create(:user) }
  let!(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }
  let!(:article) { create(:article) }
  let!(:hot_story) { create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago) }
  let!(:old_story) { create(:article, published_at: 3.days.ago) }
  let!(:low_scoring_article) { create(:article, score: -1000) }
  let!(:month_old_story) { create(:article, published_at: 1.month.ago) }

  describe "#published_articles_by_tag" do
    let(:unpublished_article) { create(:article, published: false) }
    let(:tag) { "foo" }
    let(:tagged_article) { create(:article, tags: tag) }

    it "returns published articles" do
      expect(feed.published_articles_by_tag).to include article
      expect(feed.published_articles_by_tag).not_to include unpublished_article
    end

    context "with tag" do
      it "returns articles with the specified tag" do
        expect(described_class.new(tag: tag).published_articles_by_tag).to include tagged_article
      end
    end
  end

  describe "#top_articles_by_timeframe" do
    let!(:moderately_high_scoring_article) { create(:article, score: 20) }
    let(:result) { feed.top_articles_by_timeframe(timeframe: "week").to_a }

    it "returns articles ordered by score" do
      expect(result.slice(0, 2)).to eq [hot_story, moderately_high_scoring_article]
      expect(result.last).to eq low_scoring_article
    end

    context "with week article timeframe specified" do
      it "only returns articles from this week" do
        expect(feed.top_articles_by_timeframe(timeframe: "week")).not_to include(month_old_story)
      end
    end
  end

  describe "#latest_feed" do
    it "only returns articles with scores above -40" do
      expect(feed.latest_feed).not_to include(low_scoring_article)
    end

    it "returns articles ordered by publishing date descending" do
      expect(feed.latest_feed.last).to eq month_old_story
    end
  end

  describe "#default_home_feed_and_featured_story" do
    let(:featured_story) { feed.default_home_feed_and_featured_story.first }
    let(:stories) { feed.default_home_feed_and_featured_story.second }

    before { article.update(published_at: 1.week.ago) }

    it "returns a featured article and array of other articles" do
      expect(featured_story).to be_a(Article)
      expect(stories).to be_a(Array)
      expect(stories.first).to be_a(Article)
    end

    it "chooses a featured story with a main image" do
      expect(featured_story).to eq hot_story
    end

    it "doesn't include low scoring stories" do
      expect(stories).not_to include(low_scoring_article)
    end

    context "when user logged in" do
      let(:result) { feed.default_home_feed_and_featured_story(user_signed_in: true) }
      let(:featured_story) { result.first }
      let(:stories) { result.second }

      it "only includes stories" do
        expect(stories).to include(old_story)
        expect(stories).to include(article)
        expect(stories).to include(hot_story)
      end
    end

    context "when ranking is true" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story(ranking: true)
        expect(feed).to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking is false" do
      it "does not perform article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story(ranking: false)
        expect(feed).not_to have_received(:rank_and_sort_articles)
      end
    end

    context "when ranking not passed" do
      it "performs article ranking" do
        allow(feed).to receive(:rank_and_sort_articles).and_call_original
        feed.default_home_feed_and_featured_story
        expect(feed).to have_received(:rank_and_sort_articles)
      end
    end
  end

  describe "#default_home_feed" do
    let!(:new_story) { create(:article, published_at: 10.minutes.ago, score: 10) }

    context "when user is not logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: false) }

      before { article.update(published_at: 1.week.ago) }

      it "returns array of articles" do
        expect(stories).to be_a(Array)
        expect(stories.first).to be_a(Article)
      end

      it "doesn't include low scoring stories" do
        expect(stories).not_to include(low_scoring_article)
      end
    end

    context "when user logged in" do
      let(:stories) { feed.default_home_feed(user_signed_in: true) }

      it "includes stories " do
        expect(stories).to include(old_story)
        expect(stories).to include(new_story)
      end
    end
  end

  describe "all non-default experiments" do
    it "returns articles for all experiments" do
      new_story = create(:article, published_at: 10.minutes.ago, score: 10)
      NON_DEFAULT_EXPERIMENTS.each do |method|
        stories = feed.default_home_feed_with_more_randomness_experiment
        expect(stories).to include(old_story)
        expect(stories).to include(new_story)
      end
    end
  end

  describe "#more_comments_experiment" do
    let(:article_with_one_comment) { create(:article) }
    let(:article_with_five_comments) { create(:article) }
    let(:stories) { feed.more_comments_experiment }

    before do
      create(:comment, user: user, commentable: article_with_one_comment)
      create_list(:comment, 5, user: user, commentable: article_with_five_comments)
      article_with_one_comment.update_score
      article_with_five_comments.update_score
      article_with_one_comment.reload
      article_with_five_comments.reload
    end

    it "ranks articles with more comments higher" do
      expect(stories[0]).to eq article_with_five_comments
    end
  end

  describe "#score_followed_user" do
    context "when article is written by a followed user" do
      before { user.follow(article.user) }

      it "returns a score of 1" do
        expect(feed.score_followed_user(article)).to eq 1
      end
    end

    context "when article is not written by a followed user" do
      it "returns a score of 0" do
        expect(feed.score_followed_user(article)).to eq 0
      end
    end
  end

  describe "#score_followed_organization" do
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }

    context "when article is from a followed organization" do
      before { user.follow(organization) }

      it "returns a score of 1" do
        expect(feed.score_followed_organization(article)).to eq 1
      end
    end

    context "when article is not from a followed organization" do
      it "returns a score of 0" do
        expect(feed.score_followed_organization(article)).to eq 0
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article) }

      it "returns a score of 0" do
        expect(feed.score_followed_organization(article)).to eq 0
      end
    end
  end

  describe "#score_randomness" do
    context "when random number is less than 0.6 but greater than 0.3" do
      it "returns 6" do
        allow(feed).to receive(:rand).and_return(2)
        expect(feed.score_randomness).to eq 6
      end
    end

    context "when random number is less than 0.3" do
      it "returns 3" do
        allow(feed).to receive(:rand).and_return(1)
        expect(feed.score_randomness).to eq 3
      end
    end

    context "when random number is greater than 0.6" do
      it "returns 0" do
        allow(feed).to receive(:rand).and_return(0)
        expect(feed.score_randomness).to eq 0
      end
    end
  end

  describe "#score_language" do
    context "when article is in a user's preferred language" do
      it "returns a score of 1" do
        expect(feed.score_language(article)).to eq 1
      end
    end

    context "when article is not in user's prferred language" do
      before { article.language = "de" }

      it "returns a score of -10" do
        expect(feed.score_language(article)).to eq(-15)
      end
    end

    context "when article doesn't have a language, assume english" do
      before { article.language = nil }

      it "returns a score of 1" do
        expect(feed.score_language(article)).to eq 1
      end
    end
  end

  describe "#score_followed_tags" do
    let(:tag) { create(:tag) }
    let(:unfollowed_tag) { create(:tag) }

    context "when article includes a followed tag" do
      let(:article) { create(:article, tags: tag.name) }

      before do
        user.follow(tag)
        user.save
        user.follows.last.update(points: 2)
      end

      it "returns the followed tag point value" do
        expect(feed.score_followed_tags(article)).to eq 2
      end
    end

    context "when article includes multiple followed tags" do
      let(:tag2) { create(:tag) }
      let(:article) { create(:article, tags: "#{tag.name}, #{tag2.name}") }

      before do
        user.follow(tag)
        user.follow(tag2)
        user.save
        user.follows.each { |follow| follow.update(points: 2) }
      end

      it "returns the sum of followed tag point values" do
        expect(feed.score_followed_tags(article)).to eq 4
      end
    end

    context "when article includes an unfollowed tag" do
      let(:article) { create(:article, tags: "#{tag.name}, #{unfollowed_tag.name}") }

      before do
        user.follow(tag)
        user.save
      end

      it "doesn't score the unfollowed tag" do
        expect(feed.score_followed_tags(article)).to eq 1
      end
    end

    context "when article doesn't include any followed tags" do
      let(:article) { create(:article, tags: unfollowed_tag.name) }

      it "returns 0" do
        expect(feed.score_followed_tags(article)).to eq 0
      end
    end

    context "when user doesn't follow any tags" do
      it "returns 0" do
        expect(user.cached_followed_tag_names).to be_empty
        expect(feed.score_followed_tags(article)).to eq 0
      end
    end
  end

  describe "#score_experience_level" do
    let(:article) { create(:article, experience_level_rating: 7) }

    context "when user has a further experience level" do
      let(:user) { create(:user, experience_level: 1) }

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(feed.score_experience_level(article)).to eq(-3)
      end

      it "returns  proper negative when fractional" do
        article.experience_level_rating = 8
        expect(feed.score_experience_level(article)).to eq(-3.5)
      end
    end

    context "when user has a closer experience level" do
      let(:user) { create(:user, experience_level: 9) }

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(feed.score_experience_level(article)).to eq(-1)
      end
    end

    context "when the user does not have an experience level set" do
      let(:user) { create(:user, experience_level: nil) }

      it "uses a value of 5 for user experience level" do
        expect(feed.score_experience_level(article)).to eq(-1)
      end
    end
  end

  describe "#score_comments" do
    let(:article_with_one_comment) { create(:article) }
    let(:article_with_five_comments) { create(:article) }

    before do
      create(:comment, user: user, commentable: article_with_one_comment)
      create_list(:comment, 5, user: user, commentable: article_with_five_comments)
      article_with_one_comment.update_score
      article_with_five_comments.update_score
      article_with_one_comment.reload
      article_with_five_comments.reload
    end

    context "when comment_weight is default of 0" do
      it "returns 0 for uncommented articles" do
        expect(feed.score_comments(article)).to eq(0)
      end

      it "returns 0 for articles with comments" do
        expect(article_with_five_comments.comments_count).to eq(5)
        expect(feed.score_comments(article_with_five_comments)).to eq(0)
      end
    end

    context "when comment_weight is higher than 0" do
      before { feed.instance_variable_set(:@comment_weight, 2) }

      it "returns 0 for uncommented articles" do
        expect(feed.score_comments(article)).to eq(0)
      end

      it "returns a non-zero score for commented upon articles" do
        expect(feed.score_comments(article_with_one_comment)).to be > 0
      end

      it "scores article with more comments high than others" do
        expect(feed.score_comments(article_with_five_comments)).to be > feed.score_comments(article_with_one_comment)
      end
    end
  end

  describe "#rank_and_sort_articles" do
    let(:article1) { create(:article) }
    let(:article2) { create(:article) }
    let(:article3) { create(:article) }
    let(:articles) { [article1, article2, article3] }

    context "when number of articles specified" do
      let(:feed) { described_class.new(number_of_articles: 1) }

      it "only returns the requested number of articles" do
        expect(feed.rank_and_sort_articles(articles).size).to eq 1
      end
    end

    it "returns articles in scored order" do
      allow(feed).to receive(:score_single_article).with(article1).and_return(1)
      allow(feed).to receive(:score_single_article).with(article2).and_return(2)
      allow(feed).to receive(:score_single_article).with(article3).and_return(3)

      expect(feed.rank_and_sort_articles(articles)).to eq [article3, article2, article1]
    end
  end

  describe ".globally_hot_articles" do
    let!(:recently_published_article) { create(:article, published_at: 3.hours.ago) }
    let(:globally_hot_articles) { feed.globally_hot_articles(true).second }

    it "returns hot stories" do
      expect(globally_hot_articles).not_to be_empty
    end

    it "returns recent stories" do
      expect(globally_hot_articles).to include(recently_published_article)
    end

    context "when low number of hot stories and no recently published articles" do
      before do
        Article.delete_all
        create(:article, hotness_score: 1000, score: 1000, published_at: 3.hours.ago)
      end

      # This test handles a situation in which there are a low number of hot or new stories, and the user is logged in.
      # Previously the offest factor could result in zero stories being returned sometimes.

      # We manually called `feed.globally_hot_articles` here because `let` caches it!
      it "still returns articles" do
        empty_feed = false
        20.times do
          if feed.globally_hot_articles(true).second.empty?
            empty_feed = true
            break
          end
        end
        expect(empty_feed).to be false
      end
    end

    context "when now hot stories and no recently published articles" do
      before do
        Article.delete_all
        create(:article, hotness_score: 0, score: 0, published_at: 3.days.ago)
      end

      it "still returns articles" do
        expect(globally_hot_articles).not_to be_empty
      end
    end
  end

  describe ".find_featured_story" do
    let(:featured_story) { described_class.find_featured_story(stories) }

    context "when passed an ActiveRecord collection" do
      let(:stories) { Article.all }

      it "returns first article with a main image" do
        expect(featured_story.main_image).not_to be_nil
      end
    end

    context "when passed an array" do
      let(:stories) { Article.all.to_a }

      it "returns first article with a main image" do
        expect(featured_story.main_image).not_to be_nil
      end
    end

    context "when passed collection without any articles" do
      let(:stories) { [] }

      it "returns an new, empty Article object" do
        expect(featured_story.main_image).to be_nil
        expect(featured_story.id).to be_nil
      end
    end
  end

  describe "#find_featured_story" do
    it "calls the class method" do
      allow(described_class).to receive(:find_featured_story)
      feed.find_featured_story([])
      expect(described_class).to have_received(:find_featured_story)
    end
  end
end
