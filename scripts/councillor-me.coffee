# Description:
#   Race to the bottom.
#
#   Battle it out with your mates to see who is the
#   most important/coolest/sexiest/funniest/smartest of them all solely
#   based on the clearly scientific number of twitter followers.
#
#   Vanity will check all the users that a specific twitter account, like say maybe
#   your company's twitter account, follows and display them in order by followers.
#
# Dependencies:
#   "sprintf": "0.1.1"
#
# Configuration:
#   HUBOT_TWITTER_COUNCILLOR_LIST_SLUG
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# Commands:
#   hubot councillor me [bottom] - list the most or least popular councillors on Twitter
#
# Author:
#   maddox

_ = require "underscore"
Twit = require "twit"
list = process.env.HUBOT_TWITTER_COUNCILLOR_LIST_SLUG
list = list && list.split('/') || []
config =
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET
  list_slug: list.pop()
  list_owner: list.pop()

module.exports = (robot) ->
  twit = undefined
  robot.respond /councillor me( bottom)?$/i, (msg) ->
    unless config.consumer_key
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_KEY environment variable."
      return
    unless config.consumer_secret
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_SECRET environment variable."
      return
    unless config.access_token
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN environment variable."
      return
    unless config.access_token_secret
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN_SECRET environment variable."
      return

    unless twit
      twit = new Twit config

    bottom = msg.match[1]

    twit.get "lists/members",
      owner_screen_name: config.list_owner
      slug: config.list_slug
    , (err, res) ->
      return msg.send "Error" if err

      ranked_users = _.sortBy(res.users, 'followers_count')
      if bottom
        ranked_users = ranked_users[..4]
      else
        ranked_users = ranked_users.reverse()[..4]
      for user in ranked_users
        msg.send "#{user.name}: #{user.followers_count}"
