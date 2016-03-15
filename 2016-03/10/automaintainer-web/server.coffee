express = require 'express'
fetch = require 'node-fetch'
generate = require './generate'
path = require 'path'
fs = require 'fs'

CACHEDIR = path.join(__dirname, 'cache')

app = express()

app.use express.static CACHEDIR

app.get '*', (req, res) ->
  name = req.path.slice(1)

  return res.status(404).send('not found') unless name
  return res.status(400).send('bad name') unless path.join(CACHEDIR, name).indexOf(CACHEDIR) == 0

  fetch "https://raw.githubusercontent.com/#{name}/automaintainer/automaintainer.json"
  .then (result) -> result.json()
  .then (data) ->
    # cacheStream = fs.createWriteStream path.join(CACHEDIR, name)
    pngStream = generate data.rules

    # pngStream.pipe cacheStream
    pngStream.pipe res

  .catch (e) ->
    res.status(500).send(e.message)

app.listen process.env.PORT or 3000

console.log "listening on", process.env.PORT