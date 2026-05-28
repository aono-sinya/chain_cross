# BigQuery (emulator) クライアント
# テスト環境では何もしない (ワーカーは別途モック)
if Rails.env.test?
  BIGQUERY = nil
else
  require "google/cloud/bigquery"
  ENV["BIGQUERY_EMULATOR_HOST"] ||= "bigquery:9050"
  BIGQUERY = Google::Cloud::Bigquery.new(
    project_id: ENV.fetch("GOOGLE_CLOUD_PROJECT", "chaincross-local"),
    endpoint:   "http://#{ENV['BIGQUERY_EMULATOR_HOST']}"
  )

  Rails.application.config.after_initialize do
    begin
      ds = BIGQUERY.dataset(ENV.fetch("BIGQUERY_DATASET", "chaincross")) ||
           BIGQUERY.create_dataset(ENV.fetch("BIGQUERY_DATASET", "chaincross"))

      unless ds.table("tx_logs")
        ds.create_table("tx_logs") do |t|
          t.schema do |s|
            s.string  "event_type",  mode: :required
            s.string  "collab_id"
            s.string  "title_id"
            s.string  "player_id"
            s.string  "quest_id"
            s.string  "reward_id"
            s.integer "amount"
            s.string  "tx_hash"
            s.integer "block_number"
            s.timestamp "occurred_at"
          end
        end
      end
    rescue => e
      Rails.logger.warn("[bigquery] init skipped: #{e.message}")
    end
  end
end

