fetch = require 'node-fetch'
striptags = require 'striptags'

numcontent = (x) -> Number x.textContent.replace(/\D/g,'')

jsprom = (site) ->
  new Promise (resolve, reject) ->
    jsdom.env site, (err, window) -> if err then reject err else resolve window

get = (query_url) ->
  fetch query_url
  .then (res) -> res.json()
  .then (result) ->
    posts =
      for row in result.rows
        values = {}
        values.wordcount = striptags(row.value.body).split(/\s+/).length
        values.time = new Date(row.value.created)
        values.revisions = Number row.value._rev.split('-')[0]
        attachments = 0
        attachments++ for k of row.value._attachments
        values.attachments = attachments
        tags = {id: row.id.replace(/^posts\//,'')}

        {values, tags}
    {posts}


module.exports = (config) -> get config.query_url


