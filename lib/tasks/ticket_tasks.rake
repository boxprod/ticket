namespace :ticket do
  desc "Send again the reports GitHub has not received"
  task redeliver: :environment do
    abort "Ticket has no repository or token to deliver to" unless Ticket.config.deliver?

    Ticket::Report.undelivered.find_each do |report|
      report.update!(state: :pending, error: nil)
      Ticket::DeliverJob.perform_later(report)
      puts "Report ##{report.id} queued"
    end
  end
end
