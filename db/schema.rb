# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_04_133925) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ahoy_messages", id: :serial, force: :cascade do |t|
    t.datetime "clicked_at"
    t.text "content"
    t.integer "feedback_message_id"
    t.string "mailer"
    t.datetime "opened_at"
    t.datetime "sent_at"
    t.text "subject"
    t.text "to"
    t.string "token"
    t.integer "user_id"
    t.string "user_type"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.index ["to"], name: "index_ahoy_messages_on_to"
    t.index ["token"], name: "index_ahoy_messages_on_token"
    t.index ["user_id", "user_type"], name: "index_ahoy_messages_on_user_id_and_user_type"
  end

  create_table "api_secrets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "secret"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["secret"], name: "index_api_secrets_on_secret", unique: true
    t.index ["user_id"], name: "index_api_secrets_on_user_id"
  end

  create_table "articles", id: :serial, force: :cascade do |t|
    t.boolean "any_comments_hidden", default: false
    t.boolean "approved", default: false
    t.boolean "archived", default: false
    t.text "body_html"
    t.text "body_markdown"
    t.jsonb "boost_states", default: {}, null: false
    t.text "cached_organization"
    t.string "cached_tag_list"
    t.text "cached_user"
    t.string "cached_user_name"
    t.string "cached_user_username"
    t.string "canonical_url"
    t.integer "collection_id"
    t.integer "comment_score", default: 0
    t.string "comment_template"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "crossposted_at"
    t.string "description"
    t.datetime "edited_at"
    t.boolean "email_digest_eligible", default: true
    t.float "experience_level_rating", default: 5.0
    t.float "experience_level_rating_distribution", default: 5.0
    t.datetime "facebook_last_buffered"
    t.boolean "featured", default: false
    t.integer "featured_number"
    t.string "feed_source_url"
    t.integer "hotness_score", default: 0
    t.string "language"
    t.datetime "last_buffered"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "last_experience_level_rating_at"
    t.string "main_image"
    t.string "main_image_background_hex_color", default: "#dddddd"
    t.integer "nth_published_by_author", default: 0
    t.integer "organic_page_views_count", default: 0
    t.integer "organic_page_views_past_month_count", default: 0
    t.integer "organic_page_views_past_week_count", default: 0
    t.integer "organization_id"
    t.datetime "originally_published_at"
    t.integer "page_views_count", default: 0
    t.string "password"
    t.string "path"
    t.integer "positive_reactions_count", default: 0, null: false
    t.integer "previous_positive_reactions_count", default: 0
    t.integer "previous_public_reactions_count", default: 0, null: false
    t.text "processed_html"
    t.integer "public_reactions_count", default: 0, null: false
    t.boolean "published", default: false
    t.datetime "published_at"
    t.boolean "published_from_feed", default: false
    t.integer "rating_votes_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.integer "reading_time", default: 0
    t.boolean "receive_notifications", default: true
    t.integer "score", default: 0
    t.string "search_optimized_description_replacement"
    t.string "search_optimized_title_preamble"
    t.integer "second_user_id"
    t.boolean "show_comments", default: true
    t.text "slug"
    t.string "social_image"
    t.integer "spaminess_rating", default: 0
    t.integer "third_user_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "video"
    t.string "video_closed_caption_track_url"
    t.string "video_code"
    t.float "video_duration_in_seconds", default: 0.0
    t.string "video_source_url"
    t.string "video_state"
    t.string "video_thumbnail_url"
    t.index ["boost_states"], name: "index_articles_on_boost_states", using: :gin
    t.index ["comment_score"], name: "index_articles_on_comment_score"
    t.index ["featured_number"], name: "index_articles_on_featured_number"
    t.index ["feed_source_url"], name: "index_articles_on_feed_source_url"
    t.index ["hotness_score"], name: "index_articles_on_hotness_score"
    t.index ["path"], name: "index_articles_on_path"
    t.index ["published"], name: "index_articles_on_published"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "roles", array: true
    t.string "slug"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["data"], name: "index_audit_logs_on_data", using: :gin
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "backup_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "instance_id", null: false
    t.string "instance_type", null: false
    t.bigint "instance_user_id"
    t.jsonb "json_data", null: false
    t.datetime "updated_at", null: false
  end

  create_table "badge_achievements", force: :cascade do |t|
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.integer "rewarder_id"
    t.text "rewarding_context_message"
    t.text "rewarding_context_message_markdown"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["badge_id", "user_id"], name: "index_badge_achievements_on_badge_id_and_user_id", unique: true
    t.index ["badge_id"], name: "index_badge_achievements_on_badge_id"
    t.index ["user_id", "badge_id"], name: "index_badge_achievements_on_user_id_and_badge_id"
    t.index ["user_id"], name: "index_badge_achievements_on_user_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "badge_image"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_badges_on_slug", unique: true
    t.index ["title"], name: "index_badges_on_title", unique: true
  end

  create_table "banished_users", force: :cascade do |t|
    t.bigint "banished_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["banished_by_id"], name: "index_banished_users_on_banished_by_id"
    t.index ["username"], name: "index_banished_users_on_username", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "blocks", id: :serial, force: :cascade do |t|
    t.text "body_html"
    t.text "body_markdown"
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.integer "featured_number"
    t.integer "index_position"
    t.text "input_css"
    t.text "input_html"
    t.text "input_javascript"
    t.text "processed_css"
    t.text "processed_html"
    t.text "processed_javascript"
    t.text "published_css"
    t.text "published_html"
    t.text "published_javascript"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "broadcasts", id: :serial, force: :cascade do |t|
    t.boolean "active", default: false
    t.text "body_markdown"
    t.datetime "created_at"
    t.text "processed_html"
    t.string "title"
    t.string "type_of"
    t.datetime "updated_at"
    t.index ["title", "type_of"], name: "index_broadcasts_on_title_and_type_of", unique: true
  end

  create_table "buffer_updates", force: :cascade do |t|
    t.integer "approver_user_id"
    t.integer "article_id", null: false
    t.text "body_text"
    t.string "buffer_id_code"
    t.string "buffer_profile_id_code"
    t.text "buffer_response", default: "--- {}\n"
    t.integer "composer_user_id"
    t.datetime "created_at", null: false
    t.string "social_service_name"
    t.string "status", default: "pending"
    t.integer "tag_id"
    t.datetime "updated_at", null: false
  end

  create_table "chat_channel_memberships", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.boolean "has_unopened_messages", default: false
    t.datetime "last_opened_at", default: "2017-01-01 05:00:00"
    t.string "role", default: "member"
    t.boolean "show_global_badge_notification", default: true
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id", "user_id"], name: "index_chat_channel_memberships_on_chat_channel_id_and_user_id", unique: true
    t.index ["chat_channel_id"], name: "index_chat_channel_memberships_on_chat_channel_id"
    t.index ["user_id", "chat_channel_id"], name: "index_chat_channel_memberships_on_user_id_and_chat_channel_id"
    t.index ["user_id"], name: "index_chat_channel_memberships_on_user_id"
  end

  create_table "chat_channels", force: :cascade do |t|
    t.string "channel_name"
    t.string "channel_type", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "discoverable", default: false
    t.datetime "last_message_at", default: "2017-01-01 05:00:00"
    t.string "slug"
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_chat_channels_on_slug", unique: true
  end

  create_table "classified_listing_categories", force: :cascade do |t|
    t.integer "cost", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "rules", null: false
    t.string "slug", null: false
    t.string "social_preview_color"
    t.string "social_preview_description"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_classified_listing_categories_on_name", unique: true
    t.index ["slug"], name: "index_classified_listing_categories_on_slug", unique: true
  end

  create_table "classified_listings", force: :cascade do |t|
    t.text "body_markdown"
    t.datetime "bumped_at"
    t.string "cached_tag_list"
    t.bigint "classified_listing_category_id"
    t.boolean "contact_via_connect", default: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_buffered"
    t.string "location"
    t.bigint "organization_id"
    t.text "processed_html"
    t.boolean "published"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["classified_listing_category_id"], name: "index_classified_listings_on_classified_listing_category_id"
    t.index ["organization_id"], name: "index_classified_listings_on_organization_id"
    t.index ["user_id"], name: "index_classified_listings_on_user_id"
  end

  create_table "collections", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "main_image"
    t.integer "organization_id"
    t.boolean "published", default: false
    t.string "slug"
    t.string "social_image"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["organization_id"], name: "index_collections_on_organization_id"
    t.index ["slug", "user_id"], name: "index_collections_on_slug_and_user_id", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "ancestry"
    t.text "body_html"
    t.text "body_markdown"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "edited", default: false
    t.datetime "edited_at"
    t.boolean "hidden_by_commentable_user", default: false
    t.string "id_code"
    t.integer "markdown_character_count"
    t.integer "positive_reactions_count", default: 0, null: false
    t.text "processed_html"
    t.integer "public_reactions_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.boolean "receive_notifications", default: true
    t.integer "score", default: 0
    t.integer "spaminess_rating", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["ancestry"], name: "index_comments_on_ancestry"
    t.index ["body_markdown", "user_id", "ancestry", "commentable_id", "commentable_type"], name: "index_comments_on_body_markdown_user_id_ancestry_commentable", unique: true
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["score"], name: "index_comments_on_score"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "credits", force: :cascade do |t|
    t.float "cost", default: 0.0
    t.datetime "created_at", null: false
    t.bigint "organization_id"
    t.bigint "purchase_id"
    t.string "purchase_type"
    t.boolean "spent", default: false
    t.datetime "spent_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["purchase_id", "purchase_type"], name: "index_credits_on_purchase_id_and_purchase_type"
    t.index ["spent"], name: "index_credits_on_spent"
  end

  create_table "data_update_scripts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_name"
    t.datetime "finished_at"
    t.datetime "run_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["file_name"], name: "index_data_update_scripts_on_file_name", unique: true
  end

  create_table "display_ad_events", force: :cascade do |t|
    t.string "category"
    t.string "context_type"
    t.datetime "created_at", null: false
    t.integer "display_ad_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["display_ad_id"], name: "index_display_ad_events_on_display_ad_id"
    t.index ["user_id"], name: "index_display_ad_events_on_user_id"
  end

  create_table "display_ads", force: :cascade do |t|
    t.boolean "approved", default: false
    t.text "body_markdown"
    t.integer "clicks_count", default: 0
    t.datetime "created_at", null: false
    t.integer "impressions_count", default: 0
    t.integer "organization_id"
    t.string "placement_area"
    t.text "processed_html"
    t.boolean "published", default: false
    t.float "success_rate", default: 0.0
    t.datetime "updated_at", null: false
  end

  create_table "email_authorizations", force: :cascade do |t|
    t.string "confirmation_token"
    t.datetime "created_at", null: false
    t.jsonb "json_data", default: {}, null: false
    t.string "type_of", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.datetime "verified_at"
  end

  create_table "events", force: :cascade do |t|
    t.string "category"
    t.string "cover_image"
    t.datetime "created_at", null: false
    t.text "description_html"
    t.text "description_markdown"
    t.datetime "ends_at"
    t.string "host_name"
    t.boolean "live_now", default: false
    t.string "location_name"
    t.string "location_url"
    t.string "profile_image"
    t.boolean "published"
    t.string "slug"
    t.datetime "starts_at"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "feedback_messages", force: :cascade do |t|
    t.integer "affected_id"
    t.string "category"
    t.datetime "created_at"
    t.string "feedback_type"
    t.text "message"
    t.integer "offender_id"
    t.string "reported_url"
    t.integer "reporter_id"
    t.string "status", default: "Open"
    t.datetime "updated_at"
    t.index ["affected_id"], name: "index_feedback_messages_on_affected_id"
    t.index ["offender_id"], name: "index_feedback_messages_on_offender_id"
    t.index ["reporter_id"], name: "index_feedback_messages_on_reporter_id"
  end

  create_table "field_test_events", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "field_test_membership_id"
    t.string "name"
    t.index ["field_test_membership_id"], name: "index_field_test_events_on_field_test_membership_id"
  end

  create_table "field_test_memberships", force: :cascade do |t|
    t.boolean "converted", default: false
    t.datetime "created_at"
    t.string "experiment"
    t.string "participant_id"
    t.string "participant_type"
    t.string "variant"
    t.index ["experiment", "created_at"], name: "index_field_test_memberships_on_experiment_and_created_at"
    t.index ["participant_type", "participant_id", "experiment"], name: "index_field_test_memberships_on_participant", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at"
    t.integer "followable_id", null: false
    t.string "followable_type", null: false
    t.integer "follower_id", null: false
    t.string "follower_type", null: false
    t.float "points", default: 1.0
    t.string "subscription_status", default: "all_articles", null: false
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_follows_on_created_at"
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
  end

  create_table "github_issues", id: :serial, force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "issue_serialized", default: "--- {}\n"
    t.string "processed_html"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["url"], name: "index_github_issues_on_url", unique: true
  end

  create_table "github_repos", force: :cascade do |t|
    t.string "additional_note"
    t.integer "bytes_size"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "featured", default: false
    t.boolean "fork", default: false
    t.integer "github_id_code"
    t.text "info_hash", default: "--- {}\n"
    t.string "language"
    t.string "name"
    t.integer "priority", default: 0
    t.integer "stargazers_count"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id"
    t.integer "watchers_count"
    t.index ["github_id_code"], name: "index_github_repos_on_github_id_code", unique: true
    t.index ["url"], name: "index_github_repos_on_url", unique: true
  end

  create_table "html_variant_successes", force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.integer "html_variant_id"
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_successes_on_html_variant_id_and_article_id"
  end

  create_table "html_variant_trials", force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.integer "html_variant_id"
    t.datetime "updated_at", null: false
    t.index ["html_variant_id", "article_id"], name: "index_html_variant_trials_on_html_variant_id_and_article_id"
  end

  create_table "html_variants", force: :cascade do |t|
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.string "group"
    t.text "html"
    t.string "name"
    t.boolean "published", default: false
    t.float "success_rate", default: 0.0
    t.string "target_tag"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["name"], name: "index_html_variants_on_name", unique: true
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.text "auth_data_dump"
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "secret"
    t.string "token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["provider", "user_id"], name: "index_identities_on_provider_and_user_id", unique: true
  end

  create_table "mentions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mentionable_id"
    t.string "mentionable_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id", "mentionable_id", "mentionable_type"], name: "index_mentions_on_user_id_and_mentionable_id_mentionable_type", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "chat_action"
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.string "message_html", null: false
    t.string "message_markdown", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id"], name: "index_messages_on_chat_channel_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "noteable_id"
    t.string "noteable_type"
    t.string "reason"
    t.datetime "updated_at", null: false
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.text "config", default: "all_comments", null: false
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notifiable_id", "notifiable_type", "config"], name: "index_notification_subscriptions_on_notifiable_and_config"
    t.index ["user_id", "notifiable_type", "notifiable_id"], name: "idx_notification_subs_on_user_id_notifiable_type_notifiable_id", unique: true
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.jsonb "json_data"
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.datetime "notified_at"
    t.bigint "organization_id"
    t.boolean "read", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["json_data"], name: "index_notifications_on_json_data", using: :gin
    t.index ["notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_notifiable_id_notifiable_type_and_action"
    t.index ["notifiable_id"], name: "index_notifications_on_notifiable_id"
    t.index ["notifiable_type"], name: "index_notifications_on_notifiable_type"
    t.index ["notified_at"], name: "index_notifications_on_notified_at"
    t.index ["organization_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_org_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["organization_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_org_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["user_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_on_user_notifiable_and_action_not_null", unique: true, where: "(action IS NOT NULL)"
    t.index ["user_id", "notifiable_id", "notifiable_type"], name: "index_notifications_on_user_notifiable_action_is_null", unique: true, where: "(action IS NULL)"
    t.index ["user_id", "organization_id", "notifiable_id", "notifiable_type", "action"], name: "index_notifications_user_id_organization_id_notifiable_action", unique: true
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.bigint "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.bigint "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "type_of_user", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "user_title"
    t.index ["user_id", "organization_id"], name: "index_organization_memberships_on_user_id_and_organization_id", unique: true
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.string "bg_color_hex"
    t.string "company_size"
    t.datetime "created_at", null: false
    t.integer "credits_count", default: 0, null: false
    t.text "cta_body_markdown"
    t.string "cta_button_text"
    t.string "cta_button_url"
    t.text "cta_processed_html"
    t.string "dark_nav_image"
    t.string "email"
    t.string "github_username"
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.string "location"
    t.string "name"
    t.string "nav_image"
    t.string "old_old_slug"
    t.string "old_slug"
    t.string "profile_image"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.text "proof"
    t.string "secret"
    t.string "slug"
    t.integer "spent_credits_count", default: 0, null: false
    t.string "story"
    t.text "summary"
    t.string "tag_line"
    t.string "tech_stack"
    t.string "text_color_hex"
    t.string "twitter_username"
    t.integer "unspent_credits_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["secret"], name: "index_organizations_on_secret", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "page_views", force: :cascade do |t|
    t.bigint "article_id"
    t.integer "counts_for_number_of_views", default: 1
    t.datetime "created_at", null: false
    t.string "domain"
    t.string "path"
    t.string "referrer"
    t.integer "time_tracked_in_seconds", default: 15
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["article_id"], name: "index_page_views_on_article_id"
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["domain"], name: "index_page_views_on_domain"
    t.index ["user_id"], name: "index_page_views_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.text "body_html"
    t.text "body_markdown"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "is_top_level_path", default: false
    t.text "processed_html"
    t.string "slug"
    t.string "social_image"
    t.string "template"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "path_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "new_path", null: false
    t.string "old_path", null: false
    t.string "source"
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index ["new_path"], name: "index_path_redirects_on_new_path"
    t.index ["old_path"], name: "index_path_redirects_on_old_path", unique: true
    t.index ["source"], name: "index_path_redirects_on_source"
    t.index ["version"], name: "index_path_redirects_on_version"
  end

  create_table "podcast_episodes", id: :serial, force: :cascade do |t|
    t.boolean "any_comments_hidden", default: false
    t.text "body"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duration_in_seconds"
    t.string "guid", null: false
    t.boolean "https", default: true
    t.string "image"
    t.string "itunes_url"
    t.string "media_url", null: false
    t.integer "podcast_id"
    t.text "processed_html"
    t.datetime "published_at"
    t.text "quote"
    t.boolean "reachable", default: true
    t.integer "reactions_count", default: 0, null: false
    t.string "slug", null: false
    t.string "social_image"
    t.string "status_notice"
    t.string "subtitle"
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["guid"], name: "index_podcast_episodes_on_guid", unique: true
    t.index ["media_url"], name: "index_podcast_episodes_on_media_url", unique: true
    t.index ["podcast_id"], name: "index_podcast_episodes_on_podcast_id"
    t.index ["title"], name: "index_podcast_episodes_on_title"
    t.index ["website_url"], name: "index_podcast_episodes_on_website_url"
  end

  create_table "podcasts", id: :serial, force: :cascade do |t|
    t.string "android_url"
    t.datetime "created_at", null: false
    t.integer "creator_id"
    t.text "description"
    t.string "feed_url", null: false
    t.string "image", null: false
    t.string "itunes_url"
    t.string "main_color_hex", null: false
    t.string "overcast_url"
    t.string "pattern_image"
    t.boolean "published", default: false
    t.boolean "reachable", default: true
    t.string "slug", null: false
    t.string "soundcloud_url"
    t.text "status_notice", default: ""
    t.string "title", null: false
    t.string "twitter_username"
    t.boolean "unique_website_url?", default: true
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["creator_id"], name: "index_podcasts_on_creator_id"
    t.index ["feed_url"], name: "index_podcasts_on_feed_url", unique: true
    t.index ["slug"], name: "index_podcasts_on_slug", unique: true
  end

  create_table "poll_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "markdown"
    t.bigint "poll_id"
    t.integer "poll_votes_count", default: 0, null: false
    t.string "processed_html"
    t.datetime "updated_at", null: false
  end

  create_table "poll_skips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["poll_id", "user_id"], name: "index_poll_skips_on_poll_and_user", unique: true
  end

  create_table "poll_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_id", "user_id"], name: "index_poll_votes_on_poll_id_and_user_id", unique: true
    t.index ["poll_option_id", "user_id"], name: "index_poll_votes_on_poll_option_and_user", unique: true
  end

  create_table "polls", force: :cascade do |t|
    t.bigint "article_id"
    t.datetime "created_at", null: false
    t.integer "poll_options_count", default: 0, null: false
    t.integer "poll_skips_count", default: 0, null: false
    t.integer "poll_votes_count", default: 0, null: false
    t.string "prompt_html"
    t.string "prompt_markdown"
    t.datetime "updated_at", null: false
  end

  create_table "profile_pins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "pinnable_id"
    t.string "pinnable_type"
    t.bigint "profile_id"
    t.string "profile_type"
    t.datetime "updated_at", null: false
    t.index ["pinnable_id", "profile_id", "profile_type", "pinnable_type"], name: "idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type", unique: true
    t.index ["pinnable_id"], name: "index_profile_pins_on_pinnable_id"
    t.index ["profile_id"], name: "index_profile_pins_on_profile_id"
  end

  create_table "rating_votes", force: :cascade do |t|
    t.bigint "article_id"
    t.string "context", default: "explicit"
    t.datetime "created_at", null: false
    t.string "group"
    t.float "rating"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["article_id"], name: "index_rating_votes_on_article_id"
    t.index ["user_id", "article_id", "context"], name: "index_rating_votes_on_user_id_and_article_id_and_context", unique: true
    t.index ["user_id"], name: "index_rating_votes_on_user_id"
  end

  create_table "reactions", id: :serial, force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.float "points", default: 1.0
    t.integer "reactable_id"
    t.string "reactable_type"
    t.string "status", default: "valid"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["category"], name: "index_reactions_on_category"
    t.index ["created_at"], name: "index_reactions_on_created_at"
    t.index ["points"], name: "index_reactions_on_points"
    t.index ["reactable_id", "reactable_type"], name: "index_reactions_on_reactable_id_and_reactable_type"
    t.index ["reactable_id"], name: "index_reactions_on_reactable_id"
    t.index ["reactable_type"], name: "index_reactions_on_reactable_type"
    t.index ["user_id", "reactable_id", "reactable_type", "category"], name: "index_reactions_on_user_id_reactable_id_reactable_type_category", unique: true
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "response_templates", force: :cascade do |t|
    t.text "content", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.string "type_of", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["content", "user_id", "type_of", "content_type"], name: "idx_response_templates_on_content_user_id_type_of_content_type", unique: true
    t.index ["type_of"], name: "index_response_templates_on_type_of"
    t.index ["user_id", "type_of"], name: "index_response_templates_on_user_id_and_type_of"
    t.index ["user_id"], name: "index_response_templates_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "site_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_site_configs_on_var", unique: true
  end

  create_table "sponsorships", force: :cascade do |t|
    t.text "blurb_html"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "featured_number", default: 0, null: false
    t.text "instructions"
    t.datetime "instructions_updated_at"
    t.string "level", null: false
    t.bigint "organization_id"
    t.bigint "sponsorable_id"
    t.string "sponsorable_type"
    t.string "status", default: "none", null: false
    t.string "tagline"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id"
    t.index ["level"], name: "index_sponsorships_on_level"
    t.index ["organization_id"], name: "index_sponsorships_on_organization_id"
    t.index ["sponsorable_id", "sponsorable_type"], name: "index_sponsorships_on_sponsorable_id_and_sponsorable_type"
    t.index ["status"], name: "index_sponsorships_on_status"
    t.index ["user_id"], name: "index_sponsorships_on_user_id"
  end

  create_table "tag_adjustments", force: :cascade do |t|
    t.string "adjustment_type"
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.string "reason_for_adjustment"
    t.string "status"
    t.integer "tag_id"
    t.string "tag_name"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["tag_name", "article_id"], name: "index_tag_adjustments_on_tag_name_and_article_id", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at"
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "alias_for"
    t.integer "badge_id"
    t.string "bg_color_hex"
    t.string "buffer_profile_id_code"
    t.string "category", default: "uncategorized", null: false
    t.datetime "created_at"
    t.integer "hotness_score", default: 0
    t.string "keywords_for_search"
    t.integer "mod_chat_channel_id"
    t.string "name"
    t.string "pretty_name"
    t.string "profile_image"
    t.boolean "requires_approval", default: false
    t.text "rules_html"
    t.text "rules_markdown"
    t.string "short_summary"
    t.string "social_image"
    t.string "social_preview_template", default: "article"
    t.text "submission_template"
    t.boolean "supported", default: false
    t.integer "taggings_count", default: 0
    t.string "text_color_hex"
    t.datetime "updated_at"
    t.text "wiki_body_html"
    t.text "wiki_body_markdown"
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["social_preview_template"], name: "index_tags_on_social_preview_template"
  end

  create_table "tweets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "extended_entities_serialized", default: "--- {}\n"
    t.integer "favorite_count"
    t.text "full_fetched_object_serialized", default: "--- {}\n"
    t.string "hashtags_serialized", default: "--- []\n"
    t.string "in_reply_to_status_id_code"
    t.string "in_reply_to_user_id_code"
    t.string "in_reply_to_username"
    t.boolean "is_quote_status"
    t.datetime "last_fetched_at"
    t.text "media_serialized", default: "--- []\n"
    t.string "mentioned_usernames_serialized", default: "--- []\n"
    t.string "profile_image"
    t.string "quoted_tweet_id_code"
    t.integer "retweet_count"
    t.string "source"
    t.string "text"
    t.datetime "tweeted_at"
    t.string "twitter_id_code"
    t.string "twitter_name"
    t.string "twitter_uid"
    t.integer "twitter_user_followers_count"
    t.integer "twitter_user_following_count"
    t.string "twitter_username"
    t.datetime "updated_at", null: false
    t.text "urls_serialized", default: "--- []\n"
    t.integer "user_id"
    t.boolean "user_is_verified"
  end

  create_table "user_blocks", force: :cascade do |t|
    t.bigint "blocked_id", null: false
    t.bigint "blocker_id", null: false
    t.string "config", default: "default", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id", "blocker_id"], name: "index_user_blocks_on_blocked_id_and_blocker_id", unique: true
  end

  create_table "user_counters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["data"], name: "index_user_counters_on_data", using: :gin
    t.index ["user_id"], name: "index_user_counters_on_user_id", unique: true
  end

  create_table "user_optional_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "value", null: false
    t.index ["label", "user_id"], name: "index_user_optional_fields_on_label_and_user_id", unique: true
    t.index ["user_id"], name: "index_user_optional_fields_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.string "available_for"
    t.integer "badge_achievements_count", default: 0, null: false
    t.string "behance_url"
    t.string "bg_color_hex"
    t.bigint "blocked_by_count", default: 0, null: false
    t.bigint "blocking_others_count", default: 0, null: false
    t.boolean "checked_code_of_conduct", default: false
    t.boolean "checked_terms_and_conditions", default: false
    t.integer "comments_count", default: 0, null: false
    t.string "config_font", default: "default"
    t.string "config_navbar", default: "default", null: false
    t.string "config_theme", default: "default"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.boolean "contact_consent", default: false
    t.datetime "created_at", null: false
    t.integer "credits_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "currently_hacking_on"
    t.string "currently_learning"
    t.string "currently_streaming_on"
    t.boolean "display_sponsors", default: true
    t.string "dribbble_url"
    t.string "editor_version", default: "v1"
    t.string "education"
    t.string "email"
    t.boolean "email_badge_notifications", default: true
    t.boolean "email_comment_notifications", default: true
    t.boolean "email_community_mod_newsletter", default: false
    t.boolean "email_connect_messages", default: true
    t.boolean "email_digest_periodic", default: true, null: false
    t.boolean "email_follower_notifications", default: true
    t.boolean "email_membership_newsletter", default: false
    t.boolean "email_mention_notifications", default: true
    t.boolean "email_newsletter", default: true
    t.boolean "email_public", default: false
    t.boolean "email_tag_mod_newsletter", default: false
    t.boolean "email_unread_notifications", default: true
    t.string "employer_name"
    t.string "employer_url"
    t.string "employment_title"
    t.string "encrypted_password", default: "", null: false
    t.integer "experience_level"
    t.boolean "export_requested", default: false
    t.datetime "exported_at"
    t.string "facebook_url"
    t.boolean "feed_admin_publish_permission", default: true
    t.datetime "feed_fetched_at", default: "2017-01-01 05:00:00"
    t.boolean "feed_mark_canonical", default: false
    t.boolean "feed_referential_link", default: true, null: false
    t.string "feed_url"
    t.integer "following_orgs_count", default: 0, null: false
    t.integer "following_tags_count", default: 0, null: false
    t.integer "following_users_count", default: 0, null: false
    t.datetime "github_created_at"
    t.datetime "github_repos_updated_at", default: "2017-01-01 05:00:00"
    t.string "github_username"
    t.string "gitlab_url"
    t.string "inbox_guidelines"
    t.string "inbox_type", default: "private"
    t.string "instagram_url"
    t.jsonb "language_settings", default: {}, null: false
    t.datetime "last_article_at", default: "2017-01-01 05:00:00"
    t.datetime "last_comment_at", default: "2017-01-01 05:00:00"
    t.datetime "last_followed_at"
    t.datetime "last_moderation_notification", default: "2017-01-01 05:00:00"
    t.datetime "last_notification_activity"
    t.string "last_onboarding_page"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.string "linkedin_url"
    t.string "location"
    t.boolean "looking_for_work", default: false
    t.boolean "looking_for_work_publicly", default: false
    t.string "mastodon_url"
    t.string "medium_url"
    t.boolean "mobile_comment_notifications", default: true
    t.boolean "mod_roundrobin_notifications", default: true
    t.integer "monthly_dues", default: 0
    t.string "mostly_work_with"
    t.string "name"
    t.string "old_old_username"
    t.string "old_username"
    t.boolean "onboarding_package_requested", default: false
    t.datetime "organization_info_updated_at"
    t.boolean "permit_adjacent_sponsors", default: true
    t.string "profile_image"
    t.datetime "profile_updated_at", default: "2017-01-01 05:00:00"
    t.integer "rating_votes_count", default: 0, null: false
    t.integer "reactions_count", default: 0, null: false
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.float "reputation_modifier", default: 1.0
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "saw_onboarding", default: true
    t.integer "score", default: 0
    t.string "secret"
    t.integer "sign_in_count", default: 0, null: false
    t.string "signup_cta_variant"
    t.integer "spent_credits_count", default: 0, null: false
    t.string "stackoverflow_url"
    t.string "stripe_id_code"
    t.text "summary"
    t.string "text_color_hex"
    t.string "twitch_url"
    t.string "twitch_username"
    t.datetime "twitter_created_at"
    t.integer "twitter_followers_count"
    t.integer "twitter_following_count"
    t.string "twitter_username"
    t.string "unconfirmed_email"
    t.integer "unspent_credits_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "website_url"
    t.boolean "welcome_notifications", default: true, null: false
    t.datetime "workshop_expiration"
    t.string "youtube_url"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_username"], name: "index_users_on_github_username", unique: true
    t.index ["language_settings"], name: "index_users_on_language_settings", using: :gin
    t.index ["old_old_username"], name: "index_users_on_old_old_username"
    t.index ["old_username"], name: "index_users_on_old_username"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["twitter_username"], name: "index_users_on_twitter_username", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "events", null: false, array: true
    t.bigint "oauth_application_id"
    t.string "source"
    t.string "target_url", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["events"], name: "index_webhook_endpoints_on_events"
    t.index ["oauth_application_id"], name: "index_webhook_endpoints_on_oauth_application_id"
    t.index ["target_url"], name: "index_webhook_endpoints_on_target_url", unique: true
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  add_foreign_key "api_secrets", "users", on_delete: :cascade
  add_foreign_key "audit_logs", "users"
  add_foreign_key "badge_achievements", "badges"
  add_foreign_key "badge_achievements", "users"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "classified_listings", "classified_listing_categories"
  add_foreign_key "classified_listings", "users", on_delete: :cascade
  add_foreign_key "email_authorizations", "users", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "messages", "chat_channels"
  add_foreign_key "messages", "users"
  add_foreign_key "notification_subscriptions", "users", on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "page_views", "articles", on_delete: :cascade
  add_foreign_key "podcasts", "users", column: "creator_id"
  add_foreign_key "response_templates", "users"
  add_foreign_key "sponsorships", "organizations"
  add_foreign_key "sponsorships", "users"
  add_foreign_key "tag_adjustments", "articles", on_delete: :cascade
  add_foreign_key "tag_adjustments", "tags", on_delete: :cascade
  add_foreign_key "tag_adjustments", "users", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocked_id"
  add_foreign_key "user_blocks", "users", column: "blocker_id"
  add_foreign_key "user_counters", "users", on_delete: :cascade
  add_foreign_key "user_optional_fields", "users"
  add_foreign_key "users_roles", "users", on_delete: :cascade
  add_foreign_key "webhook_endpoints", "oauth_applications"
  add_foreign_key "webhook_endpoints", "users"
end
