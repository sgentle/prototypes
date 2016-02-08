path = require 'path'
http = require 'http'
crypto = require 'crypto'
child_process = require 'child_process'
fs = require 'fs'

git = require 'nodegit'
homedir = require 'homedir'

argv = require 'yargs'
  .option 'example-config',
    type: 'boolean'
    describe: "Generate an example config file"

  .option 'config',
    alias: 'c'
    type: 'string'
    default: path.join(homedir(), '.pullitzer.json')
    describe: "Specify a config file with default options"
  .help 'help'
  .argv

if argv['example-config']
  throw 'Example.config.json already exists' if fs.existsSync 'example.config.json'
  readstream = fs.createReadStream(path.join __dirname, 'example.config.json')
  writestream = fs.createWriteStream('example.config.json')
  console.log "example.config.json written to current directory"
  process.exit()

try
  config = require path.resolve(argv.config)
catch e
  console.warn e
  console.error "no config file found, try --config yourconfig.json or generate one with --example-config"
  process.exit()

readBody = (req) -> new Promise (resolve, reject) ->
  bufs = []
  req.on 'data', (buf) -> bufs.push buf
  req.on 'end', -> resolve Buffer.concat bufs


parallelshuffle = (strings...) ->
  last = strings[0].length-1
  order = [0..last]
  for n in [last..1] by -1
    i = Math.floor(Math.random() * (n+1))
    [order[i], order[n]] = [order[n], order[i]]
  for string in strings
    (string[order[i]] for i in [0..last]).join('')

checksig = (body, sig, secret) ->
  [sigtype, signature] = sig.split('=')
  console.log "sigtype/signature", sigtype, signature
  hmac = crypto.createHmac(sigtype, secret)
  hmac.update(body)
  result = hmac.digest('hex')

  [sresult, ssignature] = parallelshuffle(result, signature)
  sresult == ssignature


server = new http.Server()
server.listen config.webhook.port, config.webhook.ip
server.on 'request', (req, res) ->
  res.statusCode = 400
  readBody req
  .then (rawbody) ->
    if config.webhook.secret? and !checksig(rawbody, req.headers["x-hub-signature"], config.webhook.secret)
      throw new Error("Signature verification failed")
    rawbody
  .then JSON.parse
  .then (body) ->
    reponame = body.repository.full_name
    throw new Error "Unknown repo" if !config.repos[reponame] and !repoconfig.accept_unknown_repos

    repoconfig = {}
    repoconfig[k] = v for k, v of config.all_repos or {}
    repoconfig[k] = v for k, v of config.repos[reponame] or {}

    res.statusCode = 500
    repodir = path.join config.repodir, if repoconfig.use_short_name then body.repository.name else reponame

    updateRepo(repodir, body.repository.clone_url)
    .then ->
      pullRepo(repodir, repoconfig.pull) if repoconfig.pull
    .then ->
      exec repoconfig.after if repoconfig.after


  .then ->
    console.log "request completed successfully"
    res.statusCode = 200
    res.end("OK")
  , (err) ->
    console.error "request failed", err
    res.end("ERROR: " + err.message or "Request failed")

cloneOrOpenRepo = (dir, url) ->
  git.Repository.open(dir).catch -> git.Clone(url, dir)


updateRepo = (dir, url) ->
  cloneOrOpenRepo(dir, url)
  .then (repo) -> repo.fetchAll()

pullRepo = (dir, branch) ->
  git.Repository.open(dir)
  .then (repo) -> repo.mergeBranches("master", branch)


exec = (cmd, options={}) -> new Promise (resolve, reject) ->
  child_process.exec cmd, options, (err, stdout, stderr) -> if err then reject stdout else resolve stderr

Promise.resolve()
