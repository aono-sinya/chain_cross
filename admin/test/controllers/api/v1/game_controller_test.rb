require "test_helper"

class Api::V1::GameControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    @collab = Collab.create!(
      name: "C", symbol: "C",
      start_at: "2026-06-01T00:00:00Z", end_at: "2026-06-30T00:00:00Z",
      title_ids: ["title-a"], deployed: true, swept: false
    )
    @fake_chain.create_collab(
      collab_id: @collab.id, name: "C", symbol: "C",
      start_at: Time.utc(2026, 6, 1), end_at: Time.utc(2026, 6, 30)
    )
    @fake_chain.set_title_enabled(collab_id: @collab.id, title_id: "title-a", enabled: true)
    @quest  = Quest.create!(collab_id: @collab.id, title_id: "title-a", name: "Q", reward_amount: 100)
    @reward = Reward.create!(collab_id: @collab.id, title_id: "title-a", name: "R", cost: 30)
  end

  test "POST quests/clear mints currency" do
    travel_to Time.utc(2026, 6, 15) do
      post "/api/v1/quests/clear",
           params: { collab_id: @collab.id, title_id: "title-a",
                     player_id: "user-001", quest_id: @quest.id }
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert json["ok"]
    assert_equal 100, @fake_chain.balance_of(collab_id: @collab.id, title_id: "title-a", player_id: "user-001")
  end

  test "POST rewards/redeem burns currency" do
    travel_to Time.utc(2026, 6, 15) do
      @fake_chain.mint_for_quest(collab_id: @collab.id, title_id: "title-a",
                                 player_id: "user-001", quest_id: @quest.id, amount: 50)
      post "/api/v1/rewards/redeem",
           params: { collab_id: @collab.id, title_id: "title-a",
                     player_id: "user-001", reward_id: @reward.id }
    end
    assert_response :success
    assert_equal 20, @fake_chain.balance_of(collab_id: @collab.id, title_id: "title-a", player_id: "user-001")
  end

  test "POST quests/clear rejects unknown collab" do
    post "/api/v1/quests/clear",
         params: { collab_id: "nope", title_id: "title-a", player_id: "x", quest_id: @quest.id }
    assert_response :not_found
  end

  test "POST quests/clear rejects title not in collab" do
    post "/api/v1/quests/clear",
         params: { collab_id: @collab.id, title_id: "title-b",
                   player_id: "x", quest_id: @quest.id }
    assert_response :unprocessable_entity
  end

  test "GET balance returns 0 outside collab period" do
    # 期間前
    travel_to Time.utc(2026, 5, 1) do
      get "/api/v1/players/title-a/user-001/balance/#{@collab.id}"
    end
    assert_response :success
    assert_equal 0, JSON.parse(@response.body)["balance"]
  end
end

