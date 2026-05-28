require "test_helper"

class CollabsControllerTest < ActionDispatch::IntegrationTest
  test "GET /collabs lists collabs" do
    Collab.create!(name: "C1", symbol: "C1", start_at: "2026-06-01T00:00:00Z",
                   end_at: "2026-06-30T00:00:00Z", title_ids: [], deployed: false, swept: false)
    get collabs_path
    assert_response :success
    assert_match "C1", @response.body
  end

  test "POST /collabs creates a collab" do
    Title.create!(name: "A", code: "title-a", endpoint: "x")

    assert_difference -> { Collab.all.size }, 1 do
      post collabs_path, params: {
        collab: {
          name: "Summer", symbol: "SUM",
          start_at: "2026-07-01T00:00:00Z", end_at: "2026-07-31T00:00:00Z",
          title_ids: ["title-a"]
        }
      }
    end
    assert_redirected_to collabs_path
  end

  test "POST /collabs/:id/deploy deploys via chain and enables titles" do
    c = Collab.create!(name: "X", symbol: "X",
                       start_at: "2026-06-01T00:00:00Z", end_at: "2026-06-30T00:00:00Z",
                       title_ids: %w[title-a title-b], deployed: false, swept: false)

    post deploy_collab_path(c)
    assert_redirected_to collab_path(c)

    assert Collab.find(c.id)[:deployed]
    # FakeChainClient へ呼び出しが伝わっているか
    kinds = @fake_chain.calls.map(&:first)
    assert_includes kinds, :create_collab
    assert_equal 2, kinds.count(:set_title_enabled)
  end

  test "POST /collabs/:id/sweep marks collab swept" do
    c = Collab.create!(name: "X", symbol: "X",
                       start_at: "2026-06-01T00:00:00Z", end_at: "2026-06-02T00:00:00Z",
                       title_ids: ["title-a"], deployed: true, swept: false)
    # FakeChainClient 側にもコラボ作成 (期間外で sweep するため endAt < now になるよう古い日付)
    @fake_chain.create_collab(collab_id: c.id, name: "X", symbol: "X",
                              start_at: Time.utc(2026, 6, 1), end_at: Time.utc(2026, 6, 2))
    # 現在時刻を end より後にする
    travel_to Time.utc(2026, 6, 3) do
      post sweep_collab_path(c)
    end
    assert_redirected_to collab_path(c)
    assert Collab.find(c.id)[:swept]
  end
end

