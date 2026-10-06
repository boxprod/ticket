require "ticket/version"
require "ticket/configuration"
require "ticket/github"
require "ticket/engine"

# Feedback from the people using an app, filed as GitHub issues in that app's repository.
module Ticket
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # Replaced in tests; anything that answers #create_issue(title:, body:, labels:).
    attr_writer :client

    def client
      @client ||= GitHub.new(token: config.github_token, repository: config.repository)
    end
  end
end
