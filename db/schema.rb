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

ActiveRecord::Schema[8.0].define(version: 2025_08_16_071525) do
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
    t.integer "job_analysis_id"
    t.index ["job_analysis_id"], name: "index_chat_sessions_on_job_analysis_id"
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

  create_table "company_analyses", force: :cascade do |t|
    t.string "company_name"
    t.string "industry"
    t.string "company_size"
    t.text "recent_issues"
    t.text "business_context"
    t.text "hiring_patterns"
    t.text "competitor_info"
    t.text "industry_trends"
    t.datetime "analysis_date"
    t.datetime "cached_until"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.boolean "saved", default: false
    t.string "session_id"
    t.index ["saved"], name: "index_company_analyses_on_saved"
    t.index ["session_id"], name: "index_company_analyses_on_session_id"
    t.index ["user_id"], name: "index_company_analyses_on_user_id"
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
    t.text "advanced_analysis"
    t.bigint "user_id"
    t.jsonb "deep_analysis_data"
    t.index ["user_id"], name: "index_cover_letters_on_user_id"
  end

  create_table "job_analyses", force: :cascade do |t|
    t.string "url"
    t.string "company_name"
    t.string "position"
    t.text "analysis_result"
    t.text "keywords"
    t.text "required_skills"
    t.text "company_values"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "summary"
    t.integer "user_id"
    t.boolean "saved", default: false
    t.string "session_id"
    t.index ["session_id"], name: "index_job_analyses_on_session_id"
    t.index ["user_id"], name: "index_job_analyses_on_user_id"
  end

  create_table "job_posting_caches", force: :cascade do |t|
    t.string "url", null: false
    t.text "content"
    t.datetime "cached_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cached_at"], name: "index_job_posting_caches_on_cached_at"
    t.index ["url"], name: "index_job_posting_caches_on_url", unique: true
  end

  create_table "ontology_analyses", force: :cascade do |t|
    t.json "job_posting_data"
    t.json "company_data"
    t.json "applicant_data"
    t.json "relationships"
    t.float "match_score"
    t.json "strategy"
    t.datetime "analyzed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "job_analysis_id"
    t.bigint "user_profile_id"
    t.string "analysis_status"
    t.jsonb "applicant_graph"
    t.jsonb "job_graph"
    t.jsonb "company_graph"
    t.jsonb "matching_result"
    t.index ["analyzed_at"], name: "index_ontology_analyses_on_analyzed_at"
    t.index ["job_analysis_id"], name: "index_ontology_analyses_on_job_analysis_id"
    t.index ["match_score"], name: "index_ontology_analyses_on_match_score"
    t.index ["user_profile_id"], name: "index_ontology_analyses_on_user_profile_id"
  end

  create_table "ontology_concepts", force: :cascade do |t|
    t.string "concept_type", null: false
    t.string "name", null: false
    t.text "description"
    t.json "attributes"
    t.string "category"
    t.float "importance_score", default: 0.5
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_ontology_concepts_on_category"
    t.index ["concept_type", "name"], name: "index_ontology_concepts_on_concept_type_and_name"
  end

  create_table "ontology_matches", force: :cascade do |t|
    t.string "job_posting_url"
    t.string "company_name"
    t.bigint "user_id"
    t.json "job_ontology"
    t.json "company_ontology"
    t.json "applicant_ontology"
    t.json "relationships"
    t.float "match_score"
    t.json "strategy"
    t.json "visualization_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_ontology_matches_on_created_at"
    t.index ["match_score"], name: "index_ontology_matches_on_match_score"
    t.index ["user_id"], name: "index_ontology_matches_on_user_id"
  end

  create_table "ontology_relationships", force: :cascade do |t|
    t.bigint "source_concept_id"
    t.bigint "target_concept_id"
    t.string "relationship_type"
    t.float "strength", default: 0.5
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["relationship_type"], name: "index_ontology_relationships_on_relationship_type"
    t.index ["source_concept_id", "target_concept_id"], name: "idx_on_source_concept_id_target_concept_id_91d4ebbdbf"
    t.index ["source_concept_id"], name: "index_ontology_relationships_on_source_concept_id"
    t.index ["target_concept_id"], name: "index_ontology_relationships_on_target_concept_id"
  end

  create_table "skill_ontologies", force: :cascade do |t|
    t.string "esco_uri"
    t.string "skill_name", null: false
    t.string "skill_type"
    t.text "description"
    t.json "alternative_labels"
    t.json "broader_skills"
    t.json "narrower_skills"
    t.json "related_skills"
    t.integer "hierarchy_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["esco_uri"], name: "index_skill_ontologies_on_esco_uri"
    t.index ["skill_name"], name: "index_skill_ontologies_on_skill_name"
    t.index ["skill_type"], name: "index_skill_ontologies_on_skill_type"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "desired_position"
    t.text "introduction"
    t.text "education"
    t.text "technical_skills"
    t.jsonb "career_history"
    t.jsonb "projects"
    t.text "achievements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "analysis_preference"
    t.jsonb "educations", default: []
    t.jsonb "certifications", default: []
    t.jsonb "awards", default: []
    t.jsonb "extracurricular_activities", default: []
    t.text "programming_languages"
    t.text "frameworks"
    t.text "databases"
    t.text "tools"
    t.boolean "is_draft", default: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "phone_number"
    t.text "bio"
    t.json "profile_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "company_analyses", "users"
  add_foreign_key "company_news", "companies"
  add_foreign_key "cover_letters", "users"
  add_foreign_key "ontology_analyses", "job_analyses"
  add_foreign_key "ontology_analyses", "user_profiles"
  add_foreign_key "ontology_relationships", "ontology_concepts", column: "source_concept_id"
  add_foreign_key "ontology_relationships", "ontology_concepts", column: "target_concept_id"
  add_foreign_key "user_profiles", "users"
end
