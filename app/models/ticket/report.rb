module Ticket
  # A report kept in the host's database, so nothing is lost while GitHub is unreachable.
  class Report < ApplicationRecord
    KINDS = %w[ bug idea question ].freeze
    IMAGE_TYPES = { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp" }.freeze

    enum :state, { pending: "pending", sent: "sent", failed: "failed" }, default: "pending"

    serialize :context, coder: JSON

    validates :kind, inclusion: { in: KINDS }
    validates :description, presence: true, length: { maximum: 20_000 }
    validates :screenshot_content_type, inclusion: { in: IMAGE_TYPES.keys }, allow_nil: true
    validate :screenshot_within_limit

    # What `ticket:redeliver` sends again.
    scope :undelivered, -> { where.not(state: "sent") }

    def reporter=(reporter)
      self.reporter_id = reporter.try(:id)&.to_s
      self.reporter_name = Ticket.config.reporter_name.call(reporter).to_s.first(200)
      self.reporter_email = reporter.try(:email_address) || reporter.try(:email)
    end

    def screenshot_upload=(upload)
      return unless upload.respond_to?(:read)

      self.screenshot_content_type = upload.content_type
      self.screenshot = upload.read
    end

    def screenshot?
      screenshot.present?
    end

    def deliver_later
      DeliverJob.perform_later(self) if Ticket.config.deliver?
    end

    def title
      "[#{kind.capitalize}] #{description.squish.truncate(80)}"
    end

    # The engine's address as the reporter saw it, so the issue can link back to the screenshot.
    def screenshot_url
      "#{context["engine_url"]}/reports/#{id}/screenshot" if screenshot? && context&.dig("engine_url")
    end

    def labels
      Ticket.config.labels + [ kind ]
    end

    private
      def screenshot_within_limit
        errors.add(:screenshot, :too_long, count: Ticket.config.max_screenshot_size) if screenshot.to_s.bytesize > Ticket.config.max_screenshot_size
      end
  end
end
