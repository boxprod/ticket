require "test_helper"

class Ticket::ReportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "refuses a report from someone signed out" do
    post "/ticket/reports", params: { kind: "bug", description: "Broken" }, as: :json
    assert_response :unauthorized
    assert_equal 0, Ticket::Report.count
  end

  test "keeps the report with its context and queues the issue" do
    get "/sign_in", params: { name: "ana" }

    assert_enqueued_with(job: Ticket::DeliverJob) do
      post "/ticket/reports", params: {
        kind: "idea", description: "A total per chapter", page_url: "http://www.example.com/quotes/1", page_title: "Quote 1",
        page_request_id: "req-1", browser: { viewport: "1280×800", language: "fr-FR" }, errors: [ "TypeError" ],
        screenshot: fixture_file_upload("screenshot.png", "image/png")
      }
    end
    assert_response :created

    report = Ticket::Report.last
    assert_equal "idea", report.kind
    assert_equal "ana", report.reporter_name
    assert_equal "7", report.reporter_id
    assert_equal "image/png", report.screenshot_content_type
    assert_equal "req-1", report.context["request_id"]
    assert_equal "1280×800", report.context.dig("browser", "viewport")
    assert_equal [ "TypeError" ], report.context["errors"]
    assert_equal "http://www.example.com/ticket/reports/#{report.id}/screenshot", report.screenshot_url
  end

  test "answers what is missing" do
    get "/sign_in", params: { name: "ana" }
    post "/ticket/reports", params: { kind: "bug", description: "" }
    assert_response :unprocessable_content
    assert_not_empty response.parsed_body["errors"]
  end

  test "keeps the report but sends nothing without a token" do
    get "/sign_in", params: { name: "ana" }
    token, Ticket.config.github_token = Ticket.config.github_token, nil
    assert_no_enqueued_jobs { post "/ticket/reports", params: { kind: "bug", description: "Broken" } }
  ensure
    Ticket.config.github_token = token
    assert Ticket::Report.last.pending?
  end

  test "shows the screenshot to someone signed in only" do
    report = build_report(screenshot: file_fixture("screenshot.png").binread, screenshot_content_type: "image/png").tap(&:save!)

    get "/ticket/reports/#{report.id}/screenshot"
    assert_response :unauthorized

    get "/sign_in", params: { name: "ana" }
    get "/ticket/reports/#{report.id}/screenshot"
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal file_fixture("screenshot.png").binread, response.body
  end
end
