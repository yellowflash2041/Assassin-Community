class BadgeAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :badge
  belongs_to :rewarder, class_name: "User", optional: true

  counter_culture :user, column_name: "badge_achievements_count"

  validates :badge_id, uniqueness: { scope: :user_id }

  after_create :notify_recipient
  after_create :send_email_notification
  before_validation :render_rewarding_context_message_html

  def render_rewarding_context_message_html
    return if rewarding_context_message_markdown.blank?

    parsed_markdown = MarkdownParser.new(rewarding_context_message_markdown)
    html = parsed_markdown.finalize
    final_html = ActionController::Base.helpers.sanitize html,
                                                         tags: %w[strong em i b u a code],
                                                         attributes: %w[href name]
    self.rewarding_context_message = final_html
  end

  private

  def notify_recipient
    Notification.send_new_badge_notification(self)
  end

  def send_email_notification
    NotifyMailer.new_badge_email(self).deliver if user.class.name == "User" && user.email.present? && user.email_badge_notifications
  end
  handle_asynchronously :send_email_notification
end
