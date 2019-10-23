##
# Custom Audit Instrumentation
#
# Put here all custom listener names, for later usage in Audit Instrumentation
#
# Example:
# Audit::Subscribe.listen :admin, :quest_user

Audit::Subscribe.listen(:moderator, :internal) unless Rails.env.test?
