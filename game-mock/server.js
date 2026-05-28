// 簡易ゲームタイトルモック。プレイヤーがクエストをクリア/報酬を交換すると
// 管理APIに転送し、Besu のコラボ通貨を mint/burn してもらう。
import express from "express";
import fetch from "node-fetch";

const TITLE_ID  = process.env.TITLE_ID  || "title-a";
const TITLE_NAME = process.env.TITLE_NAME || "Game";
const PORT       = process.env.PORT || 4001;
const ADMIN      = process.env.ADMIN_API_BASE || "http://admin:3000";

const app = express();
app.use(express.json());

app.get("/", (_req, res) => {
  res.json({ ok: true, title: TITLE_NAME, titleId: TITLE_ID });
});

// プレイヤーがクエストをクリア
// body: { collabId, questId, playerId }
app.post("/quests/clear", async (req, res) => {
  const { collabId, questId, playerId } = req.body;
  const r = await fetch(`${ADMIN}/api/v1/quests/clear`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ collab_id: collabId, quest_id: questId, player_id: playerId, title_id: TITLE_ID })
  });
  res.status(r.status).send(await r.text());
});

// プレイヤーが報酬を交換
// body: { collabId, rewardId, playerId }
app.post("/rewards/redeem", async (req, res) => {
  const { collabId, rewardId, playerId } = req.body;
  const r = await fetch(`${ADMIN}/api/v1/rewards/redeem`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ collab_id: collabId, reward_id: rewardId, player_id: playerId, title_id: TITLE_ID })
  });
  res.status(r.status).send(await r.text());
});

// プレイヤーのコラボ通貨残高
app.get("/players/:playerId/balance/:collabId", async (req, res) => {
  const { playerId, collabId } = req.params;
  const r = await fetch(`${ADMIN}/api/v1/players/${TITLE_ID}/${playerId}/balance/${collabId}`);
  res.status(r.status).send(await r.text());
});

app.listen(PORT, () => console.log(`[${TITLE_ID}] listening on :${PORT}`));

