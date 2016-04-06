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
        ret[0].c.push str1[p.prev.x]
      when 1
        ret[0].c.push str2[p.prev.y]
    # console.log "- #{str1[p.prev.x]}" if p.dir is 0
    # console.log "+ #{str2[p.prev.y]}" if p.dir is 1
    # console.log "= #{str1[p.prev.x]}" if p.dir is 2
    p = p.prev
  ret

attach = (el) ->
  elset = new Set()
  observer = new MutationObserver (mutations) ->
    for mut in mutations
      if mut.type is 'childList'
        console.log 'target', mut.target
        console.log 'added', mut.addedNodes
        console.log 'removed', mut.removedNodes
      else if mut.type is 'characterData'
        console.log 'target', mut.target
        # console.log 'old content', mut.oldValue
        # console.log 'new content', mut.target.data
        console.log diff(mut.oldValue, mut.target.data)

  observer.observe el, {childList: true, characterData: true, subtree: true, characterDataOldValue: true}

if typeof window == 'undefined'
  module.exports = {diff, sortedInsert}
else
  window.пере = (sel) ->
    attach el for el in document.querySelectorAll sel
