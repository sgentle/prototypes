Bean = require 'ble-bean'

NAMES =
  '88c255ac2509': '1A'
  '88c255ac23f4': '2A'
  '88c255ac23e6': '3A'
  '88c255ac237f': '4A'
  '88c255ac23a3': '1B'
  '88c255ac23c4': '2B'
  '88c255ac268c': '3B'
  '41d9bdccf6874efcbe91faf8e5837ffd': '1A'
  '8c4cb96aab3e4992b8af796579d2656f': '2B'
  '7c438508815e4872b12d33e203414976': '1B'

beans = {}

sendmap =
  '1A': '1B'
  '2A': '2B'
  '3A': '3B'
  '4A': '4B'

console.log "scanning"
Bean.discoverAll (bean) ->
  console.log "discovered bean #{bean.id} [#{NAMES[bean.id]}] [#{bean._peripheral.advertisement.localName}]"

  return unless name = NAMES[bean.id]
  beans[name] = bean
  log = (msg...) -> msg.unshift "[#{name}]"; console.log msg...
  bean.connectAndSetup ->
    log "connected"
    disconnect = false
    process.on 'SIGINT', ->
      if disconnect
        console.log "quitting"
        process.exit()
      else
        log "disconnecting"
        bean.disconnect()
        disconnect = true


    bean.requestTemp(->)
    bean.readBatteryLevel (err, battery) -> log "battery", battery
    bean.on 'temp', (data) -> log "temp data", data
    bean.on 'serial', (data) -> 
      log "serial data", data
      if sendmap[name] and beans[sendmap[name]]
        console.log "[route] #{name} -> #{sendmap[name]}"
        beans[sendmap[name]].write data
    bean.on 'disconnect', ->
      log "disconnected"
