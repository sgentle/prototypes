Canvas = require('canvas')

WIDTH = 300
HEIGHT = 100

canvas = new Canvas WIDTH, HEIGHT
ctx = canvas.getContext('2d')

ctx.font = '16px Helvetica'
ctx.textAlign = 'center'
ctx.fillText 'Administered by Automaintainer', WIDTH/2, 32

rules = {
  "voter": {
    "pulls": 1
  },
  "accept_pull": {
    "votes": 2,
    "voteRatio": 0.666
  }
}

ctx.font = '12px Helvetica'
ctx.textAlign = 'left'

y = 64
drawNext = (text1, text2) ->
  ctx.fillText text1, 16, y
  ctx.fillText text2, WIDTH/2, y
  y += 16

if rules.accept_pull
  voteRatio = rules.accept_pull.voteRatio && Math.round(rules.accept_pull.voteRatio*100) + '%'
  votes = [rules.accept_pull.votes, voteRatio]
    .filter(Boolean)
    .join(' or ')
  drawNext "Votes to merge:", votes

if rules.voter?.pulls
  drawNext "Requirements to vote:", "#{rules.voter.pulls} accepted pull requests"

ctx.strokeRect 0, 0, WIDTH, HEIGHT

stream = canvas.pngStream()

stream.pipe(process.stdout)
