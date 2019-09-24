class ProMembershipMailer < ApplicationMailer
  default from: "DEV Pro Memberships <yo@dev.to>"

  def expiring_membership(pro_membership, expiration_date)
    @pro_membership = pro_membership
    @user = pro_membership.user
    @days = (Time.current.to_date..expiration_date.to_date).count - 1
    @date = expiration_date.to_date
    mail(to: @user.email, subject: "Your Pro Membership will expire in #{@days} days!")
  end
end
