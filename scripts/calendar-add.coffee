# Description:
#   Allow users to add events to a shared calendar via links.
#
#   It depends on a tiny app called `event-metadata-parser` in order to extract
#   event data from webpages: https://event-metadata-parser.herokuapp.com/~
#
# Dependencies:
#   googleapis
#   request
#
# Configuration:
#   None.
#
# Commands:
#   hubot gcal add <url> - Add event url to community calendar (Supports: EventBrite)
#
# Author:
#   patcon

Url = require 'url'
request = require 'request'

HubotGoogleAuth = require 'hubot-google-auth'
auth = {}

EVENT_PARSER_BASE_URL = 'https://event-metadata-parser.herokuapp.com/'

config =
  client_id: process.env.HUBOT_GOOGLE_CLIENT_ID
  client_secret: process.env.HUBOT_GOOGLE_CLIENT_SECRET
  scope: "https://www.googleapis.com/auth/calendar"
  calendar_id: process.env.HUBOT_GCAL_ID


module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    auth = new HubotGoogleAuth "GoogleCalendar", config.client_id, config.client_secret, "http://localhost:2222", config.scope, robot.brain

  robot.respond /set code (.+)/i, (msg) ->
    code = msg.match[1]
    auth.setCode code, (err, resp) ->
      if err
        msg.send "Could not obtain tokens with code: #{code}"
        return

      msg.send "Code successfully set. Tokens now stored in brain for service: #{auth.serviceName}"

  robot.respond /check tokens/i, (msg) ->
    tokens = auth.getTokens()
    if !tokens.token
      msg.send "No tokens found"
      msg.send "Please copy the code at this url #{auth.generateAuthUrl()}"
      msg.send "Then use the command @toby set code <code>"
      return

  robot.respond /gcal add (.+)/i, (msg) ->

    # Thread the bot response if not in thread already
    if not msg.message.thread_ts
      msg.message.thread_ts = msg.message.id

    url = Url.parse msg.match[1]
    if not /eventbrite/i.test url.host
      msg.send "We can only read from EventBrite right now... sorry!"
      return

    data_url = "#{EVENT_PARSER_BASE_URL}/#{url.href}"
    request data_url, (err, res, body) ->
      event = JSON.parse body

      auth.validateToken (err, resp) ->
        if err
          console.log err
          return

        calendar = auth.google.calendar('v3')
        calendar.events.list {calendarId: config.calendar_id, q: event.url}, (err, res) ->
          if err
            msg.send "ERROR: could not search for existing event: #{err}"
            return

          if res.items.length > 0
            console.log res.items[0].start
            start = res.items[0].start
            start = if start.date? then start.date else start.dateTime
            start = new Date(start).toDateString()
            msg.send "Oops! It appears this is already in the calendar as '#{res.items[0].summary}' on #{start}"
            return

          data =
            calendarId: config.calendar_id
            resource:
              summary: event.title
              description: event.url
              location: event.location
              start:
                dateTime: event.start_time
              end:
                dateTime: event.end_time

          calendar.events.insert data, (err, res) ->
            if err
              msg.send "ERROR: could not create event: #{err}"
              return

            msg.send "Added '#{event.title}' to community calendar: http://civictech.ca/calendar/"

            if robot.adapter.constructor.name == 'SlackBot'
              robot.adapter.client.web.reactions.add('+1', {channel: msg.message.room, timestamp: msg.message.id})

