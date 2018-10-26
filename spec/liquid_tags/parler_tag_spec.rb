require "rails_helper"

RSpec.describe ParlerTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id) { "https://www.parler.io/audio/73240183203/d53cff009eac2ab1bc9dd8821a638823c39cbcea.7dd28611-b7fc-4cf8-9977-b6e3aaf644a1.mp3" }

    let(:invalid_id) { "https://www.google.com" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("parler", ParlerTag)
      Liquid::Template.parse("{% parler #{id} %}")
    end

    def generate_iframe(_id)
      "<iframe "\
        "width=\"710\" "\
        "height=\"120\" "\
        "src=\"https://api.parler.io/ss/player?url=#{valid_id}\"> "\
      "</iframe>"
    end

    it "accepts a valid Parler URL" do
      liquid = generate_new_liquid(valid_id)
      expect(liquid.render).to eq(generate_iframe(valid_id))
    end

    it "raises an error for invalid IDs" do
      expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid Parler URL")
    end
  end
end
