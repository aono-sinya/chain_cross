require "test_helper"

class FirestoreModelTest < ActiveSupport::TestCase
  test "Title CRUD round-trips through Firestore stub" do
    t = Title.create!(name: "Game A", code: "title-a", endpoint: "http://game-a:4001")
    assert t.id.present?

    found = Title.find(t.id)
    assert_equal "Game A",    found.name
    assert_equal "title-a",   found.code
    assert_equal "http://game-a:4001", found.endpoint

    Title.create!(name: "Game B", code: "title-b", endpoint: "http://game-b:4002")
    assert_equal 2, Title.all.size

    found.destroy!
    assert_nil Title.find(t.id)
  end

  test "Quest.where filters by collab_id" do
    Quest.create!(collab_id: "c1", title_id: "title-a", name: "Q1", reward_amount: 10)
    Quest.create!(collab_id: "c1", title_id: "title-b", name: "Q2", reward_amount: 20)
    Quest.create!(collab_id: "c2", title_id: "title-a", name: "Q3", reward_amount: 30)

    in_c1 = Quest.where(collab_id: "c1")
    assert_equal 2, in_c1.size
    assert_equal %w[Q1 Q2].sort, in_c1.map(&:name).sort
  end

  test "Reward.where filters by collab_id" do
    Reward.create!(collab_id: "c1", title_id: "title-a", name: "R1", cost: 100)
    Reward.create!(collab_id: "c2", title_id: "title-a", name: "R2", cost: 200)
    assert_equal ["R1"], Reward.where(collab_id: "c1").map(&:name)
  end

  test "Collab has child quests/rewards via Firestore" do
    c = Collab.create!(name: "Spring Collab", symbol: "SPR",
                       start_at: "2026-06-01T00:00:00Z", end_at: "2026-06-30T00:00:00Z",
                       title_ids: %w[title-a title-b], deployed: false, swept: false)
    Quest.create!(collab_id: c.id, title_id: "title-a", name: "Q", reward_amount: 5)
    Reward.create!(collab_id: c.id, title_id: "title-a", name: "R", cost: 5)

    assert_equal 1, c.quests.size
    assert_equal 1, c.rewards.size
    assert_equal Time.utc(2026, 6, 1),  c.start_time
    assert_equal Time.utc(2026, 6, 30), c.end_time
  end
end

