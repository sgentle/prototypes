milight = require 'node-milight-promise'
cmd = milight.commandsV6
Lazy = require 'lazy'

light = new milight.MilightController
  ip: '192.168.0.231'
  type: 'v6'
  commandRepeat: 1


min = 2700
max = 6500

clamp = (val, min, max) -> Math.max(Math.min(val, max), min)

setTemp = (rawtemp) ->
  temp = (+rawtemp - min) / (max - min)
  val = clamp(Math.round(temp*100 or 0), 0, 100)
  console.log "#{rawtemp} -> #{val}"
  light.sendCommands(cmd.fullColor.whiteTemperature(0, val))

new Lazy(process.stdin).lines.forEach (line) -> setTemp line.toString()
