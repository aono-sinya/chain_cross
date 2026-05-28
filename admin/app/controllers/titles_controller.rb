class TitlesController < ApplicationController
  def index;  @titles = Title.all; end
  def new;    @title = Title.new;  end

  def create
    Title.create!(params.require(:title).permit(:name, :code, :endpoint).to_h)
    redirect_to titles_path
  end

  def destroy
    Title.find(params[:id])&.destroy!
    redirect_to titles_path
  end
end

