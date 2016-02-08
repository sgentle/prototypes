nano = require 'nano'
influx = require 'influx'

config = require './config.json'

indb = influx config.influx
outdb = nano config.couch.url

PREFIX = "stats/"

promQuery = (q) -> new Promise (resolve, reject) -> indb.query q, (err, result) -> if err then reject err else resolve result

stat = (key) ->
  [series, field] = key.split '.'
  promQuery("select #{field} as value from #{series}")
  .then (result) -> result[0][0].value

put = (name, key, val) ->
  new Promise (resolve, reject) ->
    id = "stats/#{key}"
    data =
      _id: "stats/#{key}"
      name: name
      value: val
      type: 'stats'

    outdb.get id, (err, existing) ->
      data._rev = existing._rev if existing

      outdb.insert data, (err, result) ->
        if err then reject err else resolve result


monotonic = (name, couchkey, influxkey) ->
  stat influxkey
  .then (result) ->
    put name, couchkey, result


monotonic 'Repositories on GitHub', 'github_repos', 'github.max(public_repos)'
monotonic 'Peak stars on GitHub', 'github_stars', 'github.max(popularRepoStars)'
monotonic 'Total posts', 'website_posts', 'posts.count(wordcount)'
monotonic 'Total words', 'website_words', 'posts.sum(wordcount)'
