ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require_relative "support/fake_firestore"
require_relative "support/fake_chain_client"

# テスト時は全コントローラを先にロードして prepend で chain を差し替える
Rails.application.eager_load!

module FakeChainHelper
  def chain
    Thread.current[:fake_chain] ||= FakeChainClient.new
  end
end

ApplicationController.prepend(FakeChainHelper)
Api::V1::GameController.prepend(FakeChainHelper) if defined?(Api::V1::GameController)

module ChainStubbing
  def setup
    super if defined?(super)
    FIRESTORE.reset! if FIRESTORE.respond_to?(:reset!)
    @fake_chain = FakeChainClient.new
    Thread.current[:fake_chain] = @fake_chain
  end

  def teardown
    Thread.current[:fake_chain] = nil
    super if defined?(super)
  end
end

class ActiveSupport::TestCase
  include ChainStubbing
  include ActiveSupport::Testing::TimeHelpers
end



