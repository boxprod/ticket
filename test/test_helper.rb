# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Records issues instead of calling GitHub.
class FakeGitHubClient
  attr_reader :issues
  attr_accessor :failure

  def initialize
    @issues = []
  end

  def create_issue(**issue)
    raise failure if failure
    @issues << issue
    { number: @issues.size, url: "https://github.com/boxprod/dummy/issues/#{@issues.size}" }
  end
end

class ActiveSupport::TestCase
  setup do
    @github = Ticket.client = FakeGitHubClient.new
  end

  def build_report(**attributes)
    Ticket::Report.new(kind: "bug", description: "The total is wrong", page_url: "http://example.com/quotes/1",
      page_title: "Quote 1", reporter_name: "Ana", context: { "engine_url" => "http://example.com/ticket" }, **attributes)
  end
end
