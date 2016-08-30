Redis = require 'ioredis'

redis = new Redis()

redis.keys('*')
.then (keys) ->
  Promise.all keys.map (key) -> redis.get key
  .then (values) ->
    keys
      .map (k, i) -> [k, JSON.parse(values[i])]
      .sort()

.then (data) ->
  console.log "time,irl,internet"
  for x in data when x[0] isnt 'values'
    console.log "#{x[0].replace('values-', '')}:00:00Z,#{x[1].irl},#{x[1].internet}"

.then ->
  redis.quit()
