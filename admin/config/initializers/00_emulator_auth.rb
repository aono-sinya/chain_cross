# BigQuery / Firestore エミュレータ用のダミー認証情報
require "googleauth"

module EmulatorAuth
  class NullCredentials < Google::Auth::Credentials
    def initialize(*_); end
    def apply!(_md); end
    def apply(md); md; end
    def updater_proc; ->(md) { md }; end
    def project_id; ENV["GOOGLE_CLOUD_PROJECT"]; end
    def quota_project_id; nil; end
    def universe_domain; "googleapis.com"; end
  end
end

