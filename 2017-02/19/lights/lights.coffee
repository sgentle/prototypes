#!/usr/bin/env coffee
milight = require 'node-milight-promise'
cmds = milight.commandsV6.fullColor
color = require 'color'

LIGHTSMAP =
  all: 0
  desk: 1
  room: 2


MIN_TEMP = 2700
MAX_TEMP = 6500

TEMPSMAP =
  day: 6500
  night: 3400
  daylight: 6500
  halogen: 3400
  tungsten: 2700
  min: MIN_TEMP
  max: MAX_TEMP

light = new milight.MilightController
  ip: '192.168.0.231'
  type: 'v6'
  commandRepeat: 1

die = (msg) ->
  console.warn(msg)
  process.exit(1)

args = process.argv.slice(2)

die "Usage: lights [LIGHT] <cmd> <arg>" if args.length < 1 or args.length > 3

args.unshift('all') if args.length < 3 and args[1] not in ['on', 'off', 'day', 'night', 'white']

[id, cmd, arg] = args

id = Number(id) or LIGHTSMAP[id]

clamp = (val, min, max) -> Math.max(Math.min(val, max), min)

fixhue = (hue) -> (Math.round(0.00109284 * hue * hue + 0.398124 * hue + 16.0833) % 255)

isDay = () -> 7 < new Date().getHours() < 19

result = switch cmd
  when 'on'
    light.sendCommands cmds.on(id)

  when 'off'
    light.sendCommands cmds.off(id)

  when 'temp', 'day', 'night', 'white'
    arg = cmd if cmd != 'temp'
    if arg is 'white'
      arg = if isDay() then 'day' else 'night'

    basetemp = Number(arg) or TEMPSMAP[arg] or die("invalid temperature: #{arg}")
    temp = (basetemp - MIN_TEMP) / (MAX_TEMP - MIN_TEMP)
    val = clamp(Math.round(temp*100 or 0), 0, 100)
    light.sendCommands cmds.whiteTemperature(id, val)

  when 'rgb'
    die "invalid color: #{arg}" unless match = arg.match /^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i
    [r, g, b] = [parseInt(match[1], 16), parseInt(match[2], 16), parseInt(match[3], 16)]

    hsv = color.rgb(r, g, b).hsv().object()

    light.sendCommands(
      cmds.hue(id, Math.round(fixhue(hsv.h))),
      cmds.saturation(id, Math.round(100 - hsv.s)),
      cmds.brightness(id, Math.round(hsv.v))
    )

  when 'rgb2'
    die "invalid color: #{arg}" unless match = arg.match /^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i
    [r, g, b] = [parseInt(match[1], 16), parseInt(match[2], 16), parseInt(match[3], 16)]
    light.sendCommands cmds.rgb(id, r, g, b)

  when 'hue'
    light.sendCommands cmds.hue(id, +arg)

  when 'brightness', 'bright'
    light.sendCommands cmds.brightness(id, +arg)

  when 'saturation', 'sat'
    light.sendCommands cmds.saturation(id, 100 - (+arg))

  else
    die("Unknown command: #{cmd}")

result
  .then -> light.close()
  .then -> console.log "OK"
  .catch (err) -> console.error err
