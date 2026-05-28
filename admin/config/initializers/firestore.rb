# Firestore クライアント(emulator 経由)
# テスト環境では FakeFirestore に差し替え
if Rails.env.test?
  require_relative "../../test/support/fake_firestore"
  FIRESTORE = Fakes::FakeFirestore.new
else
  require "google/cloud/firestore"
  ENV["FIRESTORE_EMULATOR_HOST"] ||= "firestore:8080"
  FIRESTORE = Google::Cloud::Firestore.new(
    project_id:  ENV.fetch("GOOGLE_CLOUD_PROJECT", "chaincross-local"),
    credentials: EmulatorAuth::NullCredentials.new
  )
end

