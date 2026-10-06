# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_06_000000) do
  create_table "ticket_reports", force: :cascade do |t|
    t.string "kind", null: false
    t.text "description", null: false
    t.string "page_url"
    t.string "page_title"
    t.string "reporter_id"
    t.string "reporter_name"
    t.string "reporter_email"
    t.text "context"
    t.binary "screenshot"
    t.string "screenshot_content_type"
    t.string "state", default: "pending", null: false
    t.integer "issue_number"
    t.string "issue_url"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "state" ], name: "index_ticket_reports_on_state"
  end
end
