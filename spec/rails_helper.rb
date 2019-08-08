ENV["RAILS_ENV"] = "test"

require "spec_helper"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Add additional requires below this line. Rails is not loaded until this point!

require "algolia/webmock"
require "pundit/matchers"
require "pundit/rspec"
require "webmock/rspec"
require "test_prof/recipes/rspec/before_all"
require "test_prof/recipes/rspec/let_it_be"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.

Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }
Dir[Rails.root.join("spec", "system", "shared_examples", "**", "*.rb")].each { |f| require f }
Dir[Rails.root.join("spec", "models", "shared_examples", "**", "*.rb")].each { |f| require f }
Dir[Rails.root.join("spec", "jobs", "shared_examples", "**", "*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Disable internet connection with Webmock
# allow browser websites, so that "webdrivers" can access their binaries
# see <https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock>
allowed_sites = [
  "https://chromedriver.storage.googleapis.com",
  "https://github.com/mozilla/geckodriver/releases",
  "https://selenium-release.storage.googleapis.com",
  "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver",
]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites)

# tell VCR to ignore browsers download sites
# see <https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock>
VCR.configure do |config|
  config.ignore_hosts(
    "chromedriver.storage.googleapis.com",
    "github.com/mozilla/geckodriver/releases",
    "selenium-release.storage.googleapis.com",
    "developer.microsoft.com/en-us/microsoft-edge/tools/webdriver",
  )
end

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.include ApplicationHelper
  config.include ActionMailer::TestHelper
  config.include ActiveJob::TestHelper
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.include OmniauthMacros

  config.before do
    ActiveRecord::Base.observers.disable :all # <-- Turn 'em all off!
  end

  # Only turn on VCR if :vcr is included metadata keys
  config.around do |ex|
    if ex.metadata.key?(:vcr)
      ex.run
    else
      VCR.turned_off { ex.run }
    end
  end

  # Allow testing with Stripe's test server. BECAREFUL
  if config.filter_manager.inclusions.rules.include?(:live)
    WebMock.allow_net_connect!
    StripeMock.toggle_live(true)
    Rails.logger.info("Running **live** tests against Stripe...")
  end

  config.before do
    stub_request(:any, /res.cloudinary.com/).to_rack("dsdsdsds")

    stub_request(:post, /api.fastly.com/).
      to_return(status: 200, body: "", headers: {})

    stub_request(:post, /api.bufferapp.com/).
      to_return(status: 200, body: { fake_text: "so fake" }.to_json, headers: {})

    # for twitter image cdn
    stub_request(:get, /twimg.com/).
      to_return(status: 200, body: "", headers: {})

    stub_request(:any, /api.mailchimp.com/).
      to_return(status: 200, body: "", headers: {})
  end

  OmniAuth.config.test_mode = true
  OmniAuth.config.logger = Rails.logger

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Doorkeeper.configure do
  # hash_token_secrets on its own won't work in test
  hash_token_secrets fallback: :plain
end
