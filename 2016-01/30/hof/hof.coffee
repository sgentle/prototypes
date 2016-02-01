$ = document.querySelector.bind(document)
$$ = document.querySelectorAll.bind(document)

getContents = (el) ->
  range = document.createRange()
  range.selectNodeContents(el)
  range.extractContents()

cloneContents = (el) ->
  range = document.createRange()
  range.selectNodeContents(el)
  range.cloneContents()

hofOf = (el) ->
  field = el.getAttribute 'field'
  contents = getContents el

  el.innerHTML = field
  listener = -> el.parentNode.replaceChild(contents, el)
  el.addEventListener 'click', listener


hofOver = (el) ->
  definitions = {}

  for hof in el.querySelectorAll('hof-of')
    definitions[hof.getAttribute 'field'] = cloneContents hof

  names = {}
  names[t.innerHTML] = true for t in el.querySelectorAll('hof-on')

  outputs = []
  for hout in el.querySelectorAll('hof-output') then do (hout) ->
    fun = new Function Object.keys(names), 'return ' + hout.getAttribute('function')
    outputs.push (counts) -> hout.innerHTML = fun.apply(null, counts)

  updateOutputs = ->
    counts = {}
    counts[k] = 0 for k of names
    for hon in el.querySelectorAll('hof-on')
      key = hon.innerHTML
      counts[key]++ if counts[key]?
    for hof in el.querySelectorAll('hof-of')
      key = hof.getAttribute 'field'
      counts[key]++ if counts[key]
    countsList = (v for k, v of counts)
    out(countsList) for out in outputs

  setTimeout updateOutputs, 0

  expandAll = ->
    hofs = el.querySelectorAll('hof-of')
    return if hofs.length is 0
    for hof in hofs
      if replacement = definitions[hof.getAttribute('field')]
        hof.parentNode.replaceChild replacement.cloneNode(true), hof
    expandAll()

  for hofOpener in el.querySelectorAll('hof-open-full')
    hofOpener.addEventListener 'click', expandAll


  el.addEventListener 'click', (ev) ->
    updateOutputs()
    return if el.querySelector('hof-of')

    if el.hasAttribute 'factory'
      clone = el.cloneNode(true)
      subEl.remove() for subEl in clone.querySelectorAll('hof-open-full')
      el.parentNode.insertBefore clone, el

    for oldel in el.querySelectorAll('hof-on')
      if replacement = definitions[oldel.innerHTML]
        newel = document.createElement('hof-of')
        newel.setAttribute 'field', oldel.innerHTML
        newel.appendChild replacement.cloneNode(true)
        hofOf subEl for subEl in newel.querySelectorAll('hof-of')
        hofOf newel
        oldel.parentNode.replaceChild(newel, oldel)

hofOver el for el in $$('hof-over')
hofOf el for el in $$('hof-of')
