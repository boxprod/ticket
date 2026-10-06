require "application_system_test_case"

class WidgetSystemTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    visit "/sign_in?name=ana"
  end

  test "sends a report with an attached image" do
    widget = find("ticket-widget", visible: :all).shadow_root
    widget.find(".toggle").click
    widget.find("input[value=idea]").click
    widget.find("textarea").fill_in(with: "A total per chapter")
    widget.find("input[type=file]", visible: :all).attach_file(file_fixture("screenshot.png"), make_visible: true)
    assert widget.has_css?(".shot img[src^=blob]")

    widget.find(".submit").click
    assert widget.has_css?(".done:not([hidden])", text: "Thank you")

    report = Ticket::Report.last
    assert_equal "idea", report.kind
    assert_equal "A total per chapter", report.description
    assert_equal "image/webp", report.screenshot_content_type
    assert_match %r{/\z}, report.page_url
  end

  test "captures the current tab" do
    widget = find("ticket-widget", visible: :all).shadow_root
    widget.find(".toggle").click
    widget.find(".capture").click
    assert widget.has_css?(".shot img[src^=blob]", wait: 10)
  end

  test "keeps the draft across a Turbo-less reload of the element" do
    widget = find("ticket-widget", visible: :all).shadow_root
    widget.find(".toggle").click
    widget.find("textarea").fill_in(with: "Half written")
    page.execute_script("const w = document.querySelector('ticket-widget'); const copy = w.cloneNode(); w.replaceWith(copy)")
    assert_equal "Half written", find("ticket-widget", visible: :all).shadow_root.find("textarea").value
  end
end
