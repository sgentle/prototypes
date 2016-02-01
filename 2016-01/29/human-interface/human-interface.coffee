$ = document.querySelector.bind(document)

$instruction = $('#instrunction')
$elements = $('#elements')

ary = [0..9]

shuffle = (xs) ->
  m = xs.length
  while m
    i = Math.floor(Math.random() * m--)
    [xs[i], xs[m]] = [xs[m], xs[i]]

#shuffle ary
ary = ary.map -> Math.floor(Math.random()*10)

$elements.addEventListener 'dragstart', (ev) ->
  console.log 'dragstart', ev
  ev.dataTransfer.setData "text/plain", ev.target.getAttribute('data-index')

$elements.addEventListener 'dragover', (ev) ->
  ev.dataTransfer.dropEffect = 'move'
  ev.preventDefault()

active = null

$elements.addEventListener 'drop', (ev) ->
  console.log 'drop', ev
  from = Number ev.dataTransfer.getData('text')
  to = Number ev.target.getAttribute('data-index')
  return unless from and to
  console.log 'from', from, 'to', ev.target.getAttribute('data-index')
  console.log "ary", ary
  [ary[from], ary[to]] = [ary[to], ary[from]]
  console.log "ary", ary
  if active is from or active is to then active = null
  writeAry(ary)

$elements.addEventListener 'click', (ev) ->
  console.log 'clickety'
  active = Number ev.target.getAttribute('data-index')
  writeAry(ary)


writeAry = (ary) ->
  $elements.innerHTML = ary.map((x, i) -> "<div class='element #{if i is active then 'active' else ''}' data-index='#{i}' draggable='true'>#{x}</div>").join('')


writeAry ary