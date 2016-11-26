Bean = require 'ble-bean'

NAMES =
  '88c255ac2509': '1A'
  '88c255ac23f4': '2A'
  '88c255ac23e6': '3A'
  '88c255ac237f': '4A'
  '88c255ac23a3': '1B'
  '88c255ac23c4': '2B'
  '88c255ac268c': '3B'
  '88c255ac23b6': '4B'

beans = {}
beandata = {}
beandata[k] = {connected: false} for k in '1A 1B 2A 2B 3A 3B 4A 4B'.split(' ')
listeners = new Set()

sendmap =
  '1A': '1B'
  '2A': '2B'
  '3A': '3B'
  '4A': '4B'

disconnecting = false
process.on 'SIGINT', ->
  process.exit() if disconnecting
  console.log "disconnecting beans"
  disconnecting = true
  for name, bean of beans
    console.log "disconnecting #{name}"
    bean.disconnect()

broadcast = (msg) -> listeners.forEach (sock) -> sock.send msg if sock.readyState is sock.OPEN

applog = (name, msg) -> broadcast JSON.stringify {type: 'log', bean: name, message: msg}
syslog = (msg) ->
  console.log "[system] #{msg}"
  broadcast JSON.stringify {type: 'syslog', message: msg}

setbeandata = (name, key, val) ->
  beandata[name] ?= {}
  beandata[name][key] = val
  console.log "[#{name}] #{key} = #{val}"
  broadcast JSON.stringify {type: 'update', bean: name, data: beandata[name]}

console.log "scanning"
Bean.discoverAll (bean) ->
  console.log "discovered bean #{bean.id} [#{NAMES[bean.id]}] [#{bean._peripheral.advertisement.localName}]"
  #console.log "bean", bean
  return unless name = NAMES[bean.id]
  if beans[name]
    beans[name].disconnect()
    clearTimeout beans[name].connectionTimeout

  beans[name] = bean
  log = (msg...) ->
    applog name, msg.join " "
    console.log "[#{name}]", msg...
  update = (key, val) -> setbeandata name, key, val

  log "waiting to connect"
  setTimeout ->
    log "connecting"
    bean.connectionTimeout = setTimeout ->
      log "connection timed out"
      setTimeout ->
        bean.disconnect()
        Bean.startScanning()
      , 500
    , 5000
    bean.connectAndSetup (err) ->
      clearTimeout bean.connectionTimeout
      if err
        log "failed to connect", err
        bean.disconnect()
        Bean.startScanning()

      log "connected"
      update "connected", true
      Bean.startScanning() #Workaround for ble bug

      bean.on 'temp', (data) -> update "temperature", data
      getTemp = -> bean.requestTemp(->)
      getBattery = ->
        bean.readBatteryLevel (err, battery) -> update "battery", battery if battery

      getTemp()
      tempInterval = setInterval getTemp, 60*1000
      getBattery()
      battInterval = setInterval getBattery, 60*1000

      bean.on 'serial', (data) ->
        return unless data.toString().trim()
        log data.toString()
        update 'state', data.toString()

        if sendmap[name] and (targetbean = beans[sendmap[name]])
          if targetbean.sending then return
          targetbean.sending = true
          syslog "trigger #{name} -> #{sendmap[name]}"
          targetbean.write new Buffer("go"), ->
            targetbean.sending = false

      bean.on 'disconnect', ->
        log "disconnected"
        if beans[name] == bean
          delete beans[name]
          update "connected", false
        clearInterval tempInterval
        clearInterval battInterval

        if disconnecting and Object.keys(beans).length is 0
          process.exit()
  , 1000


express = require 'express'

app = express()
app.use express.static __dirname + '/public'
expressWs = require('express-ws')(app)

app.ws '/beans', (ws) ->
  listeners.add ws
  for name, data of beandata
    ws.send JSON.stringify {type: 'update', bean: name, data}

  ws.on 'message', (msg) ->
    console.log "[socket] message", msg
    try
      data = JSON.parse msg
      if data.type is 'rescan'
        return Bean.startScanning()
      if data.type is 'restart'
        process.exit()

      return unless data.bean and bean = beans[data.bean]
      if data.type is 'disconnect'
        applog data.bean, 'manual disconnect'
        bean.disconnect()
        return

      if data.type is 'trigger'
        if bean.sending then return
        bean.sending = true
        applog data.bean, 'manual trigger'
        bean.write new Buffer("go"), ->
          bean.sending = false
    catch
      console.log "[socket] invalid JSON"
  ws.on 'disconnected', ->
    console.log "[ws] disconnected"
    listeners.remove ws


app.get '/test', (req, res) -> res.send "hello"

app.listen 80
console.log "[express] listening on port 80"
