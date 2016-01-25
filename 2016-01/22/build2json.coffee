fs = require 'fs'
path = require 'path'
vdf = require 'vdf'
herodata = require './herodata.json'

mkArray = (s) ->
  return s if Array.isArray s
  return [] if !s
  return [s]

noItem = (str) -> str.replace(/^item_/, '')

build2json = (filename) ->

  txt = fs.readFileSync(filename, 'utf8')
  g = vdf.parse(txt).HeroGuide

  obj =
    title: g.Title
    hero: herodata[g.Hero].id
    filename: 'guides/' + path.basename(filename)
    isScratch: g.Scratch
    skillBuild: (v for k, v of g.AbilityBuild.AbilityOrder)
    abilityTooltips: g.AbilityBuild.AbilityTooltips
    itemBuild: (header: k, items: mkArray(v.item).map(noItem) for k, v of g.ItemBuild.Items)
    itemTooltips: g.ItemBuild.ItemTooltips

  obj

module.exports = build2json

if !module.parent
  console.log JSON.stringify(build2json process.argv[2])