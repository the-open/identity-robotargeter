class CreateRobotargeterTestDb < ActiveRecord::Migration[5.0]
  def up
    create_table 'callees', force: true do |t|
      t.string   'tijuana_id'
      t.string   'nationbuilder_id'
      t.datetime 'created_at',                         default: 'now()'
      t.datetime 'updated_at',                         default: 'now()'
      t.string   'first_name'
      t.string   'last_name'
      t.string   'mobile_number'
      t.string   'home_number'
      t.string   'location'
      t.string   'timezone'
      t.boolean  'created_from_incoming'
      t.datetime 'last_called_at'
      t.integer  'call_count'
      t.datetime 'last_survey_started_at'
      t.datetime 'last_survey_completed_at'
      t.text     'api_response'
      t.string   'campaign'
      t.boolean  'callable', default: true
      t.integer  'campaign_id', limit: 8
      t.integer  'audience_id', limit: 8
      t.datetime 'opted_out_at'
      t.string   "external_id", limit: 255
      t.json     'data'
    end

    add_index 'callees', ['campaign_id', 'mobile_number'], name: 'callees_campaign_id_mobile_number_unique', unique: true, using: :btree

    create_table 'calls', { id: :string, force: true } do |t|
      t.integer  'callee_id'
      t.datetime 'created_at',              default: 'now()'
      t.datetime 'updated_at',              default: 'now()'
      t.boolean  'outgoing'
      t.string   'plivo_number'
      t.string   'callee_number'
      t.string   'status'
      t.string   'hangup_cause'
      t.string   'machine'
      t.integer  'duration'
      t.integer  'bill_duration'
      t.integer  'campaign_id', limit: 8
    end

    create_table 'campaigns', force: true do |t|
      t.datetime 'created_at',                  default: 'now()'
      t.datetime 'updated_at',                  default: 'now()'
      t.string   'name', null: false
      t.string   'status'
      t.string   'intro', null: false
      t.text     "target_numbers", array: true
      t.string   'phone_number'
      t.text     'caller_id'
      t.boolean  'outbound',                    default: false
      t.integer  'no_call_window_in_hours',     default: 24
      t.integer  'max_call_attempts',           default: 1
      t.string   'daily_start',                 default: '0900'
      t.string   'daily_finish',                default: '1700'
      t.json     'questions'
      t.boolean  'transparent_target_transfer', default: true
      t.boolean  "sync_to_identity",            default: true
    end

    add_index 'campaigns', ['name'], name: 'campaigns_name_index', using: :btree
    add_index 'campaigns', ['status'], name: 'campaigns_status_index', using: :btree

    create_table 'events', force: true do |t|
      t.datetime 'created_at',            default: 'now()'
      t.datetime 'updated_at',            default: 'now()'
      t.string   'name', null: false
      t.text     'value'
      t.integer  'campaign_id', limit: 8
      t.string   'call_id'
    end

    create_table 'knex_migrations', force: true do |t|
      t.string   'name'
      t.integer  'batch'
      t.datetime 'migration_time'
    end

    create_table 'logs', force: true do |t|
      t.datetime 'created_at', default: 'now()'
      t.string   'uuid'
      t.string   'url'
      t.text     'body'
      t.text     'query'
      t.text     'params'
      t.text     'headers'
    end

    create_table 'redirects', force: true do |t|
      t.datetime 'created_at', default: 'now()'
      t.string   'call_uuid'
      t.integer  'campaign_id',     limit: 8, null: false
      t.integer  'callee_id',       limit: 8
      t.string   'phone_number'
      t.string   'redirect_number'
      t.string   'target_number'
    end

    add_index 'redirects', ['campaign_id'], name: 'redirects_campaign_id_index', using: :btree

    create_table 'survey_results', force: true do |t|
      t.integer  'log_id', limit: 8
      t.datetime 'created_at',           default: 'now()'
      t.datetime 'updated_at',           default: 'now()'
      t.string   'call_id'
      t.string   'question'
      t.string   'answer'
    end

    create_table 'audiences', force: true do |t|
      t.integer  'sync_id', limit: 8
      t.integer  'campaign_id', limit: 8
      t.integer  "priority",    limit: 8, default: 1
      t.string   'status', default: "initialising"
      t.datetime 'updated_at', default: 'now()'
    end
    execute "ALTER TABLE audiences ADD CONSTRAINT audiences_sync_id_campaign_id_unique UNIQUE (sync_id, campaign_id)"
  end
end
