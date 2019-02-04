require "rails_helper"

RSpec.describe "HtmlVariantSuccesses", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, approved: true) }
  let(:html_variant) { create(:html_variant) }

  describe "POST /html_variant_successes" do
    it "rejects non-permissioned user" do
      run_background_jobs_immediately do
        post "/html_variant_successes", params: {
          article_id: article.id,
          html_variant_id: html_variant.id
        }
      end
      expect(HtmlVariantSuccess.all.size).to eq(1)
    end
  end
end
