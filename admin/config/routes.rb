Rails.application.routes.draw do
  root "dashboard#index"

  resources :titles
  resources :collabs do
    member do
      post :deploy
      post :sweep
    end
    resources :quests
    resources :rewards
  end

  # Game-facing API (used by game-mock services)
  namespace :api do
    namespace :v1 do
      post  "quests/clear",   to: "game#clear_quest"
      post  "rewards/redeem", to: "game#redeem_reward"
      get   "players/:title_id/:player_id/balance/:collab_id", to: "game#balance"
    end
  end
end

