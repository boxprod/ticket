module Ticket
  class ReportsController < ApplicationController
    before_action :require_reporter

    def create
      report = Report.new(report_params)
      report.reporter = current_reporter
      report.screenshot_upload = params[:screenshot]
      report.context = context

      if report.save
        report.deliver_later
        render json: { id: report.id }, status: :created
      else
        render json: { errors: report.errors.full_messages }, status: :unprocessable_content
      end
    end

    # The screenshot an issue links to; behind the host's sign-in like any other page.
    def screenshot
      report = Report.find(params[:id])
      return head :not_found unless report.screenshot?

      send_data report.screenshot, type: report.screenshot_content_type, disposition: :inline,
        filename: "ticket-#{report.id}.#{Report::IMAGE_TYPES.fetch(report.screenshot_content_type)}"
    end

    private
      def report_params
        params.permit(:kind, :description, :page_url, :page_title)
      end

      def context
        browser = params.fetch(:browser, {}).permit(:viewport, :screen, :language, :timezone).to_h
        {
          "user_agent" => request.user_agent,
          "request_id" => params[:page_request_id].presence,
          "app_version" => app_version,
          "environment" => Rails.env,
          "engine_url" => request.base_url + request.script_name,
          "browser" => browser,
          "errors" => Array(params[:errors]).first(10).map { |error| error.to_s.first(500) }
        }.compact_blank
      end

      def app_version
        version = Ticket.config.app_version
        version.respond_to?(:call) ? version.call : version
      end
  end
end
