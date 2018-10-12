class NotifyMailer < ApplicationMailer
  def new_reply_email(comment)
    @user = comment.parent_user
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_comment_notifications)
    @comment = comment
    mail(to: @user.email, subject: "#{@comment.user.name} replied to your #{@comment.parent_type}")
  end

  def new_follower_email(follow)
    @user = follow.followable
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @follower = follow.follower
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_follower_notifications)

    mail(to: @user.email, subject: "#{@follower.name} just followed you on dev.to")
  end

  def new_mention_email(mention)
    @user = User.find(mention.user_id)
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @mentioner = User.find(mention.mentionable.user_id)
    @mentionable = mention.mentionable
    @mention = mention
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_mention_notifications)

    mail(to: @user.email, subject: "#{@mentioner.name} just mentioned you!")
  end

  def unread_notifications_email(user)
    @user = user
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @unread_notifications_count = NotificationCounter.new(@user).unread_notification_count
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_unread_notifications)
    subject = "🔥 You have #{@unread_notifications_count} unread notifications on dev.to"
    mail(to: @user.email, subject: subject)
  end

  def video_upload_complete_email(article)
    @article = article
    @user = @article.user
    mail(to: @user.email, subject: "Your video upload is complete")
  end

  def new_badge_email(badge_achievement)
    @badge_achievement = badge_achievement
    @user = @badge_achievement.user
    @badge = @badge_achievement.badge
    mail(to: @user.email, subject: "You just got a badge")
  end

  def feedback_message_resolution_email(params)
    @user = User.find_by(email: params[:email_to])
    @email_body = params[:email_body]
    track utm_campaign: params[:email_type]
    track extra: { feedback_message_id: params[:feedback_message_id] }
    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def new_report_email(report)
    @feedback_message = report
    @user = report.reporter
    mail(to: @user.email, subject: "Thank you for your report")
  end

  def new_message_email(message)
    @message = message
    @user = message.direct_receiver
    subject = "#{message.user.name} just messaged you"
    mail(to: @user.email, subject: subject)
  end

  def reporter_resolution_email(report)
    @feedback_message = report
    @user = report.reporter
  end

  def account_deleted_email(user)
    @name = user.name
    subject = "dev.to - Account Deletion Confirmation"
    mail(to: user.email, subject: subject)
  end

  def mentee_email(mentee, mentor)
    @mentee = mentee
    @mentor = mentor
    subject = "You have been matched with a DEV mentor!"
    mail(to: @mentee.email, subject: subject)
  end

  def mentor_email(mentor, mentee)
    @mentor = mentor
    @mentee = mentee
    subject = "You have been matched with a new DEV mentee!"
    mail(to: @mentor.email, subject: subject)
  end
end
