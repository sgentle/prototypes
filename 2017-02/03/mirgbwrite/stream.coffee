milight = require 'node-milight-promise'
cmd = milight.commandsV6
Lazy = require 'lazy'
color = require 'color'

light = new milight.MilightController
  ip: '192.168.0.231'
  type: 'v6'
  commandRepeat: 1
  delayBetweenCommands: 0


MINSAT = 0
MINBRIGHT = 0
HUEOFFSET = 15

current = {h: 0, s: 0, v: 0}
last = {h: null, s: null, v: null}

fixhue = (hue) -> (hue + HUEOFFSET) * 255 // 360 % 255
fixhue = (hue) -> (Math.round(0.00109284 * hue * hue + 0.398124 * hue + 16.0833) % 255)

onCommand = ->
waitForCommand = ->
  new Promise (resolve) -> onCommand = resolve
  .then ->
    onCommand = ->


update = ->
  cmds = []
  cmds.push cmd.fullColor.hue(1, fixhue(current.h)) if current.h != last.h
  cmds.push cmd.fullColor.saturation(1, Math.max(MINSAT, 100 - current.s)) if current.s != last.s
  cmds.push cmd.fullColor.brightness(1, Math.max(MINBRIGHT, current.v)) if current.v != last.v

  last = current


  if cmds.length
    console.log "updating #{cmds.length}", [Math.round(current.h), Math.round(current.s), Math.round(current.v)]

    light.sendCommands.apply(light, cmds)
    .then update
  else
    waitForCommand()
    .then update

  null


waitForCommand().then update

setColor = (rawcolor) ->
  [r, g, b] = rawcolor.split(',').map(Number)
  return unless r? and g? and b?

  hsv = color.rgb(r, g, b).hsv().object()
  current = {h: Math.round(hsv.h), s: Math.round(hsv.s), v: Math.round(hsv.v)}

  onCommand()

new Lazy(process.stdin).lines.forEach (line) -> setColor line.toString()

