require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  it { is_expected.to validate_length_of(:name).is_at_most(30) }
  it { is_expected.not_to allow_value("#Hello", "c++", "AWS-Lambda").for(:name) }

  describe "validations" do
    describe "bg_color_hex" do
      it "passes validations if bg_color_hex is valid" do
        tag.bg_color_hex = "#000000"
        expect(tag).to be_valid
      end

      it "fails validation if bg_color_hex is invalid" do
        tag.bg_color_hex = "0000000"
        expect(tag).not_to be_valid
      end
    end

    describe "text_color_hex" do
      it "passes validations if text_color_hex is valid" do
        tag.text_color_hex = "#000000"
        expect(tag).to be_valid
      end

      it "fails validation if text_color_hex is invalid" do
        tag.text_color_hex = "0000000"
        expect(tag).not_to be_valid
      end
    end

    describe "name" do
      it "passes validations if name is alphanumeric" do
        tag.name = "foobar123"
        expect(tag).to be_valid
      end

      it "fails validations if name is empty" do
        tag.name = ""
        expect(tag).not_to be_valid
      end

      it "fails validations if name is nil" do
        tag.name = nil
        expect(tag).not_to be_valid
      end

      it "fails validations if name uses non-ASCII characters" do
        tag.name = "مرحبا"
        expect(tag).not_to be_valid

        tag.name = "你好"
        expect(tag).not_to be_valid

        tag.name = "Cześć"
        expect(tag).not_to be_valid

        tag.name = "♩ ♪ ♫ ♬ ♭ ♮ ♯"
        expect(tag).not_to be_valid

        tag.name = "Test™"
        expect(tag).not_to be_valid
      end
    end

    describe "alias_for" do
      it "passes validation if the alias refers to an existing tag" do
        tag = create(:tag)
        tag.alias_for = tag.name
        expect(tag).to be_valid
      end

      it "fails validation if the alias does not refer to an existing tag" do
        tag.alias_for = "hello"
        expect(tag).not_to be_valid
      end
    end
  end

  it "turns markdown into HTML before saving" do
    tag.rules_markdown = "Hello [Google](https://google.com)"
    tag.save
    expect(tag.rules_html.include?("href")).to be(true)
  end

  it "marks as updated after save" do
    tag.save
    expect(tag.reload.updated_at).to be > 1.minute.ago
  end

  it "knows class valid categories" do
    expect(described_class.valid_categories).to include("tool")
  end

  it "triggers cache busting on save" do
    sidekiq_assert_enqueued_with(job: Tags::BustCacheWorker, args: [tag.name]) do
      tag.save
    end
  end

  it "finds mod chat channel" do
    channel = create(:chat_channel)
    tag.mod_chat_channel_id = channel.id
    expect(tag.mod_chat_channel).to eq(channel)
  end

  describe "#after_commit" do
    it "on update enqueues job to index tag to elasticsearch" do
      tag.save
      sidekiq_assert_enqueued_with(job: Search::IndexWorker, args: [described_class.to_s, tag.id]) do
        tag.save
      end
    end

    it "on destroy enqueues job to delete tag from elasticsearch" do
      tag.save
      sidekiq_assert_enqueued_with(job: Search::RemoveFromIndexWorker, args: [described_class::SEARCH_CLASS.to_s, tag.id]) do
        tag.destroy
      end
    end

    it "syncs related elasticsearch documents" do
      article = create(:article)
      podcast_episode = create(:podcast_episode)
      tag = described_class.find(article.tags.first.id)
      podcast_episode.tags << tag
      reaction = create(:reaction, reactable: article, category: "readinglist")
      new_keywords = "keyword1, keyword2, keyword3"
      sidekiq_perform_enqueued_jobs

      tag.update(keywords_for_search: new_keywords)
      sidekiq_perform_enqueued_jobs
      expect(collect_keywords(article)).to include(new_keywords)
      expect(
        reaction.elasticsearch_doc.dig("_source", "reactable", "tags").flat_map { |t| t["keywords_for_search"] },
      ).to include(new_keywords)
      expect(collect_keywords(podcast_episode)).to include(new_keywords)
    end
  end

  describe "::aliased_name" do
    it "returns the preferred alias tag" do
      preferred_tag = create(:tag, name: "rails")
      bad_tag = create(:tag, name: "ror", alias_for: "rails")
      expect(described_class.aliased_name(bad_tag.name)).to eq(preferred_tag.name)
    end

    it "returns self if there's no preferred alias" do
      tag = create(:tag, name: "ror")
      expect(described_class.aliased_name(tag.name)).to eq(tag.name)
    end

    it "returns nil for non-existing tag" do
      expect(described_class.aliased_name("faketag")).to be_nil
    end
  end

  describe "::find_preferred_alias_for" do
    it "returns preferred tag" do
      preferred_tag = create(:tag, name: "rails")
      tag = create(:tag, name: "ror", alias_for: "rails")
      expect(described_class.find_preferred_alias_for(tag.name)).to eq(preferred_tag.name)
    end

    it "returns self if there's no preferred tag" do
      expect(described_class.find_preferred_alias_for("something")).to eq("something")
    end
  end

  def collect_keywords(record)
    record.elasticsearch_doc.dig("_source", "tags").flat_map { |t| t["keywords_for_search"] }
  end
end
