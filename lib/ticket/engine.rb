module Ticket
  class Engine < ::Rails::Engine
    isolate_namespace Ticket

    # The widget helper is available in every host view, without touching the host's helpers.
    initializer "ticket.helpers" do
      ActiveSupport.on_load(:action_view) { include Ticket::WidgetHelper }
    end
  end
end
