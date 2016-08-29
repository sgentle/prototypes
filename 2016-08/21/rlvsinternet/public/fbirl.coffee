$id = (x) -> document.getElementById(x)

get = (cb=->) ->
  req = new XMLHttpRequest()
  req.open 'GET', 'http://dev.samgentle.com:9999'
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
  req.open 'POST', 'http://dev.samgentle.com:9999/ping'
  # req.addEventListener 'load', ->
  #   try
  #     cb(null, JSON.parse(req.responseText))
  #   catch e
  #     cb e
  # req.addEventListener 'error', cb
  req.send()


elsets =
  internet:
    counter: $id('internet-counter')
    button: $id('internet-button')
  irl:
    counter: $id('irl-counter')
    button: $id('irl-button')

elsets.internet.button.addEventListener 'click', ->
  ping()
  elsets.internet.counter.innerText = pad(Number(elsets.internet.counter.innerText) + 1)
  nextPing = Date.now() + 1000
  updateTimeout()


padString = '00000'
pad = (num) ->
  str = '' + num
  padString.slice(0,Math.max(0, padString.length - str.length)) + str


pingTimeout = null
updateTimeout = ->
  clearTimeout pingTimeout

  if !nextPing || nextPing < Date.now()
    elsets.internet.button.removeAttribute 'disabled'
  else
    pingTimeout = setTimeout ->
      elsets.internet.button.removeAttribute 'disabled'
    , (nextPing - Date.now())
    elsets.internet.button.setAttribute 'disabled', true


setInterval ->
  get (err, data) ->
    return console.error err if err
    console.log "got", data
    for k, els of elsets when data[k]?
      els.counter.innerText = pad(data[k])
    nextPing = data.nextPing
    updateTimeout()

, 1000
