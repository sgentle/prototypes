jsdom = require 'jsdom'
fetch = require 'node-fetch'

CONTRIB_QUERY = '#contributions-calendar .contrib-number'
POPULAR_REPO_QUERY = '.public.source'

API_FIELDS = ['followers', 'following', 'public_repos', 'public_gists']

numcontent = (x) -> Number x.textContent.replace(/\D/g,'')

jsprom = (site) ->
  new Promise (resolve, reject) ->
    jsdom.env site, (err, window) -> if err then reject err else resolve window

get = (domain) ->
  jsprom("https://news.ycombinator.com/from?site=#{domain}")
  .then (window) ->
    $$ = window.document.querySelectorAll.bind(window.document)
    karma = Array.from($$('.score'))
      .map((x) -> parseInt(x.textContent) || 0)
      .reduce((a, b) -> a + b)

    hackernews: [{tags: {}, values: {karma}}]
  .catch (e) ->
    console.error("error getting HN data", e)

module.exports = (config) -> get config.domain