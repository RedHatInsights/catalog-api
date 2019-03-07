def dev_credentials(config)
  # Set up user/pass for basic auth if we're in dev and they exist.
  if Rails.env.development?
    config.username = ENV['DEV_USERNAME'] || raise("Empty ENV variable: DEV_USERNAME")
    config.password = ENV['DEV_PASSWORD'] || raise("Empty ENV variable: DEV_PASSWORD")
  end
end
