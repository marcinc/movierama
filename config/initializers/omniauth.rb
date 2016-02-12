require 'omniauth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :github,
    ENV.fetch('GITHUB_OAUTH_CLIENT_ID'),
    ENV.fetch('GITHUB_OAUTH_SECRET')
end

  configure do |c|
    c.full_host = ENV.fetch('OMNIAUTH_FULL_HOST') if Rails.env.development?
  end
end
