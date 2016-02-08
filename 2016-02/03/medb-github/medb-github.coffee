jsdom = require 'jsdom'
fetch = require 'node-fetch'

CONTRIB_QUERY = '#contributions-calendar .contrib-number'
POPULAR_REPO_QUERY = '.public.source'

API_FIELDS = ['followers', 'following', 'public_repos', 'public_gists']

numcontent = (x) -> Number x.textContent.replace(/\D/g,'')

jsprom = (site) ->
  new Promise (resolve, reject) ->
    jsdom.env site, (err, window) -> if err then reject err else resolve window

get = (username) ->
  Promise.all [
    jsprom("https://github.com/#{username}")
    fetch("https://api.github.com/users/#{username}").then((res) -> res.json())
  ]
  .then ([window, apidata]) ->
    $ = window.document.querySelector.bind(window.document)
    $$ = window.document.querySelectorAll.bind(window.document)
    d = {}
    d[k] = apidata[k] for k in API_FIELDS

    [d.contributions_year, d.longest_streak, d.current_streak] =
      Array.from($$(CONTRIB_QUERY)).map numcontent

    repoStars = {}
    contribStars = {}
    popularRepoStars = 0
    for repoBlock in $$(POPULAR_REPO_QUERY)
      stars = numcontent repoBlock.querySelector('.stars')
      owner = repoBlock.querySelector('.owner')?.textContent
      repo = repoBlock.querySelector('.repo').textContent

      if owner
        contribStars[repo] = stars
      else
        repoStars[repo] = stars
        popularRepoStars += stars
    d.popular_repo_stars = popularRepoStars
    ret =
      github:
        [{tags: {}, values: d}]
      'github-stars':
        ({tags: {repo: k}, values: {stars: v}} for k, v of repoStars)
  .catch (e) ->
    console.error("error getting github data", e)

module.exports = (config) -> get config.username


