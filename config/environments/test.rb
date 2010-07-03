# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
config.active_record.schema_format = :sql

config.gem "rspec", :version => ">= 1.2.9", :lib => false
config.gem "rspec-rails", :version => ">= 1.2.9", :lib => false
config.gem "shoulda", :version => ">= 2.10.2", :lib => false, :source => "http://gemcutter.org"
config.gem "cucumber", :version => ">= 0.4.4"
config.gem "spork", :version => ">= 0.7.4"
config.gem "factory_girl", :version => ">= 1.2.3", :source => "http://gemcutter.org"
config.gem "webrat", :version => ">= 0.6.0", :source => "http://gemcutter.org"
config.gem "rcov", :version => ">= 0.9.6"
config.gem "faker", :version => ">= 0.3.1"

S3_OWNER_ID = '5e2767987f2cf4cec03c2c653567c8547b96f77e2744b68f2462fe04520e9de0'
S3_OWNER_DISPLAY_NAME = 'seerdata'
