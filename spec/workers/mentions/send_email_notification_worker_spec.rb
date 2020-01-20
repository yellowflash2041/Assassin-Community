require "rails_helper"

RSpec.describe Mentions::SendEmailNotificationWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "default", 1

  describe "#perform" do
    let(:worker) { subject }
    let(:user) { create(:user) }
    let(:mention) { create(:mention, user_id: user.id, mentionable_id: comment.id, mentionable_type: "Comment") }
    let(:comment) { create(:comment, user_id: user.id, commentable: create(:article)) }

    context "with mention" do
      it "calls on NotifyMailer" do
        worker.perform(mention.id) do
          expect(NotifyMailer).to have_received(:new_mention_email).with(mention)
        end
      end
    end

    context "without a mention" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        worker.perform(nil) do
          expect(NotifyMailer).not_to have_received(:new_mention_email)
        end
      end
    end
  end
end
