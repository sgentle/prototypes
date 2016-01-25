fs = require 'fs'
opn = require 'opn'
temp = require 'temp'

client = ->
  ctx = new (AudioContext or webkitAudioContext)()
  osc = ctx.createOscillator()
  osc.frequency.value = 2000
  osc.start()
  osc.connect(ctx.destination)
  window.onbeforeunload = -> "Did you #{document.body.firstChild.textContent}?"


message = process.argv.slice(2).join(' ') or "Do things!"

html = "<h1>#{message}</h1><script>(#{client.toString()})()</script>"
#url = "data:text/html;base64,#{new Buffer(html).toString('base64')}"

filename = temp.path suffix: '.html'
fs.writeFileSync filename, html, 'utf8'
opn filename, wait: false

setTimeout (->), 500

process.on 'exit', -> fs.unlinkSync filename

