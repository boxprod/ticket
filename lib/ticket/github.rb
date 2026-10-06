require "net/http"
require "json"

module Ticket
  # The one call made to GitHub: create an issue. Net::HTTP, so the host takes no new dependency.
  class GitHub
    class Error < StandardError; end

    # A refusal that will not change on retry (bad token, missing repository, invalid input).
    class Rejected < Error; end

    API = URI("https://api.github.com")

    # GitHub out of reach: worth trying again, like an answer in the 500s.
    NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError, IOError ].freeze

    def initialize(token:, repository:)
      @token = token
      @repository = repository
    end

    # Returns { number:, url: }.
    def create_issue(title:, body:, labels: [])
      response = post("/repos/#{@repository}/issues", title: title, body: body, labels: labels)

      # Labels are dropped rather than lose the report when the token may not set them.
      if response.code == "422" && labels.any? && response.body.to_s.include?("label")
        response = post("/repos/#{@repository}/issues", title: title, body: body)
      end

      case response
      when Net::HTTPSuccess
        issue = JSON.parse(response.body)
        { number: issue["number"], url: issue["html_url"] }
      when Net::HTTPTooManyRequests, Net::HTTPServerError
        raise Error, "GitHub answered #{response.code}: #{response.body.to_s.first(300)}"
      else
        raise Rejected, "GitHub answered #{response.code}: #{response.body.to_s.first(300)}"
      end
    end

    private
      def post(path, payload)
        request = Net::HTTP::Post.new(path)
        request["Authorization"] = "Bearer #{@token}"
        request["Accept"] = "application/vnd.github+json"
        request["X-GitHub-Api-Version"] = "2022-11-28"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(payload)
        perform(request)
      end

      def perform(request)
        Net::HTTP.start(API.host, API.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
          http.request(request)
        end
      rescue *NETWORK_ERRORS => error
        raise Error, "GitHub could not be reached: #{error.class}: #{error.message}"
      end
  end
end
