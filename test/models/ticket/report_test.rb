require "test_helper"

class Ticket::ReportTest < ActiveSupport::TestCase
  test "needs a known kind and a description" do
    report = build_report(kind: "rant", description: " ")
    assert_not report.valid?
    assert report.errors.key?(:kind)
    assert report.errors.key?(:description)
  end

  test "takes its reporter's id, name and email" do
    report = build_report
    report.reporter = User.new(id: 3, name: "", email_address: "ana@example.com")
    assert_equal "3", report.reporter_id
    assert_equal "ana@example.com", report.reporter_name
    assert_equal "ana@example.com", report.reporter_email
  end

  test "accepts images only, within the size limit" do
    report = build_report(screenshot: "x", screenshot_content_type: "text/html")
    assert_not report.valid?

    report = build_report(screenshot: "x" * (Ticket.config.max_screenshot_size + 1), screenshot_content_type: "image/png")
    assert_not report.valid?
    assert report.errors.key?(:screenshot)
  end

  test "titles the issue with its kind and the start of the description" do
    report = build_report(kind: "idea", description: "Show the margin\n\nnext to the total " + "very " * 40)
    assert report.title.start_with?("[Idea] Show the margin next to the total very")
    assert_operator report.title.length, :<=, 87
  end

  test "labels the issue with the configured labels and its kind" do
    assert_equal %w[ feedback bug ], build_report.labels
  end

  test "links to its screenshot through the engine the reporter used" do
    report = build_report(screenshot: "png", screenshot_content_type: "image/png")
    report.save!
    assert_equal "http://example.com/ticket/reports/#{report.id}/screenshot", report.screenshot_url
    assert_nil build_report.screenshot_url
  end
end
