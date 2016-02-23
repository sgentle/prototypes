bigo = require './bigo.coffee'

setup = (n) ->
  Math.random() for [1..n]

sort = (list) -> list.slice().sort()

scan = (list) -> (x for x in list)

addPairs = (list) -> (x + y for x in list for y in list)

console.log "scan", bigo(setup, scan)

console.log "sort", bigo(setup, sort)

console.log "addPairs", bigo(setup, addPairs)
