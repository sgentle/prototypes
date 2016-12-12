client = require 'hnap/js/soapclient'

config = require './config.json'

console.log config.username, config.password, config.url

client.login config.username, config.password, config.url
  .then (status) ->
    throw new Error "login failed" if status isnt 'success'
  .then ->
    console.log "Logged in okay! Rebooting..."
    client.reboot()
  .then ->
    console.log "Router rebooted"
