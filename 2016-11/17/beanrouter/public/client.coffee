$ = document.querySelector.bind(document)

sock = null

connect = ->
  console.log "connected"
  sock = new WebSocket "ws://#{location.hostname}/beans"
  sock.onconnected = -> console.log "connected"
  sock.onmessage = (e) ->
    console.log "message", e.data
    msg = JSON.parse e.data
    if msg.type is 'update'
      updateBean msg.bean, msg.data
    else if msg.type is 'log'
      logBean msg.bean, msg.message
  sock.onclose = ->
    sock = null
    console.log "Reconnecting..."
    setTimeout connect, 1000

connect()

$('#rescanbutton').addEventListener 'click', -> sock.send JSON.stringify {type: 'rescan'}
$('#restartbutton').addEventListener 'click', -> sock.send JSON.stringify {type: 'restart'}

beans = {}

beancontainer = $('#beancontainer')

addBean = (id) ->
  root = document.createElement 'div'
  root.innerHTML = id
  root.className = 'bean'

  data = document.createElement 'div'
  data.className = 'data'
  root.appendChild data

  log = document.createElement 'div'
  log.className = 'log'
  root.appendChild log

  buttonContainer = document.createElement 'div'
  buttonContainer.className = 'button-container'
  root.appendChild buttonContainer

  disconnect = document.createElement 'button'
  disconnect.innerHTML = "Disconnect"
  disconnect.addEventListener 'click', -> sock.send JSON.stringify {type: 'disconnect', bean: id}
  buttonContainer.appendChild disconnect

  trigger = document.createElement 'button'
  trigger.innerHTML = "Trigger"
  trigger.addEventListener 'click', -> sock.send JSON.stringify {type: 'trigger', bean: id}
  buttonContainer.appendChild trigger


  beancontainer.appendChild root
  beans[id] = {root, data, log, buttonContainer, buttons: {disconnect, trigger}}

updateBean = (id, data) ->
  bean = beans[id]
  bean.data.innerHTML = ("#{k} = #{v}" for k, v of data).join('<br>')
  bean.root.style.backgroundColor = if data.connected then '#ddddff' else '#ffdddd'

logBean = (id, msg) ->
  bean = beans[id]
  d = new Date()
  stamp = d.toTimeString().slice(0, 8)
  bean.log.appendChild document.createTextNode "[#{stamp}] #{msg}"
  bean.log.appendChild document.createElement 'br'
  if bean.log.children.length > 100
    bean.log.firstChild.remove()
    bean.log.firstChild.remove()
  bean.log.scrollTop = bean.log.scrollHeight

  bean.root.style.backgroundColor = '#ffffdd' if msg in ['connecting', 'waiting to connect']

addBean k for k in '1A 2A 3A 4A 1B 2B 3B 4B'.split ' '
