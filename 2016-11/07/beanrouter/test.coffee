Bean = require 'ble-bean'

NAMES =
  '41d9bdccf6874efcbe91faf8e5837ffd': 'sender'
  '8c4cb96aab3e4992b8af796579d2656f': 'receiver'

beans = {}

console.log "scanning"
Bean.discoverAll (bean) ->
  console.log "discovered bean #{bean.id} [#{NAMES[bean.id]}]"
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
      if name is 'sender' and beans.receiver
        console.log "sender -> receiver"
        beans.receiver.write data
    bean.on 'disconnect', ->
      log "disconnected"
