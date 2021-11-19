# @note While the validator implies a CSV, the implementation is that
#       we have an array.  Upstream implementors likely accept a CSV
#       and coerce it into an array.  See Authentication::Base for an
#       example of coercing the CSV into an array.
class ValidDomainCsvValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "must be a comma-separated list of valid domains".freeze
  VALID_DOMAIN = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$/

  def validate_each(record, attribute, value)
    return unless value

    return if value.all? { |domain| domain.match?(VALID_DOMAIN) }

    record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
  end
end
