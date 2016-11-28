#!/usr/bin/env coffee
rcswitch = require 'rcswitch-gpiomem'
rcswitch.enableTransmit 17
rcswitch.setPulseLength 260
rcswitch.setRepeatTransmit 5

data =
  desk:
    on: 3761262431
    off: 3761260368
  room:
    on: 3761261400
    off: 3761259348

item = process.argv[2]
state = process.argv[3]

do ->
  return console.error "Don't know how to switch #{item}" if !data[item]
  return console.error "Don't know how to switch #{item} to #{state}" if !data[item][state]
  console.error "Switching #{item} to #{state}"
  rcswitch.send data[item][state], 32
