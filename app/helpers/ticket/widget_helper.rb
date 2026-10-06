module Ticket
  # `<%= ticket_widget %>` in the host's layout: the button, for signed-in people only.
  module WidgetHelper
    def ticket_widget
      return unless respond_to?(:ticket) && instance_exec(&Ticket.config.current_reporter)

      safe_join [
        tag.ticket_widget(data: { endpoint: ticket.reports_path, request_id: request&.request_id, strings: t("ticket.widget").to_json }),
        javascript_include_tag("ticket/widget", type: "module", nonce: true)
      ]
    rescue StandardError => error
      # The host's page matters more than the feedback button.
      raise unless Rails.env.production?
      Rails.logger.error("[ticket] widget not rendered: #{error.class}: #{error.message}")
      nil
    end
  end
end
