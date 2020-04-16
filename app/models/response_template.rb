class ResponseTemplate < ApplicationRecord
  resourcify

  belongs_to :user, optional: true

  UNIQUENESS_SCOPE = %i[user_id type_of content_type].freeze
  TYPE_OF_TYPES = %w[personal_comment mod_comment abuse_report_email_reply email_reply tag_adjustment].freeze
  USER_NIL_TYPE_OF_TYPES = %w[mod_comment abuse_report_email_reply email_reply tag_adjustment].freeze
  CONTENT_TYPES = %w[plain_text html body_markdown].freeze
  COMMENT_CONTENT_TYPE = %w[body_markdown].freeze
  EMAIL_CONTENT_TYPES = %w[plain_text html].freeze
  COMMENT_VALIDATION_MSG = "Comment templates must use Markdown as its content type.".freeze
  EMAIL_VALIDATION_MSG = "Email templates must use plain text or HTML as its content type.".freeze
  USER_NIL_TYPE_OF_MSG = "cannot have a user ID associated.".freeze

  validates :type_of, :content_type, :content, :title, presence: true
  validates :content, uniqueness: { scope: UNIQUENESS_SCOPE }
  validates :type_of, inclusion: { in: TYPE_OF_TYPES }
  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :content_type,
            inclusion: { in: COMMENT_CONTENT_TYPE, message: COMMENT_VALIDATION_MSG },
            if: -> { type_of&.include?("comment") }
  validates :content_type,
            inclusion: { in: EMAIL_CONTENT_TYPES, message: EMAIL_VALIDATION_MSG },
            if: -> { type_of&.include?("email") }
  validate :user_nil_only_for_user_nil_types

  def user_nil_only_for_user_nil_types
    if user_id.present? && USER_NIL_TYPE_OF_TYPES.include?(type_of)
      errors.add(:type_of, USER_NIL_TYPE_OF_MSG)
    end
  end
end
