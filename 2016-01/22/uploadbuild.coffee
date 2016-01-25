fetch = require 'node-fetch'
qs = require 'qs'
build2json = require './build2json'

{OAUTH_TOKEN, OAUTH_INFO} = require './secrets.json'


cookie = "dota_oauth_token=#{OAUTH_TOKEN}; dota_oauth_info=#{OAUTH_INFO};"

data = build2json process.argv[2]
body = qs.stringify { post: data }

body = body.replace /%5B\d+%5D=/g, '%5B%5D=' #Valve API needs indexes for intermediate objects, no index for final objects


fetch 'http://www.dota2.com/workshop/builds/save',
  method: 'POST'
  headers:
    'Content-Type': 'application/x-www-form-urlencoded'
    'Cookie': cookie
  body: body
.then (res) ->
  console.log res.status, res.statusText
  res.text()
.then (body) ->
  console.log body
