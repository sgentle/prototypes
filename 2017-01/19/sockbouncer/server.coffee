WebSocket = require 'ws'

wss = new WebSocket.Server port: process.env.PORT or 8080

broadcast = (data) ->
  client.send data for client in wss.clients when client.readyState is WebSocket.OPEN

wss.on 'connection', (ws) ->
  ws.on 'message', (data) ->
    broadcast data
