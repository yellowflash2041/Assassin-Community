require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user_id: user.id) }

  describe "GET /dashboard" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders user's articles" do
        login_as user
        article
        get "/dashboard"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end
    end

    context "when logged in as a super admin" do
      it "renders the specified user's articles" do
        article
        user
        login_as super_admin
        get "/dashboard/#{user.username}"
        expect(response.body).to include CGI.escapeHTML(article.title)
      end
    end
  end

  describe "GET /dashboard/organization" do
    let(:organization) { create(:organization) }

    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/organization"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders user's organization articles" do
        user.update(organization_id: organization.id, org_admin: true)
        article.update(organization_id: organization.id)
        login_as user
        get "/dashboard/organization"
        expect(response.body).to include "#{CGI.escapeHTML(organization.name)} ("
      end
    end
  end

  describe "GET /dashboard/following_users" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/following_users"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders the current user's followings" do
        user.follow second_user
        login_as user
        get "/dashboard/following_users"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
      it "renders the current user's tag followings" do
        user.follow second_user
        tag = create(:tag)
        user.follow tag
        login_as user
        get "/dashboard/following"
        expect(response.body).to include CGI.escapeHTML(tag.name)
      end
    end
  end

  describe "GET /dashboard/user_followers" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/user_followers"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged in" do
      it "renders the current user's followers" do
        second_user.follow user
        login_as user
        get "/dashboard/user_followers"
        expect(response.body).to include CGI.escapeHTML(second_user.name)
      end
    end
  end

  describe "GET /dashboard/pro" do
    context "when not logged in" do
      it "raises unauthorized" do
        get "/dashboard/pro"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when user does not have permission" do
      it "raises unauthorized" do
        login_as user
        expect { get "/dashboard/pro" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user has pro permission" do
      it "shows page properly" do
        user.add_role(:pro)
        login_as user
        get "/dashboard/pro"
        expect(response.body).to include("pro")
      end
    end
  end
end
