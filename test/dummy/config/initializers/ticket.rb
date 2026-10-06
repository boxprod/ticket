Ticket.configure do |config|
  config.repository = "boxprod/dummy"
  config.github_token = "test-token"
  config.current_reporter = -> { Current.user }
end
