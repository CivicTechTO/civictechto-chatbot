# Description:
#   Create livestream events on YouTube.
#
# Dependencies:
#   googleapis
#   hubot-google-auth
#
# Configuration:
#   None
#
# Commands:
#   hubot livestream - Show livestream instructions
#   hubot livestream "Hacknight #123 with Maria Taylor: Some topic" - Set the livestream event title
#   hubot livestream reset - Set a generic event title
#
# Author:
#   patcon@github

HubotGoogleAuth = require 'hubot-google-auth'
auth = {}

config =
  client_id: process.env.HUBOT_GOOGLE_CLIENT_ID
  client_secret: process.env.HUBOT_GOOGLE_CLIENT_SECRET
  video_id: process.env.HUBOT_LIVESTREAM_VIDEO_ID || 'YXfdtsO4f5w'
  default_title: process.env.HUBOT_LIVESTREAM_DEFAULT_TITLE || 'Civic Hacknight: Presentation'
  # TODO: Implement support for a second persistent broadcast for pitches.

GOOGLE_SCOPES = [
  'https://www.googleapis.com/auth/youtube',
  'https://www.googleapis.com/auth/youtube.force-ssl',
  'https://www.googleapis.com/auth/youtube.upload',
]

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    auth = new HubotGoogleAuth "YouTube", config.client_id, config.client_secret, "http://localhost:2222", GOOGLE_SCOPES.join(';'), robot.brain

  robot.respond /set youtube code (.+)/i, (msg) ->
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
      msg.send "Then use the command @#{robot.name} set youtube code <code>"
      return

    msg.send "Tokens already set."

  robot.respond /reset tokens/i, (msg)->
    msg.send "Please copy the code at this url #{auth.generateAuthUrl()}"
    msg.send "Then use the command @#{robot.name} set youtube code <code>"
    return

  # See: https://stackoverflow.com/a/3569031/504018
  pattern = ///
            livestream(?:\s
              (")?
                (.+)
              \1
            )?
            ///i
  robot.respond pattern, (msg) ->
    title = msg.match[2]

    # Thread the bot response if not in thread already
    if not msg.message.thread_ts
      msg.message.thread_ts = msg.message.id

    event_title = if title == 'reset' then config.default_title else title

    auth.validateToken (err, resp) ->
      if err
        robot.logger.error err
        return

      # See: https://developers.google.com/youtube/v3/live/docs/liveBroadcasts
      youtube = auth.google.youtube('v3')
      youtube.liveBroadcasts.list {part: "id,snippet,status,contentDetails", broadcastStatus: 'upcoming', broadcastType: 'persistent'}, (err, res) ->
        if err
          robot.logger.error err
          return

        matches = res.items.filter (x) -> x.id == config.video_id

        if matches.length == 1
          robot.logger.info "found livestream!"
          video = matches[0]
          if event_title
            video.snippet.title = event_title
            youtube.liveBroadcasts.update {part: 'id,snippet,status,contentDetails', resource: video}, (err, res) ->
              if err
                robot.logger.error err
                return

              robot.logger.debug res
              msg.send "Livestream title updated!"

          message = """
                    Woo! Here's *how to run* the livestream: :point_down: :point_down: :point_down:
                    :one: *Install* the Streamlabs mobile app: https://streamlabs.com/mobile-app
                    :two: *Ask* for access to our YouTube account.
                    :three: *Open* the YouTube Studio event page: https://studio.youtube.com/channel/#{video.snippet.channelId}/livestreaming/dashboard?v=#{video.id}
                    :four: *Note* the _stream key_ and _stream URL_.
                    :five: Streamlabs app: *Configure* a _Custom RTMP server_ with the above info.
                    :six: You're all set! Make sure the title is up-to-date, and *start livestreaming!*

                    :bird: The key stuff to share is:
                    `#{video.snippet.title} https://youtu.be/#{video.id}`
                    """
          msg.send message
          return
