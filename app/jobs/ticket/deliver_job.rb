module Ticket
  # Not the host's ApplicationJob: none of its callbacks or retries apply here.
  class DeliverJob < ActiveJob::Base
    queue_as :default

    retry_on GitHub::Error, wait: :polynomially_longer, attempts: 10 do |job, error|
      job.arguments.first.update!(state: :failed, error: error.message)
    end

    discard_on GitHub::Rejected do |job, error|
      job.arguments.first.update!(state: :failed, error: error.message)
    end

    discard_on ActiveJob::DeserializationError

    def perform(report)
      return if report.sent?

      issue = Ticket.client.create_issue(title: report.title, body: IssueBody.new(report).to_s, labels: report.labels)
      report.update!(state: :sent, issue_number: issue[:number], issue_url: issue[:url], error: nil)
    end
  end
end
