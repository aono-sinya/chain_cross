class RewardsController < ApplicationController
  before_action :set_collab

  def index;  @rewards = @collab.rewards; end
  def new;    @reward  = Reward.new; @titles = Title.all; end

  def create
    Reward.create!(params.require(:reward).permit(:title_id, :name, :cost).to_h.merge(collab_id: @collab.id))
    redirect_to collab_rewards_path(@collab)
  end

  def destroy
    Reward.find(params[:id])&.destroy!
    redirect_to collab_rewards_path(@collab)
  end

  private
  def set_collab; @collab = Collab.find(params[:collab_id]); end
end

