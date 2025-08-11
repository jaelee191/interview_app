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

ActiveRecord::Schema[8.0].define(version: 2025_08_09_020327) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "url"
    t.string "source"
    t.datetime "published_at"
    t.string "author"
    t.string "category"
    t.text "summary"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.string "session_id"
    t.string "company_name"
    t.string "position"
    t.string "current_step"
    t.text "content"
    t.text "messages"
    t.text "final_content"
    t.text "question_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_chat_sessions_on_session_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "ticker"
    t.text "description"
    t.string "industry"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_news", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "title"
    t.text "content"
    t.string "url"
    t.string "source"
    t.datetime "published_at"
    t.string "sentiment"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_news_on_company_id"
  end

  create_table "cover_letters", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.text "analysis_result"
    t.string "company_name"
    t.string "position"
    t.string "user_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "company_news", "companies"
end
