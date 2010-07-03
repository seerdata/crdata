# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_starter_session',
  :secret      => '04cdb3295210330b0caa92e041e92f71999d7350591f19023c10d061a3835f410b22d17f58b1cfdcdd1a9fbbcfe87bbd49d0cbd462c9e0c8fc433241bfc37bc0'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
