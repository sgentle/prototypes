context = new (AudioContext or webkitAudioContext)()

gcd = (a, b) -> if b is 0 then a else gcd(b, a % b)

ratProto =
  norm: ->
    if @b < 0 then @a = -@a; @b = -@b
    g = gcd(@a, @b)
    @a /= g
    @b /= g
    this

  add: (a, b) ->
    @a = (a * @b) + (@a * b)
    @b = b * @b
    @norm()

  sub: (a, b) -> @add -a, b
  mult: (a, b) ->
    @a *= a
    @b *= b
    @norm()

  div: (a, b) -> @mult b, a

Rat = (a, b) ->
  o = Object.create(ratProto)
  o.a = a; o.b = b
  o

START = 440
createNode = (a, b) ->
  osc = context.createOscillator()
  osc.start(context.currentTime + 0.01 + Math.random() * 0.01)
  osc.frequency.value = 440*a/b
  gain = context.createGain()
  gain.connect context.destination
  gain.gain.value = 1/8
  osc.connect gain
  {osc, gain}

reduce = (a, b) ->
  if b < 0 then a = -a; b = -b
  g = gcd(a, b)
  [a/g, b/g]

oscSetProto =
  add: (a, b) ->
    [a, b] = reduce(a, b)
    return @get(a, b) if @obj["#{a}:#{b}"]
    o = Rat(a, b)
    o.node = createNode(a, b)
    @obj["#{a}:#{b}"] = o
    o
  remove: (osc) ->
    osc.node.gain.gain.value = 0
    osc.node.osc.stop(context.currentTime + 0.01 + Math.random() * 0.01)
    delete @obj["#{osc.a}:#{osc.b}"]
  get: (a, b) ->
    [a, b] = reduce(a, b)
    @obj["#{a}:#{b}"]
  each: (f) -> f(v) for k, v of @obj
  sorted: ->
    sorted = (v for k, v of @obj)
    sorted.sort (o1, o2) -> o1.a/o1.b - o2.a/o2.b
    sorted
  nearest: (osc) ->
    sorted = @sorted()
    i = sorted.indexOf(osc)
    prev = sorted[i-1]
    next = sorted[i+1]
    if !prev and !next then null
    prevDist = Math.abs prev?.a/prev?.b - osc.a/osc.b
    nextDist = Math.abs next?.a/next?.b - osc.a/osc.b
    if prevDist > nextDist then prev else next

  count: -> Object.keys(@obj).length

OSCSet = ->
  o = Object.create(oscSetProto)
  o.obj = {}
  o

oscs = OSCSet()

addRules = []
delRules = []

delRules.push (osc) ->
  if osc.a > 16 or osc.b > 16
    oscs.remove osc

delRules.push (osc) ->
  if osc.a/osc.b >= 3 or osc.b/osc.a >= 6
    oscs.remove osc

delRules.push (osc) ->
  return unless nearest = oscs.nearest(osc)
  rat = Rat(osc.a*nearest.b, osc.b*nearest.a).norm()

  if rat.a > 8 or rat.b > 4
     oscs.remove osc

addRules.push (osc) ->
  oscs.add osc.a+1, osc.b-1 if osc.b > 1
  oscs.add osc.a+1, osc.b+2
  oscs.add osc.a*1, osc.b*3
  oscs.add osc.a*3, osc.b*2

state = document.getElementById('state')

draw = ->
  state.innerHTML = (oscs.sorted().map (osc) -> "#{osc.a}/#{osc.b}").join ", "

restarter = null

step = ->
  oscs.each (osc) -> rule(osc) for rule in addRules
  oscs.each (osc) -> rule(osc) for rule in delRules
  sorted = oscs.sorted()

  if sorted.length == 0 and !restarter
    restarter = setTimeout setup, 1000

  draw()

setup = ->
  restarter = null
  while Math.random() > 1/8
    oscs.add Math.round(Math.random()*3+1), Math.round(Math.random()*7+1)
  draw()

setup()

setInterval step, 200
