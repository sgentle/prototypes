fetch = require 'node-fetch'
FormData = require 'form-data'

#https://api.steampowered.com/IPublishedFileService/QueryFiles/v1/?key=&format=json&search_text=standard+build+6.86&query_type=11&filetype=12&appid=570&requiredtags[0]=hero%20build&numperpage=10&page=1&match_all_tags=0&include_recent_votes_only=0&totalonly=0&return_vote_data=0&return_tags=0&return_kv_tags=1&return_previews=0&return_children=0&return_short_description=0&return_for_sale_data=0&return_metadata=1

fs = require 'fs'
http = require 'http'
torte = require './torte.json'

throttler = (delay) -> (arg) -> new Promise (resolve) -> setTimeout (-> resolve arg), delay

a = torte.response.publishedfiledetails

getNext = (i=0) ->
  file = a[i]
  console.log "downloading", file.filename, file.file_url
  fetch(file.file_url)
  .then (result) ->
    console.log "writing", file.filename
    result.body.pipe(fs.createWriteStream(file.filename))
  .then throttler(500)
  .then -> getNext i+1


getNext()
