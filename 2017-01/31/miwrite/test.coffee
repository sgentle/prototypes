milight = require 'node-milight-promise'

cmd = milight.commandsV6

light = new milight.MilightController
  ip: '192.168.0.231'
  type: 'v6'
  commandRepeat: 1

min = 2700
max = 6500
temp = (+process.argv[2] - min) / (max - min)
val = Math.round(temp*100 or 0)

console.log "setting temperature to", val

light.sendCommands(cmd.fullColor.whiteTemperature(0, val))
.then -> light.close()
.then -> console.log "done"

