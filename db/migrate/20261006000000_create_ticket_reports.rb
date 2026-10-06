class CreateTicketReports < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_reports do |t|
      t.string :kind, null: false
      t.text :description, null: false
      t.string :page_url
      t.string :page_title
      t.string :reporter_id
      t.string :reporter_name
      t.string :reporter_email
      t.text :context
      t.binary :screenshot
      t.string :screenshot_content_type
      t.string :state, null: false, default: "pending"
      t.integer :issue_number
      t.string :issue_url
      t.text :error
      t.timestamps
    end

    add_index :ticket_reports, :state
  end
end
