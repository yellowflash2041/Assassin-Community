require "rails_helper"

RSpec.describe ForemInstance, type: :model do
  describe "deployed_at" do
    before { allow(ENV).to receive(:[]) }

    after do
      described_class.instance_variable_set(:@deployed_at, nil)
    end

    it "sets the RELEASE_FOOTPRINT if present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("A deploy date")
      expect(described_class.deployed_at).to eq(ApplicationConfig["RELEASE_FOOTPRINT"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("")
      allow(ENV).to receive(:[]).with("HEROKU_RELEASE_CREATED_AT").and_return("A deploy date set on Heroku")
      expect(described_class.deployed_at).to eq(ENV["HEROKU_RELEASE_CREATED_AT"])
    end
  end

  describe "latest_commit_id" do
    before do
      described_class.instance_variable_set(:@latest_commit_id, nil)
    end

    it "sets the FOREM_BUILD_SHA if present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("A commit id")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => ""))
      expect(described_class.latest_commit_id).to eq(ApplicationConfig["FOREM_BUILD_SHA"])
    end

    it "sets the HEROKU_RELEASE_CREATED_AT if the RELEASE_FOOTPRINT is not present" do
      allow(ApplicationConfig).to receive(:[]).with("FOREM_BUILD_SHA").and_return("")
      stub_const("ENV", ENV.to_h.merge("HEROKU_SLUG_COMMIT" => "A Commit ID set from Heroku"))
      expect(described_class.latest_commit_id).to eq(ENV["HEROKU_SLUG_COMMIT"])
    end
  end
end
