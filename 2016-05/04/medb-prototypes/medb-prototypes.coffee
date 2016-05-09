fs = require 'fs'
path = require 'path'

readdir = (dir) ->
  new Promise (resolve, reject) -> fs.readdir dir, (err, res) -> if err then reject err else resolve res

stat = (dir) ->
  new Promise (resolve, reject) -> fs.stat dir, (err, res) -> if err then reject err else resolve res

readfile = (dir) ->
  new Promise (resolve, reject) -> fs.readFile dir, 'utf-8', (err, res) -> if err then reject err else resolve res

flatten = (arrays) -> Array.prototype.concat.apply [], arrays

getignore = (dir) ->
  readfile path.join(dir, '.gitignore')
  .then (ignores) ->
    o = {}
    o[i] = true for i in ignores.split '\n' when i
    o
  .catch -> {}


getallfiles = (dir) ->
  Promise.all [getignore(dir), readdir(dir)]
  .then ([ignore, files]) ->
    ignore['.git'] = true
    Promise.all (for f in files when !ignore[f] then do (f) ->
      stat path.join dir, f
        .then (stat) -> {f, stat}
    )
  .then (stats) ->
    files = (s.f for s in stats when s.stat.isFile())
    dirs = (s.f for s in stats when s.stat.isDirectory())
    if dirs.length
      Promise.all (getallfiles path.join(dir, d) for d in dirs)
      .then (extrafiles) -> files.concat extrafiles...
    else
      files

guessmaps =
  haskell: /\.hs$/
  elm: /\.elm$/
  pony: /\.pony$/
  coffeescript: /\.coffee$/
  javascript: /\.js$/


guesslang = (files) ->
  filemap = {}
  filemap[k] = true for k in files
  if filemap['package.json']
    if (files.some (f) -> f.match '.coffee$')
      return 'coffeescript'
    return 'javascript'
  if filemap['Cargo.toml']
    return 'rust'
  if filemap['elm-package.json']
    return 'elm'
  for f in files
    for result, match of guessmaps
      return result if f.match match

  return 'unknown'

get = (dir) ->
  readdir dir
  .then (dirs) ->
    Promise.all (for d in dirs when d.match /\d{4}-\d{2}/ then do (d) ->
      readdir(path.join dir, d).then (subdirs) ->
        [year, month] = d.split('-')
        Promise.all (for subd in subdirs when subd.match /\d{2}/ then do (subd) ->
          day = subd
          getallfiles path.join dir, d, subd
          .then (files) ->
            tags: {year, month, day}
            values:
              # nottime: "#{year}-#{month}-#{day}T00:00:00.000Z"
              time: new Date("#{year}-#{month}-#{day}")
              files: files.length
              language: guesslang files
        )

    )
  .then (days) ->
    prototypes: flatten days

  .catch (e) ->
    console.error("error getting Prototype data", e)

module.exports = (config) -> get config.dir

get '/Users/samg/Code/prototypes'