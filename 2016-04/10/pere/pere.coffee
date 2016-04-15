defaultComp = (a, b) -> a > b

sortedInsert = (ary, item, greater=defaultComp) ->
  start = 0
  end = ary.length
  while start < end
    i = Math.floor (start + end) / 2
    if greater item, ary[i]
      start = i + 1
    else
      end = i

  ary.splice start, 0, item
  ary


diffcomp = (path1, path2) ->
  path1.d > path2.d

disp = (str1, str2, path) ->
  ret = []
  while path
    ret.unshift "-#{str1[path.prev.x]}" if path.dir is 0
    ret.unshift "+#{str2[path.prev.y]}" if path.dir is 1
    ret.unshift "=#{str1[path.prev.x]}" if path.dir is 2
    path = path.prev
  ret.join ''


diff = (str1, str2) ->
  visited = {}
  paths = [{x: 0, y: 0, d: 0, dir: -1, prev: null}]
  n = 0
  until !paths[0] or (paths[0].x == str1.length) and (paths[0].y == str2.length)
    # break if n++ is 100
    thisPath = paths.shift()
    {x, y, dir, d, prev} = thisPath
    continue if visited["#{x}:#{y}"] or (x > str1.length) or (y > str2.length)

    visited["#{x}:#{y}"] = true
    if str1[x] and (str1[x] == str2[y])
      sortedInsert paths, {x: x + 1, y: y + 1, d, dir: 2, prev: thisPath}, diffcomp
    else if dir is 0
      sortedInsert paths, {x: x + 1, y, d: d + 1, dir: 0, prev: thisPath}, diffcomp
      sortedInsert paths, {x, y: y + 1, d: d + 1, dir: 1, prev: thisPath}, diffcomp
    else #if dir is 1
      sortedInsert paths, {x, y: y + 1, d: d + 1, dir: 1, prev: thisPath}, diffcomp
      sortedInsert paths, {x: x + 1, y, d: d + 1, dir: 0, prev: thisPath}, diffcomp

  p = paths[0]
  ret = []
  lastt = null
  chunks = { '-': [], '+': [], '=': [] }
  while p
    t = '-+='[p.dir]

    # Batch sequences of =, +/- together
    if !p.prev or (t != lastt and (t is '=' or lastt is '='))
      i = 0
      for _t in '+-=' when chunks[_t].length
        i += 1
        ret.unshift {t: _t, c: chunks[_t]}
        chunks[_t] = []

    if chunks[t]
      c = if p.dir is 1 then str2[p.prev.y] else str1[p.prev.x]
      chunks[t].unshift c

    lastt = t
    p = p.prev
  ret

strip = (patch) ->
  for p in patch
    if p.t is '=' or p.t is '-'
      {l: p.c.length, t: p.t}
    else
      p

patch = (str, patch) ->
  newstr = []
  i = 0
  si = 0
  for p in patch
    if p.t is '='
      l = p.l
      newstr.push str.slice(si, si + l)
      i += l
      si += l
    if p.t is '+'
      newstr.push p.c.join('')
      i += p.l
    if p.t is '-'
      si += p.l
  newstr.join('')

reflect = (el) ->
  el.innerHTML = ""
  nodeids = {}
  apply: (e) ->
    switch e.type
      when 'add'
        if e.nodeType is 1
          node = document.createElement e.tag
        else if e.nodeType is 3
          node = document.createTextNode ""
        node.data = e.data if e.data?
        node.innerHTML = e.innerHTML if e.innerHTML?
        nodeids[e.id] = node
        parent = nodeids[e.parent] or el

        if afterNode = nodeids[e.after]
          parent.insertBefore node, afterNode.nextSibling
        else
          parent.insertBefore node, parent.firstChild

      when 'remove'
        nodeids[e.id].remove()
        delete nodeids[e.id]

      when 'edit'
        node = nodeids[e.id]
        newdata = patch(node.data, e.edits)
        node.data = newdata


observe = (el, callback) ->
  el.innerHTML = ""
  nodeid = 0
  nodeids = new Map()
  oldVals = new Map()
  removedids = new Map()
  editTimers = new Map()
  timestamp = Date.now()

  addNode = (parent, node) ->
    return if nodeids.get(node)
    id = nodeid++
    nodeids.set node, id
    oldVals.set(node, node.data) if node.data
    console.warn "parent unknown", parent if !nodeids.get(parent)? and parent isnt el
    if node.previousSibling? and !nodeids.get(node.previousSibling)?
      console.warn "sibling unknown", node.previousSibling, removedids.get(node.previousSibling)
    callback {
      type: 'add', id, nodeType: node.nodeType, tag: node.tagName,
      parent: nodeids.get(parent), data: node.data,
      after: (nodeids.get(node.previousSibling))
      timestamp: Date.now() - timestamp
    }

    addNode node, child for child in node.childNodes if node.childNodes

  removeNode = (node) ->
    removeNode child for child in node.childNodes if node.childNodes

    id = nodeids.get node
    nodeids.delete node
    oldVals.delete node
    clearTimeout editTimers.get node
    editTimers.delete node
    removedids.set node, id
    callback {type: 'remove', id, timestamp: Date.now() - timestamp} if id?

  observer = new MutationObserver (mutations) ->
    for mut in mutations then do (mut) ->
      if mut.type is 'childList'
        addNode mut.target, addedNode for addedNode in mut.addedNodes

        removeNode removedNode for removedNode in mut.removedNodes

      else if mut.type is 'characterData'
        target = mut.target
        return if editTimers.get target
        timer = setTimeout ->
          editTimers.delete target

          oldVal = oldVals.get(target) or ''
          newVal = target.data
          oldVals.set(target, newVal)
          return if oldVal == newVal

          edits = strip diff oldVal, newVal

          id = nodeids.get(target)
          callback {type: 'edit', id, edits, timestamp: Date.now() - timestamp} if id?
        , Math.floor(Math.random()*300)+200

        editTimers.set target, timer

  observer.observe el, {childList: true, characterData: true, subtree: true}
  {unobserve: -> observer.disconnect()}

record = (el, callback=->) ->
  edits = []
  observer = observe el, (edit) ->
    edits.push edit
    callback(edit)
  edits.unobserve = observer.unobserve
  edits

playback = (el, edits, speed=1.0) ->
  reflector = reflect el
  i = 0
  lasttime = 0
  timeout = null
  pause = ->
    clearTimeout timeout

  play = ->
    return unless edits[i]
    timeout = setTimeout ->
      edit = edits[i]

      reflector.apply edit
      lasttime = edit.timestamp
      i++
      play()
    , ((edits[i].timestamp - lasttime) / speed) or 0

  setSpeed = (_speed) ->
    speed = _speed
    pause()
    play()
  play()

  {setSpeed, pause, play}

ex = {observe, reflect, record, playback}

if typeof window == 'undefined'
  module.exports = ex
else
  window.pere = ex