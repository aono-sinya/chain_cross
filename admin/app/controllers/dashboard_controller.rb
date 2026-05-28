class DashboardController < ApplicationController
  def index
    @titles  = Title.all
    @collabs = Collab.all
    @manager_address = CHAIN_CONFIG["collabManager"]
  end
end

