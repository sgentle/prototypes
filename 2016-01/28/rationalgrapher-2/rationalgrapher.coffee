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

BASE = 440
createNode = (a, b) ->
  osc = context.createOscillator()
  osc.start(context.currentTime + 0.01 + Math.random() * 0.01)
  osc.frequency.value = BASE*a/b
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

canvas = document.getElementById('canvas')
ctx = canvas.getContext('2d')
ctx.font = '16px serif'
ctx.scale(canvas.width, canvas.height)

pixel = Math.min(1/canvas.width, 1/canvas.height)
bigpixel = Math.max(1/canvas.width, 1/canvas.height)
ctx.lineWidth = bigpixel


withState = (f) -> ctx.save(); f(); ctx.restore()

hackText = (text, x, y, props) -> withState ->
  ctx[k] = v for k, v of props
  ctx.scale(1/canvas.width, 1/canvas.height)
  ctx.fillText text, x*canvas.width, y*canvas.height

numLim = 16
denomLim = 16
oscList = []
lastt = 0
FADETIME = 0.1 * 1000
ctx.clearRect(0, 0, 1, 1)
draw = (t) ->
  withState ->
    opacity = Math.min((t-lastt)/FADETIME, 1)
    ctx.fillStyle = "rgba(255, 255, 255, #{opacity}"
    ctx.fillRect(0, 0, 1, 1)
    ctx.fillStyle = "rgba(0, 0, 0, #{opacity*2})"
    ctx.strokeStyle = "rgba(0, 0, 0, #{opacity*2})"

    for osc in oscList
      ctx.beginPath()
      ctx.moveTo(osc.a/numLim, osc.b/denomLim)
      ctx.moveTo(0, 0)
      ctx.lineTo(osc.a*numLim, osc.b*denomLim)
      ctx.stroke()

    limit = Math.min(numLim, denomLim)
    for osc in oscList
      a = osc.a
      b = osc.b
      ctx.fillStyle = "rgba(0, 0, 0, #{(opacity * 2)}"
      ctx.fillRect (a-0.5)/numLim, (b-0.5)/denomLim, 1/numLim, 1/denomLim
      ctx.fillStyle = "rgba(255, 255, 255, #{1}"
      hackText "#{a}/#{b}", (a)/(numLim), (b)/(denomLim), textAlign: 'center', textBaseline: 'middle'

  lastt = t
  requestAnimationFrame draw

restarter = null

step = ->
  # return
  oscs.each (osc) -> rule(osc) for rule in addRules
  oscs.each (osc) -> rule(osc) for rule in delRules
  oscList = oscs.sorted()

  if oscList.length == 0 and !restarter
    restarter = setTimeout setup, 1000


setup = ->
  restarter = null
  while Math.random() > 1/8
    oscs.add Math.round(Math.random()*3+1), Math.round(Math.random()*7+1)
  oscList = oscs.sorted()

setup()

setInterval step, 200

draw(0)
