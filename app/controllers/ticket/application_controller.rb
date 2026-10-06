module Ticket
  # Inherits from the host's controller so its authentication, locale and browser rules apply.
  class ApplicationController < Ticket.config.parent_controller.constantize
    private
      def current_reporter
        @current_reporter ||= instance_exec(&Ticket.config.current_reporter)
      end

      def require_reporter
        head :unauthorized unless current_reporter
      end
  end
end
