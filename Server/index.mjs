import express from "express";
import http from "http";
import { WebSocketServer } from "ws";

const MAP_WIDTH = 100;
const MAP_HEIGHT = 60;

const app = express();
const httpServer = http.createServer(app);
const socketServer = new WebSocketServer({ server: httpServer });

let currentPlayerId = 1;

const players = [];
const map = [];
for (let x = 0; x < MAP_WIDTH; ++x) {
  map.push([]);
  for (let y = 0; y < MAP_HEIGHT; ++y) {
    map[x].push(0);
  }
}

function sendTo(player, data) {
  player.send(JSON.stringify(data));
}

function sendToAll(data) {
  for (const player of players) {
    sendTo(player, data);
  }
}

function clearFromMap(player) {
  for (let x = 0; x < MAP_WIDTH; ++x) {
    for (let y = 0; y < MAP_HEIGHT; ++y) {
      if (map[x][y] === player.id) {
        map[x][y] = 0;
      }
    }
  }
  sendToAll({ type: "clear", id: player.id });
}

function spawnOnMap(player) {
  player.x = Math.floor(Math.random() * (MAP_WIDTH - 40)) + 20;
  player.y = Math.floor(Math.random() * (MAP_HEIGHT - 30)) + 15;
  player.direction = Math.floor(Math.random() * 4);

  sendTo(player, {
    type: "spawn",
    id: player.id,
    x: player.x,
    y: player.y,
  });

  sendToAll({
    type: "move",
    id: player.id,
    x: player.x,
    y: player.y,
  });
}

function respawn(player) {
  clearFromMap(player);
  spawnOnMap(player);
}

socketServer.on("connection", (player) => {
  player.id = currentPlayerId++;

  spawnOnMap(player);

  console.log("Player connected", player.id, player.x, player.y, player.direction);

  players.push(player);

  sendTo(player, { type: "map", map });

  player.on("message", (raw) => {
    try {
      const message = JSON.parse(raw);
      if (!message || !(typeof message.direction === "number")) return;
      const direction = parseInt(message.direction, 10);
      if (direction >= 0 && direction <= 3) {
        player.direction = direction;
      }
    } catch (e) {
      console.error(e);
      player.close();
    }
  });

  player.on("close", () => {
    console.log("Player disconnected", player.id, player.x, player.y, player.direction);
    clearFromMap(player);
    const index = players.indexOf(player);
    if (index > -1) {
      players.splice(index, 1);
    }
  });
});

httpServer.listen(8080, () => console.log("Listening on port 8080"));

setInterval(() => {
  for (const player of players) {
    if (player.direction === 0) player.y -= 1;
    if (player.direction === 1) player.y += 1;
    if (player.direction === 2) player.x -= 1;
    if (player.direction === 3) player.x += 1;

    if (player.x < 0 || player.y < 0 || player.x >= MAP_WIDTH || player.y >= MAP_HEIGHT || map[player.x][player.y] > 0) {
      respawn(player);
    } else {
      map[player.x][player.y] = player.id;
      sendToAll({
        type: "move",
        id: player.id,
        x: player.x,
        y: player.y,
      });
    }
  }
}, 150);
