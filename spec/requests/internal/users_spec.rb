require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let!(:user) do
    omniauth_mock_github_payload
    create(:user, :with_identity, identities: ["github"])
  end
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GETS /internal/users" do
    it "renders to appropriate page" do
      get "/internal/users"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /internal/users/:id" do
    it "renders to appropriate page" do
      get "/internal/users/#{user.id}"
      expect(response.body).to include(user.username)
    end
  end

  describe "GET /internal/users/:id/edit" do
    it "redirects from /username/moderate" do
      get "/#{user.username}/moderate"
      expect(response).to redirect_to("/internal/users/#{user.id}")
    end

    it "shows banish button for new users" do
      get "/internal/users/#{user.id}/edit"
      expect(response.body).to include("Banish User for Spam!")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get "/internal/users/#{user.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST /internal/users/:id/banish" do
    it "bans user for spam" do
      allow(Moderator::BanishUserWorker).to receive(:perform_async)
      post "/internal/users/#{user.id}/banish"
      expect(Moderator::BanishUserWorker).to have_received(:perform_async).with(admin.id, user.id)
      expect(request.flash[:success]).to include("This user is being banished in the background")
    end
  end

  describe "POST internal/users/:id/verify_email_ownership" do
    it "allows a user to verify email ownership" do
      post "/internal/users/#{user.id}/verify_email_ownership", params: { user_id: user.id }
      verification_link = app_url(verify_email_authorizations_path(confirmation_token: user.email_authorizations.first.confirmation_token, username: user.username))
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Verify Your #{ApplicationConfig['COMMUNITY_NAME']} Account Ownership")
      expect(ActionMailer::Base.deliveries.first.text_part.body).to include(verification_link)

      sign_in(user)
      get verification_link
      expect(user.email_authorizations.last.verified_at).to be_within(1.minute).of Time.now.utc

      ActionMailer::Base.deliveries.clear
    end
  end

  describe "DELETE /internal/users/:id/remove_identity" do
    it "removes the given identity" do
      identity = user.identities.first
      delete "/internal/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect { identity.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "updates their social account's username to nil" do
      identity = user.identities.first
      delete "/internal/users/#{user.id}/remove_identity", params: { user: { identity_id: identity.id } }
      expect(user.reload.github_username).to eq nil
    end
  end

  describe "POST internal/users/:id/recover_identity" do
    it "recovers a deleted identity" do
      identity = user.identities.first
      backup = BackupData.backup!(identity)
      identity.delete
      post "/internal/users/#{user.id}/recover_identity", params: { user: { backup_data_id: backup.id } }
      expect(identity).to eq Identity.first
    end

    it "deletes the backup data" do
      identity = user.identities.first
      backup = BackupData.backup!(identity)
      identity.delete
      post "/internal/users/#{user.id}/recover_identity", params: { user: { backup_data_id: backup.id } }
      expect { backup.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
