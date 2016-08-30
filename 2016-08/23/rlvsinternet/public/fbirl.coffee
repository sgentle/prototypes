$id = (x) -> document.getElementById(x)

get = (cb=->) ->
  req = new XMLHttpRequest()
  req.open 'GET', '/data'
  req.addEventListener 'load', ->
    try
      cb(null, JSON.parse(req.responseText))
    catch e
      cb e
  req.addEventListener 'error', cb
  req.send()

nextPing = 0
ping = (cb=->) ->
  return if Date.now() < nextPing
  req = new XMLHttpRequest()
  req.open 'POST', '/ping'
  req.send()

elsets =
  internet:
    counter: $id('internet-counter')
    button: $id('internet-button')
    fader: $id('internet-fader')
  irl:
    counter: $id('irl-counter')
    button: $id('irl-button')
    fader: $id('irl-fader')

elsets.internet.button.addEventListener 'click', ->
  if sock
    sock.send ''
  else
    ping()
  elsets.internet.counter.innerText = pad(Number(elsets.internet.counter.innerText) + 1)
  nextPing = Date.now() + 1000
  updateTimeout()


padString = '00000'
pad = (num) ->
  str = '' + num
  padString.slice(0,Math.max(0, padString.length - str.length)) + str

animTimer = null
startAnim = ->
  elsets.internet.button.setAttribute 'disabled', true
  return if animTimer
  start = Date.now()
  dur = nextPing - start
  elsets.internet.fader.style.opacity = 1
  animTimer = setInterval ->
    elsets.internet.fader.style.opacity = 1 - (Date.now()-start) / dur
  , Math.max(100/3, dur/60)

stopAnim = ->
  elsets.internet.button.removeAttribute 'disabled'
  elsets.internet.fader.style.opacity = 0
  clearInterval animTimer
  animTimer = null

pingTimeout = null
updateTimeout = ->
  clearTimeout pingTimeout

  if !nextPing || nextPing < Date.now()
    stopAnim()
    elsets.internet.button.removeAttribute 'disabled'
  else
    pingTimeout = setTimeout stopAnim, (nextPing - Date.now())
    startAnim()


processData = (data, source) ->
  console.log "update from", source, data
  for k, els of elsets when data[k]?
    els.counter.innerText = pad(data[k])
  nextPing = data.nextPing
  updateTimeout()

poll = ->
  get (err, data) ->
    return console.error err if err
    processData data, "ajax"

wsa = document.createElement 'a'
wsa.href = document.location.href
wsa.protocol = if wsa.protocol is 'https:' then 'wss' else 'ws'
wsa.pathname = '/sock'

timeout = 1000
maxTimeout = 16000
sock = null
pollTimer = null
connect = ->
  sock = new WebSocket(wsa.href)
  sock.onopen = ->
    console.log "Connected"
    socketconnected = true
    timeout = 1000
    clearInterval pollTimer
    pollTimer = null
  sock.onmessage = (e) ->
    data = JSON.parse(e.data)
    processData data, "websocket"
  sock.onclose = ->
    sock = null
    console.log "Reconnecting in", timeout
    setTimeout connect, timeout
    timeout = Math.min(timeout * 2, maxTimeout)
    clearInterval pollTimer
    pollTimer = setInterval poll, 1000
    poll()

if 'WebSocket' of window
  connect()
else
  pollTimer = setInterval poll, 1000

