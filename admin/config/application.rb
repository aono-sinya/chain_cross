# Rails 設定エントリポイント
require_relative "boot"

require "rails"
# ActiveRecord は使わないので個別 require
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
# Propshaft は Railtie の auto-require があるので個別 require 不要

Bundler.require(*Rails.groups)

module ChaincrossAdmin
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = false
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "UTC"

    # CSRF を簡素化(社内ツール想定 + ゲームモック疎通)
    config.action_controller.default_protect_from_forgery = false
  end
end

