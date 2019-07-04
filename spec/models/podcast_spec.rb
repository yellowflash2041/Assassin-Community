require "rails_helper"

RSpec.describe Podcast, type: :model do
  it { is_expected.to validate_presence_of(:image) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:main_color_hex) }
  it { is_expected.to validate_presence_of(:feed_url) }

  describe "validations" do
    let(:podcast) { create(:podcast) }

    it "is valid" do
      expect(podcast).to be_valid
    end

    it "triggers cache busting on save" do
      expect { podcast.save }.to have_enqueued_job.on_queue("podcasts_bust_cache").twice
    end

    # Couldn't use shoulda uniqueness matchers for these tests because:
    # Shoulda uses `save(validate: false)` which skips validations
    # So an invalid record is trying to be saved but fails because of the db constraints
    # https://git.io/fjg2g

    it "validates slug uniqueness" do
      podcast2 = build(:podcast, slug: podcast.slug)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:slug]).to be_present
    end

    it "validates feed_url uniqueness" do
      podcast2 = build(:podcast, feed_url: podcast.feed_url)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:feed_url]).to be_present
    end

    it "doesn't allow to create a podcast with a reserved word slug" do
      enter_podcast = build(:podcast, slug: "enter")
      expect(enter_podcast).not_to be_valid
      expect(enter_podcast.errors[:slug]).to be_present
    end

    it "is invalid when a user with a username equal to the podcast slug exists" do
      create(:user, username: "annabu")
      user_podcast = build(:podcast, slug: "annabu")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end

    it "is invalid when a page with a slug equal to the podcast slug exists" do
      create(:page, slug: "superpage")
      user_podcast = build(:podcast, slug: "superpage")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end

    it "is invalid when an org with a slug equal to the podcast slug exists" do
      create(:organization, slug: "superorganization")
      user_podcast = build(:podcast, slug: "superorganization")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end
  end

  describe "#existing_episode" do
    let(:podcast) { create(:podcast) }
    let(:guid) { "<guid isPermaLink=\"false\">http://podcast.example/file.mp3</guid>" }

    let(:item) do
      build(:podcast_episode_rss_item, pubDate: "2019-06-19",
                                       enclosure_url: "https://audio.simplecast.com/2330f132.mp3",
                                       description: "yet another podcast",
                                       title: "lightalloy's podcast",
                                       guid: guid,
                                       itunes_subtitle: "hello",
                                       content_encoded: nil,
                                       itunes_summary: "world",
                                       link: "https://litealloy.ru")
    end

    it "determines existing episode by media_url" do
      episode = create(:podcast_episode, podcast: podcast, media_url: "https://audio.simplecast.com/2330f132.mp3")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by title" do
      episode = create(:podcast_episode, podcast: podcast, title: "lightalloy's podcast")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by guid" do
      episode = create(:podcast_episode, podcast: podcast, guid: guid)
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by website_url" do
      episode = create(:podcast_episode, podcast: podcast, website_url: "https://litealloy.ru")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "doesn't determine existing episode by non-unique website_url" do
      podcast.update_columns(unique_website_url?: false)
      create(:podcast_episode, podcast: podcast, website_url: "https://litealloy.ru")
      expect(podcast.existing_episode(item)).to eq(nil)
    end
  end
end
