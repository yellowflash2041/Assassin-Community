require "rails_helper"

RSpec.describe "Api::V0::Analytics", type: :request do
  describe "GET /api/analytics/totals" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "totals"
  end

  describe "GET /api/analytics/historical" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "historical", "&start=2019-03-29"

    context "when the start parameter is not included" do
      before { get "/api/analytics/historical" }

      it "renders a status of 422" do
        expect(response.status).to eq 422
      end

      it "renders the proper error message in JSON" do
        error_message = "Required 'start' parameter is missing"
        expect(JSON.parse(response.body)["error"]).to eq error_message
      end
    end

    context "when the start parameter has the incorrect format" do
      before { get "/api/analytics/historical?start=2019/2/2" }

      it "renders a status of 422" do
        expect(response.status).to eq 422
      end

      it "renders the proper error message in JSON" do
        error_message = "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'"
        expect(JSON.parse(response.body)["error"]).to eq error_message
      end
    end
  end

  describe "GET /api/analytics/past_day" do
    include_examples "GET /api/analytics/:endpoint authorization examples", "past_day"
  end
end
