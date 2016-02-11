# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

HttpClient = require 'scoped-http-client'
querystring = require 'querystring'


module.exports = (robot) ->

  defaults =
    event: process.env.HUBOT_CFA_CHECKIN_DEFAULT_EVENT or 'Weekly Civic Hack Night'

  config =
    slack_api_token: process.env.HUBOT_SLACK_API_TOKEN
    brigade_slug: process.env.HUBOT_CFA_BRIGADE_SLUG or 'test-checkin'

  robot.respond /checkin(( @[-_\w]+)+)?( .+)?/, (res) ->
    [usernames, _, event] = res.match[1..4].map (m) -> m.trim() if m
    calling_username = res.message.user.name

    usernames = usernames or calling_username
    event = event or defaults.event or null

    usernames = (u.trim().replace('@', '') for u in usernames.split ' ')

    users = usernames.map (username) -> getSlackUsers().filter (u) -> u.username = username

    checkinUser(user, event) for user in users

    res.send "username #{usernames}. event: #{event}."

  getSlackApiResponse = api_method, cb ->
    robot.http("https://slack.com/api/#{api_method}?token=#{config.slack_api_token}")
      .get() (err, res, body) ->
        if err
          res.send "Encountered an error using Slack API: #{err}"
          return
        else
          data = JSON.parse body

  getSlackUsers = ->
    data = getSlackApiResponse('users.list')
    console.log data
    users = ({username: user.name, email: user.profile.email, name: user.profile.real_name} for user in data.members)
    return users

  checkinUser = (user, event) ->
    data =
      name: user.name
      email: user.email
      event: event
      cfapi_url: "https://www.codeforamerica.org/api/organizations/#{config.brigade_slug}"

    robot.http("https://www.codeforamerica.org/brigade/#{config.brigade_slug}/checkin")
      .header('Content-Type', 'application/json')
      .post(data) (err, res, body) ->
        if err
          res.send "Encountered an error using Slack API: #{err}"
          return
        else
          robot.send "Successful checked in #{user.username} to '#{event}'!"

  class Slack
    http: (method) ->
      slackBaseUrl = 'https://slack.com/api/'
      HttpClient.create("#{slackBaseUrl}#{method}")
        .query(token: config.slack_api_token)
        .headers(Accept: 'application/json')

    get: (method, cb) ->
      @http(method)
        .get() (err, res, body) ->
          if err?
            cb(err)
            return
          json_body = null
          switch res.statusCode
            when 200 then json_body = JSON.parse(body)
            else
              console.log "Error!"

          cb null, json_body

  class CFA
    http: (method) ->
      cfaBaseUrl = "https://www.codeforamerica.org/brigade/#{config.brigade_slug}"
      HttpClient.create("#{cfaBaseUrl}#{method}/")
        .headers(Accept: 'application/x-www-form-urlencoded')

    post: (method, data, cb) ->
      form_data = querystring.stringify(data)
      @http(method)
        .post(form_data) (err, res, body) ->
          if err?
            return cb(err)

          switch res.statusCode
            unless 302
              console.log "Error!"

          cb()

    checkin: (data, cb) ->
      @post('checkin', data, cb)


  slackCheckinPost = (msg, data, cb) ->
    json = JSON.stringify(data)
    msg.http("https://www.codeforamerica.org/brigade/#{config.brigade_slug}/checkin")
      .header('Content-Type', 'application/json')
      .post(json) (err, res, body) ->
        switch res.statusCode
          when 200
            json = JSON.parse(body)
            cb(json)
          else
            console.log res.statusCode
            console.log body



  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
