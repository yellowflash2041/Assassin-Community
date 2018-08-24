require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_template do
  describe "#id" do
    let(:youtube_id) { "dQw4w9WgXcQ" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("youtube", YoutubeTag)
      Liquid::Template.parse("{% youtube #{id} %}")
    end

    def generate_iframe(id)
      "<iframe "\
        "width=\"710\" "\
        "height=\"399\" "\
        "src=\"https://www.youtube.com/embed/#{id}\" "\
        "allowfullscreen> "\
      "</iframe>"
    end

    it "accepts youtube video id" do
      liquid = generate_new_liquid(youtube_id)
      expect(liquid.render).to eq(generate_iframe(youtube_id))
    end

    it "accepts youtube video id with empty space" do
      liquid = generate_new_liquid(youtube_id + " ")
      expect(liquid.render).to eq(generate_iframe(youtube_id))
    end

    it "accepts youtube video id with start time" do
      liquid = generate_new_liquid(youtube_id + "?t=1m7s")
      expect(liquid.render).to eq(generate_iframe(youtube_id + "?start=67"))
    end
  end
end
