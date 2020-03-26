require "rails_helper"

RSpec.describe "/internal/response_templates", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /internal/response_templates" do
    it "renders with status 200" do
      get "/internal/response_templates"
      expect(response.status).to eq 200
    end

    context "when there are response templates to render" do
      it "renders with status 200" do
        create(:response_template)
        get "/internal/response_templates"
        expect(response.status).to eq 200
      end
    end
  end

  describe "GET /internal/response_templates/new" do
    it "renders with status 200" do
      get "/internal/response_templates"
      expect(response.status).to eq 200
    end
  end

  describe "POST /internal/response_templates" do
    it "successfully creates a response template" do
      post "/internal/response_templates", params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "body_markdown",
          content: "nice job!",
          title: "something"
        }
      }
      expect(ResponseTemplate.count).to eq 1
    end

    it "shows a proper error message if the request was invalid" do
      post "/internal/response_templates", params: {
        response_template: {
          type_of: "mod_comment",
          content_type: "html",
          content: "nice job!",
          title: "something"
        }
      }
      expect(response.body).to include(ResponseTemplate::COMMENT_VALIDATION_MSG)
    end
  end

  describe "GET /internal/response_templates/:id/edit" do
    let(:response_template) { create(:response_template) }

    it "renders successfully if a valid response template was found" do
      get "/internal/response_templates/#{response_template.id}/edit"
      expect(response).to have_http_status(:ok)
    end

    it "renders the response template's attributes" do
      get "/internal/response_templates/#{response_template.id}/edit"

      expect(response.body).to include(
        CGI.escapeHTML(response_template.content),
        CGI.escapeHTML(response_template.title),
        response_template.content_type,
        response_template.type_of,
      )
    end
  end

  describe "PATCH /internal/response_templates/:id" do
    it "successfully updates with a valid request" do
      response_template = create(:response_template)
      new_title = generate(:title)
      patch "/internal/response_templates/#{response_template.id}", params: {
        response_template: {
          title: new_title
        }
      }
      expect(response_template.reload.title).to eq new_title
    end

    it "renders an error if the request was invalid" do
      response_template = create(:response_template)
      patch "/internal/response_templates/#{response_template.id}", params: {
        response_template: {
          content_type: "html"
        }
      }
      expect(response.body).to include(ResponseTemplate::COMMENT_VALIDATION_MSG)
    end
  end

  describe "DELETE /internal/response_templates/:id" do
    it "successfully deletes the response template" do
      response_template = create(:response_template)
      delete "/internal/response_templates/#{response_template.id}"
      expect { response_template.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
