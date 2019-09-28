# Description:
#   Watch for Twitter links and offer to retweet them. Uses Slack emoji
#   reactions to vote/flag.
#
# Dependencies:
#   "get-urls": "*"
#   "q": "^1.0.1",
#   "twitter": "^0.2.9"
#   "underscore": "*"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#   HUBOT_RETWEET_VOTE_THRESHOLD (default: 3)
#
# Author:
#   patcon@github

getUrls = require 'get-urls'
_ = require 'underscore'
{Promise} = require 'q'
Twitter = require 'twitter'
Twit = require 'twit'

config =
  api_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  api_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET
  vote_threshold: parseInt(process.env.HUBOT_RETWEET_VOTE_THRESHOLD, 10) or 3

EMOJI_FLAG = 'triangular_flag_on_post'
EMOJI_TWEET = 'bird'
EMOJI_DONE = 'white_check_mark'

module.exports = (robot) ->
  if robot.adapterName != 'slack'
    return
  retweet = (id) ->
    new Promise (resolve, reject) ->
      new Twitter(
        consumer_key: config.api_key
        consumer_secret: config.api_secret
        access_token_key: config.access_token
        access_token_secret: config.access_token_secret
      ).retweetStatus id, (data) ->
        if data instanceof Error
          reject(data)
        else
          resolve(data)

  T = new Twit(
    consumer_key: config.api_key
    consumer_secret: config.api_secret
    access_token: config.access_token
    access_token_secret: config.access_token_secret
  )

  status = (id) ->
    T.get 'statuses/show/:id',
      id: id
    , (err, data, response) ->
      console.log data

  web = robot.adapter.client.web

  robot.react (res) ->
    if res.message.item.type == "message" and not res.message.item.thread_ts? and res.message.reaction in [EMOJI_TWEET, EMOJI_FLAG]
      # Get the exact message to process text and reactions.
      web.conversations.history res.message.item.channel, {latest: res.message.item.ts, limit: 1, inclusive: true}
        .then (resp) ->
          # TODO check for tweets in text
          # TODO: Do sanity check against response message from chatbot, to ensure twitter link wasn't changed.
          message = resp.messages[0]
          flags = _.filter(message.reactions, (reaction) -> reaction.name == EMOJI_FLAG)
          votes = _.filter(message.reactions, (reaction) -> reaction.name == EMOJI_TWEET)
          # If we don't have content for both, skip
          # as it's not our target message scenario.
          if not (!!flags.length and !!votes.length)
            return

          flag_count = flags[0].count - 1
          vote_count = votes[0].count - 1

          # Abort if any flags.
          if flag_count > 0
            robot.logger.info "Flag is set. Aborting retweet flow."
            return

          # TODO: Delete RT when goes back below threshold.
          # TODO: Delete tweet if flag set after.
          if vote_count == config.vote_threshold
            # TODO: Implement actual tweeting logic.
            # If you are reading then, then you now know that there is no
            # automation yet. Tweets are done manually by @patcon until he sees
            # that this is worth actually implementing in code :)
            res.send {thread_ts: res.message.item.ts, text: "Yay! We'll RT this soon! cc: @socialmedia"}
            web.reactions.add(EMOJI_DONE, {channel: res.message.item.channel, timestamp: res.message.item.ts})

          robot.logger.debug "flags: #{flag_count}"
          robot.logger.debug "votes: #{vote_count}"

      robot.logger.info "#{res.message.type} reaction #{res.message.reaction}"

  isCandidate = (message) ->
    # Abort if empty.
    if not message.text
      return false

    # Abort if threaded.
    if message.rawMessage.thread_ts?
      return false

    # Abort if no links.
    if not getUrls(message.text).size > 0
      return false

    return true

  robot.listen(
    (message) ->
      return if isCandidate(message) then true else false
    (res) ->

      # This was used in the reddit linker script. Unsure if still helpful here...
      # See: https://github.com/sindresorhus/normalize-url
      urlNormalizationOpts =
        normalizeProtocol: false,
        removeTrailingSlash: false,
        stripWWW: false,

      url_re = /(https?:\/\/twitter.com\/[^\/]+\/status\/(\d+))\s*$/i
      for url in Array.from(getUrls(res.message.text, urlNormalizationOpts))
        match = url.match url_re
        if match
          robot.logger.info "Detected link to ask about retweet: #{url}"
          tweet_id = match[2]
          status tweet_id
            .then (t_res) ->
              robot.logger.info "Tweet is real!"

              if robot.adapter.constructor.name == 'SlackBot'
                robot.logger.debug res.message
                web.reactions.add(EMOJI_TWEET, {channel: res.message.room, timestamp: res.message.id})
                web.reactions.add(EMOJI_FLAG, {channel: res.message.room, timestamp: res.message.id})
              else
                robot.logger.info "Added reactions :#{EMOJI_FLAG}: and :#{EMOJI_TWEET}: to message"

              tweet_content = t_res.data.text
              twitter_account = 'CivicTechTO'
              reply = "Ohai! To <#{url}|*retweet* this> from
              <https://twitter.com/#{twitter_account}|@#{twitter_account}>,
              click the :#{EMOJI_TWEET}: reaction -- when there are
              #{config.vote_threshold} more reactions
              (#{config.vote_threshold+1} total), we'll RT it with a day.\n
              \n
              (To _prevent_ a RT, click :#{EMOJI_FLAG}:)"
              res.send {thread_ts: res.message.id, text: reply, unfurl_links: false, unfurl_media: false}

              # TODO: Figure out how to exit after first true tweet
  )

