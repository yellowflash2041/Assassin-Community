require "rails_helper"

RSpec.describe Notifications::Reactions::Send, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:user2) { create(:user) }
  let(:article_reaction) { create(:reaction, reactable: article, user: user2) }
  let(:user3) { create(:user) }

  def reaction_data(reaction)
    {
      reactable_id: reaction.reactable_id,
      reactable_type: reaction.reactable_type,
      reactable_user_id: reaction.reactable.user_id
    }
  end

  context "when a reaction is ok" do
    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), user)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      notification = described_class.call(reaction_data(article_reaction), user)
      expect(notification.user_id).to eq(user.id)
      expect(notification.notifiable).to eq(article)
    end

    it "creates a notification with the correct json" do
      notification = described_class.call(reaction_data(article_reaction), user)
      expect(notification.json_data["user"]["id"]).to eq(user2.id)
      expect(notification.json_data["user"]["name"]).to eq(user2.name)
      expect(notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      expect(notification.json_data["reaction"]["aggregated_siblings"].size).to eq(1)
    end
  end

  context "when a reaction is persisted and has siblings" do
    before do
      create(:reaction, reactable: article, user: user3)
    end

    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), user)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      notification = described_class.call(reaction_data(article_reaction), user)
      expect(notification.notifiable).to eq(article)
      expect(notification.notified_at).not_to be_nil
    end

    it "creates a notification with the correct json" do
      notification = described_class.call(reaction_data(article_reaction), user)
      expect(notification.json_data["user"]["id"]).to eq(user2.id)
      expect(notification.json_data["user"]["name"]).to eq(user2.name)
      expect(notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      expect(notification.json_data["reaction"]["aggregated_siblings"].size).to eq(2)
      expect(notification.json_data["reaction"]["aggregated_siblings"].map { |s| s["user"]["id"] }.sort).to eq([user2.id, user3.id].sort)
    end

    context "when notification exists" do
      let!(:old_notification) { create(:notification, user: user, notifiable: article, action: "Reaction") }

      before do
        old_notification.update_column(:notified_at, Time.now - 1.day)
      end

      it "doesn't change notifications count" do
        expect do
          described_class.call(reaction_data(article_reaction), user)
        end.not_to change(Notification, :count)
      end

      it "returns the same notification" do
        notification = described_class.call(reaction_data(article_reaction), user)
        expect(notification.id).to eq(old_notification.id)
      end

      it "updates the notification" do
        now = Time.now
        described_class.call(reaction_data(article_reaction), user)
        old_notification.reload
        expect(old_notification.notified_at).to be >= now
      end

      it "updates the notification json" do
        described_class.call(reaction_data(article_reaction), user)
        old_notification.reload
        expect(old_notification.json_data["user"]["id"]).to eq(user2.id)
        expect(old_notification.json_data["user"]["name"]).to eq(user2.name)
        expect(old_notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      end
    end
  end

  context "when a reaction is destroyed" do
    let(:destroyed_reaction) { article_reaction.destroy }
    let(:notification) { create(:notification, user: user, notifiable: article, action: "Reaction") }

    it "doesn't change notifications count" do
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.not_to change(Notification, :count)
    end

    it "destroys the notification if it exists" do
      notification
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.to change(Notification, :count).by(-1)
    end

    it "destroys the correct notification if it exists" do
      notification
      described_class.call(reaction_data(destroyed_reaction), user)
      expect(Notification.where(id: notification.id)).not_to be_any
    end
  end

  context "when a reaction is destroyed but it has siblings" do
    let(:destroyed_reaction) { article_reaction.destroy }
    let!(:notification) { create(:notification, user: user, notifiable: article, action: "Reaction") }

    before do
      create(:reaction, reactable: article, user: user3)
    end

    it "does not destroy or create notifications" do
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.not_to change(Notification, :count)
    end

    it "keeps the notification" do
      described_class.call(reaction_data(destroyed_reaction), user)
      notification.reload
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["user"]["id"]).to eq(user3.id)
      expect(notification.json_data["user"]["username"]).to eq(user3.username)
      expect(notification.json_data["reaction"]["aggregated_siblings"].map { |s| s["user"]["id"] }).to eq([user3.id])
    end
  end

  context "when a receiver is an organization" do
    let(:organization) { create(:organization) }

    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), organization)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      notification = described_class.call(reaction_data(article_reaction), organization)
      expect(notification.organization_id).to eq(organization.id)
      expect(notification.user_id).to be_nil
      expect(notification.notifiable).to eq(article)
    end
  end
end
