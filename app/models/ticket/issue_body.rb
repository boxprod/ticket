module Ticket
  # The Markdown of the issue: the report in the reporter's words, then what was collected around it.
  class IssueBody
    def initialize(report)
      @report = report
      @context = report.context || {}
    end

    def to_s
      [ description, screenshot, reporter, details ].compact.join("\n\n")
    end

    private
      def description
        @report.description.strip
      end

      def screenshot
        "**Screenshot:** [view](#{@report.screenshot_url}) (sign in to the app to open it)" if @report.screenshot_url
      end

      def reporter
        page = @report.page_url.present? ? "[#{escape(@report.page_title.presence || @report.page_url)}](<#{@report.page_url.delete("<>")}>)" : "unknown page"
        "Reported by **#{escape(@report.reporter_name)}** on #{page}, #{@report.created_at.utc.strftime("%Y-%m-%d %H:%M UTC")}."
      end

      def details
        rows = {
          "Report" => "##{@report.id}",
          "Version" => @context["app_version"],
          "Environment" => @context["environment"],
          "Request" => @context["request_id"],
          "Browser" => @context["user_agent"],
          "Viewport" => @context.dig("browser", "viewport"),
          "Screen" => @context.dig("browser", "screen"),
          "Language" => @context.dig("browser", "language"),
          "Time zone" => @context.dig("browser", "timezone")
        }.compact_blank

        table = rows.map { |name, value| "| #{name} | `#{value.to_s.delete("`|")}` |" }
        lines = [ "<details><summary>Context</summary>", "", "| | |", "|---|---|", *table ]

        if (errors = @context["errors"]).present?
          lines += [ "", "JavaScript errors on the page:", "", "```", *errors, "```" ]
        end

        (lines + [ "", "</details>" ]).join("\n")
      end

      def escape(text)
        text.to_s.gsub(/[\[\]<>*_`]/) { |char| "\\#{char}" }
      end
  end
end
