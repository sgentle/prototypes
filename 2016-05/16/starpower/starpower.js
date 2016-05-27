const canvas = require('canvas')
const jsdom = require('jsdom')
const fetch = require('node-fetch')

const repo = process.argv[2] || (console.log('Usage: node starpower.js <reponame>'), process.exit(2))

const jsprom = (site) =>
  new Promise((resolve, reject) =>
    jsdom.env(site, (err, window) => err ? reject(err) : resolve(window))
  )

const showOrgs = (url, pages=5) =>
  jsprom(url).then(window => {
    console.log('page', pages)
    const $ = window.document.querySelector.bind(window.document)
    const $$ = window.document.querySelectorAll.bind(window.document)
    const orgs = Array.from($$('.follow-list-info > .octicon-organization + span')).map(x => x.textContent)
    const next = $('.pagination *:last-child')

    if (next && next.href && pages > 1) {
      return showOrgs(next.href, pages - 1).then(newOrgs => orgs.concat(newOrgs))
    }
    else {
      return orgs
    }
  })

showOrgs(`https://github.com/${repo}/stargazers`)
  .then(orgs => console.log("orgs:", orgs.join(', ')))
  .catch(err => console.error(err))