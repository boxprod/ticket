require "test_helper"

class Ticket::GitHubTest < ActiveSupport::TestCase
  # Answers from a list instead of the network, and keeps what was sent.
  class Recorded < Ticket::GitHub
    attr_accessor :responses, :payloads

    private
      def perform(request)
        payloads << JSON.parse(request.body)
        responses.shift
      end
  end

  setup { @github = Recorded.new(token: "t", repository: "boxprod/dummy") }

  test "returns the new issue's number and address" do
    stub_responses(net_response(Net::HTTPCreated, "201", { number: 12, html_url: "https://github.com/boxprod/dummy/issues/12" })) do |payloads|
      assert_equal({ number: 12, url: "https://github.com/boxprod/dummy/issues/12" }, @github.create_issue(title: "T", body: "B", labels: [ "bug" ]))
      assert_equal [ "bug" ], payloads.first["labels"]
    end
  end

  test "files the issue without labels when they are refused" do
    refused = net_response(Net::HTTPUnprocessableEntity, "422", { message: "Validation Failed", errors: [ { field: "labels" } ] })
    created = net_response(Net::HTTPCreated, "201", { number: 1, html_url: "u" })
    stub_responses(refused, created) do |payloads|
      @github.create_issue(title: "T", body: "B", labels: [ "bug" ])
      assert_nil payloads.last["labels"]
    end
  end

  test "tells a refusal from an outage" do
    stub_responses(net_response(Net::HTTPUnauthorized, "401", { message: "Bad credentials" })) do
      assert_raises(Ticket::GitHub::Rejected) { @github.create_issue(title: "T", body: "B") }
    end
    stub_responses(net_response(Net::HTTPBadGateway, "502", {})) do
      error = assert_raises(Ticket::GitHub::Error) { @github.create_issue(title: "T", body: "B") }
      assert_not_kind_of Ticket::GitHub::Rejected, error
    end
  end

  test "takes a network failure for an outage" do
    connection = Ticket::GitHub.new(token: "t", repository: "boxprod/dummy")
    Net::HTTP.singleton_class.alias_method(:original_start, :start)
    Net::HTTP.define_singleton_method(:start) { |*, **| raise Net::OpenTimeout, "execution expired" }
    error = assert_raises(Ticket::GitHub::Error) { connection.create_issue(title: "T", body: "B") }
    assert_not_kind_of Ticket::GitHub::Rejected, error
    assert_includes error.message, "Net::OpenTimeout"
  ensure
    Net::HTTP.singleton_class.alias_method(:start, :original_start)
    Net::HTTP.singleton_class.remove_method(:original_start)
  end

  private
    def net_response(klass, code, body)
      klass.new("1.1", code, "").tap do |response|
        response.instance_variable_set(:@body, JSON.generate(body))
        response.instance_variable_set(:@read, true)
      end
    end

    def stub_responses(*responses)
      @github.responses = responses
      @github.payloads = []
      yield @github.payloads
    end
end
