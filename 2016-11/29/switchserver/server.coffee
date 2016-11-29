rcswitch = require 'rcswitch-gpiomem'
rcswitch.enableTransmit 17
rcswitch.setPulseLength 260
rcswitch.setRepeatTransmit 5

data =
  desk:
    on: 3761262431
    off: 3761260368
  room:
    on: 3761261400
    off: 3761259348
  tv:
    on: 3761261916
    off: 3761259858
  fan:
    on: 3761262174
    off: 3761260113
  all:
    on: 3761259603
    off: 3761260635

  lights: ['desk', 'room']

express = require 'express'
bodyParser = require 'body-parser'

app = express()
app.use bodyParser.json()

commandQueue = Promise.resolve()
wait = (t) -> new Promise (resolve) -> setTimeout resolve, t

send = (val) ->
  commandQueue = commandQueue
  .then ->
    rcswitch.send val, 32
  .then ->
    wait 150
  .catch (e) ->
    commandQueue = Promise.resolve()
    throw e

app.post '/', (req, res) ->
  b = req.body
  return unless data[b.item]


  if Array.isArray data[b.item]
    for item in data[b.item] when data[item]?[b.state]
      send data[item][b.state]

    commandQueue.then -> res.sendStatus 200
  else
    return res.sendStatus(400) unless data[b.item]?[b.state]

    send data[b.item][b.state]
    .then -> res.sendStatus 200

port = process.env.PORT or 3000
app.listen port
console.log "listening on #{port}"
