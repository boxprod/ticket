require "test_helper"

class Ticket::DeliverJobTest < ActiveJob::TestCase
  setup { @report = build_report.tap(&:save!) }

  test "files the issue and keeps its number" do
    Ticket::DeliverJob.perform_now(@report)

    assert @report.reload.sent?
    assert_equal 1, @report.issue_number
    assert_equal "https://github.com/boxprod/dummy/issues/1", @report.issue_url
    assert_equal "[Bug] The total is wrong", @github.issues.first[:title]
    assert_equal %w[ feedback bug ], @github.issues.first[:labels]
  end

  test "does not file a report twice" do
    @report.update!(state: :sent)
    Ticket::DeliverJob.perform_now(@report)
    assert_empty @github.issues
  end

  test "tries again later when GitHub is unavailable" do
    @github.failure = Ticket::GitHub::Error.new("GitHub answered 502")
    assert_enqueued_with(job: Ticket::DeliverJob) { Ticket::DeliverJob.perform_now(@report) }
    assert @report.reload.pending?
  end

  test "gives up at once when GitHub refuses, and says why" do
    @github.failure = Ticket::GitHub::Rejected.new("GitHub answered 401: Bad credentials")
    assert_no_enqueued_jobs { Ticket::DeliverJob.perform_now(@report) }
    assert @report.reload.failed?
    assert_includes @report.error, "Bad credentials"
  end
end
