fetch = require 'node-fetch'

get = (domain) ->
  fetch "https://www.reddit.com/domain/#{domain}/.json"
  .then (res) -> res.json()
  .then (result) ->
    karma = result.data.children.reduce(((total, child) -> total + child.data.score), 0)
    reddit: [{tags: {}, values: {karma}}]
  .catch (e) ->
    console.error("error getting Reddit data", e)

module.exports = (config) -> get config.domain