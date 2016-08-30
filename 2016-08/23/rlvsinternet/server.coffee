express = require 'express'
bodyParser = require 'body-parser'
Redis = require 'ioredis'
WebSocketServer = require('ws').Server
httpServer = require('http').createServer()
net = require 'net'

redis = new Redis()
wss = new WebSocketServer server: httpServer, path: '/sock'

app = express()


app.use express.static 'public'
app.use bodyParser.json()

values =
  internet: 0
  irl: 0

nextPing = new Date('2019-08-22T22:30:00.000Z').getTime()

clientValues = {}
clientValues[k] = v for k, v of values
clientValueString = JSON.stringify clientValues

force = true
connected = false

app.use (req, res, next) ->
  if connected then next() else res.status(500).send()

redis.get('values').then (newvalues) ->
  connected = true
  console.log "Server: ready", newvalues
  if newvalues
    values = JSON.parse newvalues
    clientUpdate()
  console.log "values", values

update = ->
  str = JSON.stringify values

  redis.set 'values', str
  hourstamp = new Date().toISOString().slice(0,13)
  redis.set "values-#{hourstamp}", str
  clientUpdate()
  panelUpdate()

getPanelData = ->
  return {} unless connected

  if force
    force = false
    data = {}
    data[k] = v for k, v of values
    data.force = true
    JSON.stringify data
  else
    JSON.stringify values

panelUpdate = ->
  return unless currentSock
  currentSock.write getPanelData() + '\n'

clientUpdate = ->
  clientValues[k] = v for k, v of values
  clientValues.nextPing = nextPing
  clientValueString = JSON.stringify clientValues

  client.send clientValueString for client in wss.clients

DEBOUNCE = 1000
app.get '/data', (req, res) ->
  res.send clientValueString

handlePing = ->
  now = Date.now()
  console.log("now", now, "nextPing", nextPing)
  return if now < nextPing
  nextPing = now + DEBOUNCE
  values.internet++
  update()

app.post '/ping', (req, res) ->
  res.send()
  handlePing()

wss.on 'connection', (ws) ->
  ws.send clientValueString
  ws.on 'message', (msg) -> handlePing()

updateFromPanel = (data) ->
  console.log "panel update", data
  updates = false
  for k, oldval of values
    newval = data[k]
    if newval and newval > oldval
      values[k] = newval
      updates = true

  update() if updates


SECRET = 'xxx'
app.post '/panel', (req, res) ->
  return res.statusCode(403) unless req.query.secret is SECRET
  ret = updateFromPanel req.body
  res.send getPanelData()

currentSock = null

sockServer = net.createServer (socket) ->
  authed = false
  socket.on 'data', (_msg) ->
    msg = _msg.toString().trim()
    console.log (if authed then "authed" else "unauthed"), "read", msg
    if authed
      try
        data = JSON.parse msg
        updateFromPanel data
      catch e
        console.error(e)
    else
      if msg is SECRET
        authed = true
        console.log "sock authed"
        currentSock = socket
        socket.write getPanelData() + '\n'
   socket.on 'error', (err) ->
     console.error err

   socket.on 'end', ->
     currentSock = null if currentSock is socket
     console.log "socket finished"

sockServer.listen 9999

httpServer.on 'request', app
httpServer.listen process.env.PORT or 80
