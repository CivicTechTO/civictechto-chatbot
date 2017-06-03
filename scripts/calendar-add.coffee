# Description:
#   Allow users to add events to a shared calendar via links.
#
# Dependencies:
#   googleapis
#   request
#
# Configuration:
#   None.
#
# Commands:
#   hubot gcal add <url> - Add event url to community calendar
#
# Author:
#   patcon

Url = require 'url'
request = require 'request'
google = require 'googleapis'

calendar = google.calendar 'v3'
globalError

EVENT_PARSER_BASE_URL='https://event-metadata-parser.herokuapp.com/'

config =
  google_email: process.env.HUBOT_GOOGLE_API_EMAIL
  google_key: process.env.HUBOT_GOOGLE_API_KEY
  google_scopes: ["https://www.googleapis.com/auth/analytics.readonly"]

module.exports = (robot) ->
  try
    oauth2Client = new google.auth.JWT(config.google_email, null, config.google_key, config.google_scopes, null)
  catch err
    globalError = "Error on load - check your envvars HUBOT_GOOGLE_API_EMAIL and HUBOT_GOOGLE_API_KEY."

  robot.respond /gcal add (.+)/i, (msg) ->
    if globalError
      return msg.reply globalError

    url = Url.parse msg.match[1]
    if not /eventbrite/i.test url.host
      msg.send "We can only read from EventBrite right now... sorry!"
      return

    data_url = "#{EVENT_PARSER_BASE_URL}/#{url.href}"
    request data_url, (err, res, body) ->
      event = JSON.parse body
      msg.send "Added event to community calendar: http://civictech.ca/calendar/"
      if robot.adapter.constructor.name == 'SlackBot'
        robot.adapter.client.web.reactions.add('+1', {channel: msg.message.room, timestamp: msg.message.id})
        robot.adapter.client.web.reactions.add('question', {channel: msg.message.room, timestamp: msg.message.id})

