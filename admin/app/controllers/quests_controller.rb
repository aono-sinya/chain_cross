class QuestsController < ApplicationController
  before_action :set_collab

  def index;  @quests = @collab.quests; end
  def new;    @quest  = Quest.new; @titles = Title.all; end

  def create
    Quest.create!(params.require(:quest).permit(:title_id, :name, :reward_amount).to_h.merge(collab_id: @collab.id))
    redirect_to collab_quests_path(@collab)
  end

  def destroy
    Quest.find(params[:id])&.destroy!
    redirect_to collab_quests_path(@collab)
  end

  private
  def set_collab; @collab = Collab.find(params[:collab_id]); end
end

