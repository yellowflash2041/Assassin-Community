require "rails_helper"

RSpec.describe "feedback_messages", type: :request do
  describe "POST /feedback_messages" do
    def mock_recaptcha_verification
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(FeedbackMessagesController).to(
        receive(:recaptcha_verified?).and_return(true),
      )
      # rubocop:enable RSpec/AnyInstance
    end

    valid_abuse_report_params = {
      feedback_message: {
        feedback_type: "abuse-reports",
        category: "rude or vulgar",
        reported_url: "https://dev.to",
        message: "this was vulgar"
      }
    }

    headers = { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }

    context "with valid params" do
      before do
        mock_recaptcha_verification
      end

      it "creates a feedback message" do
        expect do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end.to change(FeedbackMessage, :count).by(1)

        feedback_message = FeedbackMessage.last
        expect(feedback_message.message).to eq(
          valid_abuse_report_params[:feedback_message][:message],
        )
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "with invalid recaptcha" do
      it "rerenders page" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers
        expect(response.body).to include("Make sure the forms are filled")
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "when rate limit is reached" do
      it "returns a 429" do
        user = create(:user)
        limiter = user.rate_limiter
        allow(RateLimitChecker).to receive(:new) { limiter }
        allow(limiter).to receive(:limit_by_action).and_return(true)

        post "/feedback_messages", params: valid_abuse_report_params, headers: headers
        expect(response.status).to eq(429)
      end
    end

    context "when a user submits a report" do
      let(:user) { create(:user) }

      before do
        mock_recaptcha_verification

        sign_in user
      end

      it "creates a feedback message reported by the user" do
        post feedback_messages_path, params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.exists?(reporter_id: user.id)).to be(true)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end
    end

    context "when an anonymous user submits a report" do
      before do
        mock_recaptcha_verification
      end

      it "does not add any user as the reporter" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        expect(FeedbackMessage.last.reporter).to be(nil)
      end

      it "queues a slack message to be sent" do
        sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
          post feedback_messages_path, params: valid_abuse_report_params, headers: headers
        end
      end

      it "redirects to the index page" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        expect(response).to redirect_to(feedback_messages_path)
      end

      it "redirects and continues to the index page with the correct message" do
        post "/feedback_messages", params: valid_abuse_report_params, headers: headers

        follow_redirect!

        expect(response.body).to include("Thank you for your report.")
      end
    end
  end
end
