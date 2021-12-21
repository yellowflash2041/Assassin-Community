class LiquidTagBase < Liquid::Tag
  # The method name to send the user to ask whether or not they
  # have access to the given liquid tag.
  #
  # @see LiquidTagPolicy
  #
  # @note My preference would be to use `class_attribute` as it keeps
  #       things tidier, but that's not a hard preference.
  #
  # @note Should we verify that the user responds to this given method?
  def self.user_authorization_method_name
    nil
  end

  def self.script
    ""
  end

  def initialize(_tag_name, _content, parse_context)
    super
    validate_contexts
    # This check issues DB queries so we keep it as the last one
    Pundit.authorize(
      parse_context.partial_options[:user],
      self,
      :initialize?,
      policy_class: LiquidTagPolicy,
    )
  end

  def strip_tags(string)
    ActionController::Base.helpers.strip_tags(string).strip
  end

  def pattern_match_for(input, regex_options)
    regex_options
      .filter_map { |regex| input.match(regex) }
      .first
  end

  # A method to help collaborators not need to reach into the class
  # implementation details.
  def user_authorization_method_name
    self.class.user_authorization_method_name
  end

  private

  def validate_contexts
    return unless self.class.const_defined? "VALID_CONTEXTS"

    source = parse_context.partial_options[:source]
    raise LiquidTags::Errors::InvalidParseContext, "No source found" unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class.name
    return if is_valid_source

    valid_contexts = self.class::VALID_CONTEXTS.map(&:pluralize).join(", ")
    invalid_source_error_msg = "Invalid context. This liquid tag can only be used in #{valid_contexts}."
    raise LiquidTags::Errors::InvalidParseContext, invalid_source_error_msg
  end
end
