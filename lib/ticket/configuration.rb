module Ticket
  class Configuration
    # "owner/name" of the repository the issues go to.
    attr_accessor :repository

    # A token allowed to create issues in that repository. Without one, reports are kept but not sent.
    attr_accessor :github_token

    # Labels added to every issue, before the one for the kind of report.
    attr_accessor :labels

    # Called in the controller and the view; returns the person reporting, or nil to hide the widget.
    attr_accessor :current_reporter

    # How a reporter is named in the issue. Gets the object current_reporter returned.
    attr_accessor :reporter_name

    # The host controller the engine's controller inherits from, for its authentication.
    attr_accessor :parent_controller

    # The deployed version, shown in the issue. A string or a lambda.
    attr_accessor :app_version

    # The largest screenshot accepted, in bytes.
    attr_accessor :max_screenshot_size

    def initialize
      @labels = [ "feedback" ]
      @current_reporter = -> { nil }
      @reporter_name = ->(reporter) { reporter.try(:name).presence || reporter.try(:email_address) || reporter.to_s }
      @parent_controller = "::ApplicationController"
      @app_version = -> { ENV["KAMAL_VERSION"] || ENV["GIT_REVISION"] }
      @max_screenshot_size = 8.megabytes
    end

    def deliver?
      repository.present? && github_token.present?
    end
  end
end
