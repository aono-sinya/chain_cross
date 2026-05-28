class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, except: [:create, :update, :destroy] if respond_to?(:protect_from_forgery)
  helper_method :chain

  def chain
    @chain ||= ChainClient.new
  end
end

