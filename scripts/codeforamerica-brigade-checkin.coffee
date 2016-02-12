# Description:
#   A hubot script that allows checkins to Code for America brigade events from Slack.
#
# Configuration:
#   HUBOT_SLACK_TOKEN               - Required for fetching email/name of Slack users.
#   HUBOT_CFA_BRIGADE_ID            - Required brigade ID from CfA API: http://codeforamerica.org/api/organizations?q=My+City
#   HUBOT_CFA_CHECKIN_DEFAULT_EVENT - Default event name when unspecified. Default: Civic Hack Night. (optional)
#
# Commands:
#   hubot checkin [@<user1> [...]] [<event name>] - check into a brigade event. (user defaults to speaker.)
#

HttpClient = require 'scoped-http-client'
querystring = require 'querystring'

defaults =
  event: process.env.HUBOT_CFA_CHECKIN_DEFAULT_EVENT or 'Civic Hack Night'

config =
  slack_api_token: process.env.HUBOT_SLACK_TOKEN
  brigade_id: process.env.HUBOT_CFA_BRIGADE_ID or 'test-checkin'

# Add some syntactic sugar
String::capitalize = ->
  (
    this.split(/\s+/).map (word) ->
      word[0].toUpperCase() + word[1..-1].toLowerCase()
  ).join ' '

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

        cb json_body

  users: (cb) ->
    @get('users.list', cb)

class CFA
  http: (method) ->
    cfaBaseUrl = "https://www.codeforamerica.org/brigade/#{config.brigade_id}"
    HttpClient.create("#{cfaBaseUrl}#{method}/")
      .headers(Accept: 'application/x-www-form-urlencoded')

  post: (method, data, cb) ->
    form_data = querystring.stringify(data)
    @http(method)
      .post(form_data) (err, res, body) ->
        if err?
          return cb(err)

        switch res.statusCode
          when not 302
            console.log "Error!"

        return cb(null, true, data.username)

  checkin: (data, cb) ->
    @post('checkin', data, cb)

slack = new Slack
cfa = new CFA

module.exports = (robot) ->
  robot.respond /checkin(( @[-_\w]+)+)?( (.+))?$/, (res) ->
    [usernames, _, _, event] = res.match[1..4].map (m) -> m.trim() if m
    calling_username = res.message.user.name

    usernames = usernames or calling_username
    event = event or defaults.event

    usernames = (u.trim().replace('@', '') for u in usernames.split ' ')

    checkinUsers(usernames, event, (err, success, username) ->
      if success?
        res.send "Successfully checked #{username} into '#{event}'!"
      else
        res.send "Oops! Something went wrong checking #{username} into '#{event}'..."
    )

  checkinUsers = (usernames, event, cb) ->
    slack.users (slack_users) ->
      all_users = slack_users.members
      checkinUser(username, all_users, event, cb) for username in usernames

  checkinUser = (username, all_users, event, cb) ->
    [user] = all_users.filter (u) -> u.name == username
    if user
      data =
        username: user.name
        name: user.profile.real_name
        email: user.profile.email
        event: event
        cfapi_url: "https://www.codeforamerica.org/api/organizations/#{config.brigade_id}"

      console.log "Brigade event checkin data: #{JSON.stringify(data)}"
      cfa.checkin(data, cb)
    else
      res.send "Error!"
