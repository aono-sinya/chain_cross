class CollabsController < ApplicationController
  def index;   @collabs = Collab.all; end
  def show;    @collab  = Collab.find(params[:id]); end
  def new;     @collab  = Collab.new; @titles = Title.all; end

  def create
    attrs = params.require(:collab).permit(:name, :symbol, :start_at, :end_at, title_ids: []).to_h
    attrs[:deployed] = false
    attrs[:swept]    = false
    Collab.create!(attrs)
    redirect_to collabs_path
  end

  def destroy
    Collab.find(params[:id])&.destroy!
    redirect_to collabs_path
  end

  # コラボをチェーンへデプロイ + タイトル権限付与
  def deploy
    collab = Collab.find(params[:id])
    tx = chain.create_collab(
      collab_id: collab.id,
      name:      collab.name.to_s,
      symbol:    collab.symbol.to_s,
      start_at:  collab.start_time,
      end_at:    collab.end_time
    )
    Array(collab.title_ids).each do |tid|
      chain.set_title_enabled(collab_id: collab.id, title_id: tid, enabled: true)
    end
    collab.update!(deployed: true, deploy_tx: tx["transactionHash"])
    redirect_to collab_path(collab), notice: "Deployed: #{tx['transactionHash']}"
  rescue => e
    redirect_to collab_path(collab), alert: "Deploy failed: #{e.message}"
  end

  # コラボ終了後の通貨消滅
  def sweep
    collab = Collab.find(params[:id])
    chain.sweep_collab(collab_id: collab.id)
    collab.update!(swept: true)
    redirect_to collab_path(collab), notice: "Swept"
  rescue => e
    redirect_to collab_path(collab), alert: "Sweep failed: #{e.message}"
  end
end

