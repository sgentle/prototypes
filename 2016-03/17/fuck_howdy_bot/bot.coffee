SlackBot = require 'slackbots'
conf = require './config'

bot = new SlackBot conf

console.log "bot", bot

bot.on 'start', ->
  bot.postMessageToChannel 'general', "@channel Hi! I'm Fuck Howdy Bot! I can tell you're busy, and I have a lot of respect for your time and focus, so I'm going to message you every hour until you literally die of irritation. Love ya! <3"