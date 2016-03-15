console.log 'hello'

Git = require 'nodegit'

fs = require 'fs'

addDetails = (summary, details) ->
  el = document.createElement 'details'
  el.style.marginLeft = "2em"
  summaryEl = document.createElement 'summary'
  el.appendChild summaryEl
  summaryEl.innerHTML = summary
  el.innerHTML += details
  el

giffHistory = (startCommit) ->
  history = startCommit.history()
  currentEl = document.body

  history.on 'commit', (commit) ->
    newDetails = addDetails commit.message(), """
    <dl>
    <dt>Commit<dd>#{commit.sha()}
    <dt>Author<dd>#{commit.author().name()} <#{commit.author().email()}>
    <dt>Date<dd>#{commit.date()}
    <dt>Message<dd>#{commit.message()}
    </dl>
    """
    currentEl.appendChild newDetails
    currentEl = newDetails
  history.start()

Git.Repository.open 'testrepo'
  .then (repo) ->
    repo.getReferences(Git.Reference.TYPE.OID)
  .then (refs) ->
    console.log "refs", refs
    Promise.all(
      refs
      .filter (ref) -> ref.isBranch && ref.target()
      .map (ref) ->
        Git.Commit.lookup ref.repo, ref.target()
    )
  .then (commits) ->
    commits.map giffHistory

  #   repo.getMasterCommit()
  # .then (masterCommit) ->

  .catch (err) -> console.error err