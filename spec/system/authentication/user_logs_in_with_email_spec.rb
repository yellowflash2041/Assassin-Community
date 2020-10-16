require "rails_helper"

RSpec.describe "Authenticating with Email" do
  let(:sign_in_link) { "Continue" }
  let(:sign_up_link) { "Sign up with Email" }

  before do
    allow(SiteConfig).to receive(:allow_email_password_registration).and_return(true)
    allow(SiteConfig).to receive(:allow_email_password_login).and_return(true)
  end

  context "when a user is new" do
    let(:user) { build(:user) }

    context "when using valid credentials" do
      it "creates a new user", js: true do
        expect do
          visit sign_up_path(state: "new-user")
          click_link(sign_up_link, match: :first)

          fill_in_user(user)
          click_button("Sign up", match: :first)
        end.to change(User, :count).by(1)
      end

      it "logs in and redirects to email confirmation" do
        visit sign_up_path(state: "new-user")
        click_link(sign_up_link, match: :first)

        fill_in_user(user)
        click_button("Sign up", match: :first)

        expect(page).to have_current_path("/confirm-email", ignore_query: true)
      end
    end

    context "when trying to register with an already existing email" do
      it "shows an error" do
        email = "user@test.com"
        user = create(:user, email: email)

        expect do
          visit sign_up_path(state: "new-user")
          click_link(sign_up_link, match: :first)

          fill_in_user(user)
          click_button("Sign up", match: :first)
        end.not_to change(User, :count)

        expect(page).to have_current_path("/users", ignore_query: true)
        expect(page).to have_text("Email has already been taken")
      end
    end

    context "when using invalid credentials" do
      it "does not log in" do
        visit sign_up_path
        fill_in("user_email", with: "foo@bar.com")
        fill_in("user_password", with: "password")
        click_button("Continue", match: :first)

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_text("Invalid Email or password.")
      end
    end
  end

  context "when a user already exists" do
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    after do
      sign_out user
    end

    context "when using valid credentials" do
      it "logs in" do
        visit sign_up_path
        log_in_user(user)

        expect(page).to have_current_path("/?signin=true")
      end
    end

    context "when already signed in" do
      it "redirects to the feed" do
        sign_in user
        visit sign_up_path

        expect(page).to have_current_path("/?signin=true")
      end
    end
  end

  context "when community is in invite only mode" do
    before do
      allow(SiteConfig).to receive(:invite_only_mode).and_return(true)
    end

    it "doesn't present the authentication option" do
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text(sign_in_link)
      expect(page).to have_text("invite only")
    end
  end

  def fill_in_user(user)
    attach_file("user_profile_image", "spec/fixtures/files/podcast.png")
    fill_in("user_name", with: user.name)
    fill_in("user_username", with: user.username)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: "12345678")
    fill_in("user_password_confirmation", with: "12345678")
  end

  def log_in_user(user)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: user.password)
    click_button("Continue", match: :first)
  end
end
