Rails.application.configure do
  # SMTP — vendor-agnostic, configured via env vars.
  # Works with Mailtrap, SendGrid, Mailgun, Postmark, etc.
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV["SMTP_ADDRESS"],
      port:                 ENV["SMTP_PORT"],
      user_name:            ENV["SMTP_USERNAME"],
      password:             ENV["SMTP_PASSWORD"],
      authentication:       ENV["SMTP_AUTH"].to_sym, # Converts 'login' string to :login symbol
      enable_starttls_auto: true
    }
  end

  config.action_mailer.default_url_options = {
    host: ENV.fetch("MAILER_HOST", "localhost"),
    port: ENV.fetch("MAILER_PORT", 3000).to_i
  }
end
