# -*- encoding: utf-8 -*-
# stub: devise 4.7.3 ruby lib

Gem::Specification.new do |s|
  s.name = "devise".freeze
  s.version = "4.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jos\u00E9 Valim".freeze, "Carlos Ant\u00F4nio".freeze]
  s.date = "2021-02-18"
  s.description = "Flexible authentication solution for Rails with Warden".freeze
  s.email = "heartcombo@googlegroups.com".freeze
  s.files = ["CHANGELOG.md".freeze, "MIT-LICENSE".freeze, "README.md".freeze, "app/controllers/devise".freeze, "app/controllers/devise/confirmations_controller.rb".freeze, "app/controllers/devise/omniauth_callbacks_controller.rb".freeze, "app/controllers/devise/passwords_controller.rb".freeze, "app/controllers/devise/registrations_controller.rb".freeze, "app/controllers/devise/sessions_controller.rb".freeze, "app/controllers/devise/unlocks_controller.rb".freeze, "app/controllers/devise_controller.rb".freeze, "app/helpers/devise_helper.rb".freeze, "app/mailers/devise".freeze, "app/mailers/devise/mailer.rb".freeze, "app/views/devise/confirmations/new.html.erb".freeze, "app/views/devise/mailer/confirmation_instructions.html.erb".freeze, "app/views/devise/mailer/email_changed.html.erb".freeze, "app/views/devise/mailer/password_change.html.erb".freeze, "app/views/devise/mailer/reset_password_instructions.html.erb".freeze, "app/views/devise/mailer/unlock_instructions.html.erb".freeze, "app/views/devise/passwords/edit.html.erb".freeze, "app/views/devise/passwords/new.html.erb".freeze, "app/views/devise/registrations/edit.html.erb".freeze, "app/views/devise/registrations/new.html.erb".freeze, "app/views/devise/sessions/new.html.erb".freeze, "app/views/devise/shared/_error_messages.html.erb".freeze, "app/views/devise/shared/_links.html.erb".freeze, "app/views/devise/unlocks/new.html.erb".freeze, "config/locales/en.yml".freeze, "lib/devise".freeze, "lib/devise.rb".freeze, "lib/devise/controllers".freeze, "lib/devise/controllers/helpers.rb".freeze, "lib/devise/controllers/rememberable.rb".freeze, "lib/devise/controllers/scoped_views.rb".freeze, "lib/devise/controllers/sign_in_out.rb".freeze, "lib/devise/controllers/store_location.rb".freeze, "lib/devise/controllers/url_helpers.rb".freeze, "lib/devise/delegator.rb".freeze, "lib/devise/encryptor.rb".freeze, "lib/devise/failure_app.rb".freeze, "lib/devise/hooks".freeze, "lib/devise/hooks/activatable.rb".freeze, "lib/devise/hooks/csrf_cleaner.rb".freeze, "lib/devise/hooks/forgetable.rb".freeze, "lib/devise/hooks/lockable.rb".freeze, "lib/devise/hooks/proxy.rb".freeze, "lib/devise/hooks/rememberable.rb".freeze, "lib/devise/hooks/timeoutable.rb".freeze, "lib/devise/hooks/trackable.rb".freeze, "lib/devise/mailers".freeze, "lib/devise/mailers/helpers.rb".freeze, "lib/devise/mapping.rb".freeze, "lib/devise/models".freeze, "lib/devise/models.rb".freeze, "lib/devise/models/authenticatable.rb".freeze, "lib/devise/models/confirmable.rb".freeze, "lib/devise/models/database_authenticatable.rb".freeze, "lib/devise/models/lockable.rb".freeze, "lib/devise/models/omniauthable.rb".freeze, "lib/devise/models/recoverable.rb".freeze, "lib/devise/models/registerable.rb".freeze, "lib/devise/models/rememberable.rb".freeze, "lib/devise/models/timeoutable.rb".freeze, "lib/devise/models/trackable.rb".freeze, "lib/devise/models/validatable.rb".freeze, "lib/devise/modules.rb".freeze, "lib/devise/omniauth".freeze, "lib/devise/omniauth.rb".freeze, "lib/devise/omniauth/config.rb".freeze, "lib/devise/omniauth/url_helpers.rb".freeze, "lib/devise/orm".freeze, "lib/devise/orm/active_record.rb".freeze, "lib/devise/orm/mongoid.rb".freeze, "lib/devise/parameter_filter.rb".freeze, "lib/devise/parameter_sanitizer.rb".freeze, "lib/devise/rails".freeze, "lib/devise/rails.rb".freeze, "lib/devise/rails/deprecated_constant_accessor.rb".freeze, "lib/devise/rails/routes.rb".freeze, "lib/devise/rails/warden_compat.rb".freeze, "lib/devise/secret_key_finder.rb".freeze, "lib/devise/strategies".freeze, "lib/devise/strategies/authenticatable.rb".freeze, "lib/devise/strategies/base.rb".freeze, "lib/devise/strategies/database_authenticatable.rb".freeze, "lib/devise/strategies/rememberable.rb".freeze, "lib/devise/test".freeze, "lib/devise/test/controller_helpers.rb".freeze, "lib/devise/test/integration_helpers.rb".freeze, "lib/devise/test_helpers.rb".freeze, "lib/devise/time_inflector.rb".freeze, "lib/devise/token_generator.rb".freeze, "lib/devise/version.rb".freeze, "lib/generators/active_record".freeze, "lib/generators/active_record/devise_generator.rb".freeze, "lib/generators/active_record/templates".freeze, "lib/generators/active_record/templates/migration.rb".freeze, "lib/generators/active_record/templates/migration_existing.rb".freeze, "lib/generators/devise".freeze, "lib/generators/devise/controllers_generator.rb".freeze, "lib/generators/devise/devise_generator.rb".freeze, "lib/generators/devise/install_generator.rb".freeze, "lib/generators/devise/orm_helpers.rb".freeze, "lib/generators/devise/views_generator.rb".freeze, "lib/generators/mongoid".freeze, "lib/generators/mongoid/devise_generator.rb".freeze, "lib/generators/templates".freeze, "lib/generators/templates/README".freeze, "lib/generators/templates/controllers".freeze, "lib/generators/templates/controllers/README".freeze, "lib/generators/templates/controllers/confirmations_controller.rb".freeze, "lib/generators/templates/controllers/omniauth_callbacks_controller.rb".freeze, "lib/generators/templates/controllers/passwords_controller.rb".freeze, "lib/generators/templates/controllers/registrations_controller.rb".freeze, "lib/generators/templates/controllers/sessions_controller.rb".freeze, "lib/generators/templates/controllers/unlocks_controller.rb".freeze, "lib/generators/templates/devise.rb".freeze, "lib/generators/templates/markerb".freeze, "lib/generators/templates/markerb/confirmation_instructions.markerb".freeze, "lib/generators/templates/markerb/email_changed.markerb".freeze, "lib/generators/templates/markerb/password_change.markerb".freeze, "lib/generators/templates/markerb/reset_password_instructions.markerb".freeze, "lib/generators/templates/markerb/unlock_instructions.markerb".freeze, "lib/generators/templates/simple_form_for".freeze, "lib/generators/templates/simple_form_for/confirmations".freeze, "lib/generators/templates/simple_form_for/confirmations/new.html.erb".freeze, "lib/generators/templates/simple_form_for/passwords".freeze, "lib/generators/templates/simple_form_for/passwords/edit.html.erb".freeze, "lib/generators/templates/simple_form_for/passwords/new.html.erb".freeze, "lib/generators/templates/simple_form_for/registrations".freeze, "lib/generators/templates/simple_form_for/registrations/edit.html.erb".freeze, "lib/generators/templates/simple_form_for/registrations/new.html.erb".freeze, "lib/generators/templates/simple_form_for/sessions".freeze, "lib/generators/templates/simple_form_for/sessions/new.html.erb".freeze, "lib/generators/templates/simple_form_for/unlocks".freeze, "lib/generators/templates/simple_form_for/unlocks/new.html.erb".freeze]
  s.homepage = "https://github.com/heartcombo/devise".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Flexible authentication solution for Rails with Warden".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<warden>.freeze, ["~> 1.2.3"])
    s.add_runtime_dependency(%q<orm_adapter>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<bcrypt>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<railties>.freeze, [">= 4.1.0"])
    s.add_runtime_dependency(%q<responders>.freeze, [">= 0"])
  else
    s.add_dependency(%q<warden>.freeze, ["~> 1.2.3"])
    s.add_dependency(%q<orm_adapter>.freeze, ["~> 0.1"])
    s.add_dependency(%q<bcrypt>.freeze, ["~> 3.0"])
    s.add_dependency(%q<railties>.freeze, [">= 4.1.0"])
    s.add_dependency(%q<responders>.freeze, [">= 0"])
  end
end