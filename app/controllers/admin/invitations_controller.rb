module Admin
  class InvitationsController < Admin::ApplicationController
    layout "admin"

    def index
      @invitations = Admin::UsersQuery.call(relation: User.invited,
                                            options: params.permit(
                                              :search,
                                            )).page(params[:page]).per(50)
    end

    def new; end

    def create
      email = params.dig(:user, :email)
      name = params.dig(:user, :name)

      if User.exists?(email: email.downcase, registered: true)
        flash[:error] = "Invitation was not sent. There is already a registered user with the email: #{email}"
        redirect_to admin_invitations_path
        return
      end

      username = "#{name.downcase.tr(' ', '_').gsub(/[^0-9a-z ]/i, '')}_#{rand(1000)}"
      User.invite!(email: email,
                   name: name,
                   username: username,
                   remote_profile_image_url: ::Users::ProfileImageGenerator.call,
                   registered: false)
      flash[:success] = t("admin.invitations_controller.create_success")
      redirect_to admin_invitations_path
    end

    def destroy
      @invitation = User.where(registered: false).find(params[:id])
      if @invitation.destroy
        flash[:success] = t("admin.invitations_controller.destroy_success", email: @invitation.email)
      else
        flash[:danger] = @invitation.errors_as_sentence
      end
      redirect_to admin_invitations_path
    end

    def resend
      @invited_user = User.where(registered: false).find(params[:id])
      if @invited_user.invite!
        flash[:success] = t("admin.invitations_controller.resend_success", email: @invited_user.email)
      else
        flash[:danger] = @invited_user.errors_as_sentence
      end
      redirect_to admin_invitations_path
    end
  end
end
