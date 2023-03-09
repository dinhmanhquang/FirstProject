


Devise.setup do |config|
  require 'devise/orm/active_record'
  config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.mailer_sender = 'no-reply@example.com'
  config.stretches = Rails.env.test? ? 1 : 11
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  
  config.remember_for = 24.hours
  
  
  config.password_length = 6..128
  
  
  config.reset_password_within = 1
  
  
  config.maximum_attempts = 10
  
  
  config.unlock_in = 6.hours
  
  
  config.unlock_strategy = :time
  
  config.lock_strategy = :failed_attempts
  config.sign_out_via = :delete
  config.sign_in_after_reset_password = false
  config.confirm_within = 2.days
  config.scoped_views = true
end

