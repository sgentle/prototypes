# $ = document.querySelector.bind(document)
# $$ = document.querySelectorAll.bind(document)

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
  # console.log "path", path
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
    # console.log "str1[x]", str1[x], "str2[y]", str2[y]
    if str1[x] and (str1[x] == str2[y])
      # console.log "diag", x, y, d, str1[x]
      sortedInsert paths, {x: x + 1, y: y + 1, d, dir: 2, prev: thisPath}, diffcomp
    else if dir is 0
      sortedInsert paths, {x: x + 1, y, d: d + 1, dir: 0, prev: thisPath}, diffcomp
      sortedInsert paths, {x, y: y + 1, d: d + 1, dir: 1, prev: thisPath}, diffcomp
    else #if dir is 1
      sortedInsert paths, {x, y: y + 1, d: d + 1, dir: 1, prev: thisPath}, diffcomp
      sortedInsert paths, {x: x + 1, y, d: d + 1, dir: 0, prev: thisPath}, diffcomp

    # console.log "paths", (paths.map (p) -> "#{disp(str1, str2, p)} (#{p.x},#{p.y}:#{p.d})").join ' '

  # console.log disp paths[0]
  p = paths[0]
  ret = []
  lastpdir = null
  while p
    ret.unshift {t: "-+="[p.dir], c: []} if p.dir != lastpdir and p.dir isnt -1
    lastpdir = p.dir
    switch p.dir
      when 0, 2
        ret[0].c.unshift str1[p.prev.x]
      when 1
        ret[0].c.unshift str2[p.prev.y]
    # console.log "- #{str1[p.prev.x]}" if p.dir is 0
    # console.log "+ #{str2[p.prev.y]}" if p.dir is 1
    # console.log "= #{str1[p.prev.x]}" if p.dir is 2
    p = p.prev
  ret

patch = (str, patch) ->
  console.log "patch", str, patch
  newstr = []
  i = 0
  si = 0
  for p in patch
    # console.log "i", i, "t", p.t, "c", p.c
    # console.log "at", i
    if p.t is '='
      # console.log "slice", str, si, p.c.length, str.slice(si, p.c.length)
      newstr.push str.slice(si, si + p.c.length)
      i += p.c.length
      si += p.c.length
    if p.t is '+'
      newstr.push p.c.join('')
      i += p.c.length
    if p.t is '-'
      # i += p.c.length
      si += p.c.length
  # console.log "end i", i, "si", si, "len", str.length
  newstr.join('')

handleEdit = null

attachMirror = (el) ->
  mirror = el
  console.log "mirror", mirror
  nodeids = {}
  handleEdit = (e) ->
    console.log "handling edit", e
    switch e.type
      when 'add'
        if e.nodeType is 1
          node = document.createElement e.tag
        else if e.nodeType is 3
          node = document.createTextNode ""
        node.data = e.data if e.data?
        node.innerHTML = e.innerHTML if e.innerHTML?
        nodeids[e.id] = node
        parent = nodeids[e.parent] or mirror
        console.log("insertAfter", e.after, (nodeids[e.after] or null))

        if afterNode = nodeids[e.after]
          parent.insertBefore node, afterNode.nextSibling
        else
          parent.insertBefore node, parent.firstChild

      when 'remove'
        nodeids[e.id].remove()
        console.log "remove()", nodeids[e.id]
        delete nodeids[e.id]

      when 'edit'
        node = nodeids[e.id]
        # console.log "node", node
        newdata = patch(node.data, e.edits)
        # console.log "newdata", newdata
        node.data = newdata


attach = (el) ->
  el.innerHTML = ""
  nodeid = 0
  nodeids = new Map()
  oldVals = new Map()
  removedids = new Map()
  addNode = (parent, node) ->
    return if nodeids.get(node)
    console.log "+ added", node, "before", node.previousSibling, nodeids.get(node.previousSibling)
    id = nodeid++
    nodeids.set node, id
    oldVals.set(node, node.data) if node.data
    console.warn "parent unknown", parent if !nodeids.get(parent)? and parent isnt el
    if node.previousSibling? and !nodeids.get(node.previousSibling)?
      console.warn "sibling unknown", node.previousSibling, removedids.get(node.previousSibling)
    handleEdit {
      type: 'add', id, nodeType: node.nodeType, tag: node.tagName,
      parent: nodeids.get(parent), data: node.data,
      after: (nodeids.get(node.previousSibling))
    }

    addNode node, child for child in node.childNodes if node.childNodes

  removeNode = (node) ->
    removeNode child for child in node.childNodes if node.childNodes

    id = nodeids.get node
    console.log "- removed", node
    nodeids.delete node
    oldVals.delete node
    removedids.set node, id
    handleEdit {type: 'remove', id} if id?

  observer = new MutationObserver (mutations) ->
    for mut in mutations
      if mut.type is 'childList'
        console.log "childList", mut, "added", mut.addedNodes.length, "removed", mut.removedNodes.length
        addNode mut.target, addedNode for addedNode in mut.addedNodes

        removeNode removedNode for removedNode in mut.removedNodes

      else if mut.type is 'characterData'
        # console.log 'target', mut.target
        oldVal = oldVals.get(mut.target) or ''
        newVal = mut.target.data
        oldVals.set(mut.target, newVal)
        # console.log 'old content', oldVal
        # console.log 'new content', newVal
        continue if oldVal == newVal
        edits = diff(oldVal, newVal)
        editsel = document.querySelector('#edits')
        editsel.innerHTML += "<br /> " +
          ((if d.t is '=' then d.c.map((x) -> ' ').join('') else d.t + d.c.join('')) for d in edits).join('')
        editsel.scrollTop = editsel.scrollHeight

        # console.log "target", mut.target, nodeids.get(mut.target)
        id = nodeids.get(mut.target)
        handleEdit {type: 'edit', id, edits} if id?



  observer.observe el, {childList: true, characterData: true, subtree: true}

if typeof window == 'undefined'
  module.exports = {diff, sortedInsert}
else
  window.пере = (sel) ->
    attach el for el in document.querySelectorAll sel
    attachMirror document.querySelector '.mirror'