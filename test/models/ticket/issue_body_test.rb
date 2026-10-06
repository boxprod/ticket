require "test_helper"

class Ticket::IssueBodyTest < ActiveSupport::TestCase
  test "puts the reporter's words first, then who, where and the context" do
    report = build_report(screenshot: "png", screenshot_content_type: "image/png")
    report.context.merge!("app_version" => "abc123", "user_agent" => "Firefox | 140", "errors" => [ "TypeError: x is null" ])
    report.save!

    body = Ticket::IssueBody.new(report).to_s

    assert body.start_with?("The total is wrong")
    assert_includes body, "[view](http://example.com/ticket/reports/#{report.id}/screenshot)"
    assert_includes body, "Reported by **Ana** on [Quote 1](<http://example.com/quotes/1>)"
    assert_includes body, "| Version | `abc123` |"
    assert_includes body, "| Browser | `Firefox  140` |"
    assert_includes body, "TypeError: x is null"
  end

  test "keeps a reporter's name from turning into Markdown" do
    report = build_report(reporter_name: "*Ana* [x](y)")
    report.save!
    assert_includes Ticket::IssueBody.new(report).to_s, "**\\*Ana\\* \\[x\\](y)**"
  end
end
