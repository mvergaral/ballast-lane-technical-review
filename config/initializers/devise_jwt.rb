Devise::JWT.configure do |config|
  config.secret = Rails.application.credentials.secret_key_base
  config.dispatch_requests = [
    ['POST', %r{^/api/auth/login$}],
    ['POST', %r{^/api/auth/register$}]
  ]
  config.revocation_requests = [
    ['DELETE', %r{^/api/auth/logout$}]
  ]
  config.expiration_time = 1.day.to_i
end
