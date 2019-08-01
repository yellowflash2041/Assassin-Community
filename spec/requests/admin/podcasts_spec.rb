require "rails_helper"

RSpec.describe "Admin::Podcasts", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:image_file) { Rails.root.join("spec", "support", "fixtures", "images", "image1.jpeg") }

  before do
    sign_in super_admin
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        title: "Developer Tea",
        description: "Super Podcast",
        feed_url: "http://feeds.feedburner.com/developertea",
        slug: "devtea",
        published: true,
        main_color_hex: "333333",
        image: Rack::Test::UploadedFile.new(image_file, "image/jpeg")
      }
    end

    it "creates a podcast" do
      expect do
        post "/admin/podcasts", params: { podcast: valid_attributes }
      end.to change(Podcast, :count).by(1)
    end

    it "enqueues a job after creating a podcast" do
      expect do
        post "/admin/podcasts", params: { podcast: valid_attributes }
      end.to have_enqueued_job(Podcasts::GetEpisodesJob).exactly(:once)
    end

    it "doesn't enqueue a job when creating an unpublished podcast" do
      valid_attributes[:published] = false
      expect do
        post "/admin/podcasts", params: { podcast: valid_attributes }
      end.not_to have_enqueued_job(Podcasts::GetEpisodesJob)
    end
  end
end
