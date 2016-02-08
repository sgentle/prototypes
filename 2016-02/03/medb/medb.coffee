influx = require 'influx'
homedir = require 'homedir'
path = require 'path'

config = require path.join(homedir(), '.medb.json')

client = influx(config.influx)

logthru = (msg) -> (result) -> console.log msg; result

console.log "Starting plugins"
plugins =
  for plugin, opts of config when plugin isnt 'influx'
    do (plugin) ->
      console.log "#{plugin} running"
      require("medb-#{plugin}")(opts)
      .then logthru "#{plugin} finished"

writePromised = (args...) -> new Promise (resolve, reject) ->
  client.writePoints args..., (err, result) ->
    if err then reject err else resolve result

Promise.all(plugins)
.then (results) ->
  console.log "Starting influx write"
  writes = []
  for result in results
    for series, data of result
      writes.push (
        writePromised(series, ([d.values, d.tags] for d in data))
        .then logthru "#{series} written"
      )
  Promise.all writes
.then (writes) ->
  console.log "Finished"
.catch (err) ->
  console.error "something went wrong", err