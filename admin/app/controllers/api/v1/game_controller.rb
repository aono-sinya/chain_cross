module Api
  module V1
    class GameController < ActionController::API
      # POST /api/v1/quests/clear
      # body: { collab_id, title_id, player_id, quest_id }
      def clear_quest
        collab = Collab.find(params[:collab_id]) or return render(json: { error: "no collab" }, status: 404)
        quest  = Quest.find(params[:quest_id])   or return render(json: { error: "no quest"  }, status: 404)

        unless Array(collab.title_ids).include?(params[:title_id])
          return render(json: { error: "title not in collab" }, status: 422)
        end

        tx = chain.mint_for_quest(
          collab_id: collab.id,
          title_id:  params[:title_id],
          player_id: params[:player_id],
          quest_id:  quest.id,
          amount:    quest.reward_amount.to_i
        )
        render json: { ok: true, tx_hash: tx["transactionHash"], block: tx["blockNumber"] }
      rescue => e
        render json: { error: e.message }, status: 500
      end

      # POST /api/v1/rewards/redeem
      def redeem_reward
        collab = Collab.find(params[:collab_id]) or return render(json: { error: "no collab" }, status: 404)
        reward = Reward.find(params[:reward_id]) or return render(json: { error: "no reward" }, status: 404)

        tx = chain.redeem_reward(
          collab_id: collab.id,
          title_id:  params[:title_id],
          player_id: params[:player_id],
          reward_id: reward.id,
          cost:      reward.cost.to_i
        )
        render json: { ok: true, tx_hash: tx["transactionHash"], block: tx["blockNumber"] }
      rescue => e
        render json: { error: e.message }, status: 500
      end

      def balance
        bal = chain.balance_of(
          collab_id: params[:collab_id],
          title_id:  params[:title_id],
          player_id: params[:player_id]
        )
        render json: { balance: bal.to_i }
      rescue => e
        render json: { error: e.message }, status: 500
      end

      private
      def chain; @chain ||= ChainClient.new; end
    end
  end
end

