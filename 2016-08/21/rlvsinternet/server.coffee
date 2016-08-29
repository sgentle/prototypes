express = require 'express'
bodyParser = require 'body-parser'

app = express()

app.use express.static 'public'
app.use bodyParser.json()

values =
  internet: 0
  irl: 0

force = true

nextPing = 0
DEBOUNCE = 1000
app.get '/', (req, res) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.send JSON.stringify {internet: values.internet, irl: values.irl, nextPing}

app.post '/ping', (req, res) ->
  res.header 'Access-Control-Allow-Origin', '*'
  now = Date.now()
  res.send()
  console.log("now", now, "nextPing", nextPing)
  return if now < nextPing
  nextPing = now + DEBOUNCE
  values.internet++

app.post '/', (req, res) ->
  res.header 'Access-Control-Allow-Origin', '*'
  console.log "received", req.body
  for k, oldval of values
    newval = req.body[k]
    if newval and newval > oldval
      values[k] = newval

  if force
    force = false
    data = {}
    data[k] = v for k, v of values
    data.force = true
    res.send JSON.stringify data
  else
    res.send JSON.stringify values


app.listen '9999'
