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
#   hubot livestream - Create a YouTube livestream event
#
# Author:
#   patcon@github

HubotGoogleAuth = require 'hubot-google-auth'
auth = {}

config =
  client_id: process.env.HUBOT_GOOGLE_CLIENT_ID
  client_secret: process.env.HUBOT_GOOGLE_CLIENT_SECRET
  stream_name: process.env.HUBOT_YOUTUBE_STREAM_NAME || 'default'

config.stream_name = config.stream_name.toLowerCase()

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
      msg.send "Then use the command @#{robot.name} set code <code>"
      return

    msg.send "Tokens already set."

  robot.respond /reset tokens/i, (msg)->
    msg.send "No tokens found"
    msg.send "Please copy the code at this url #{auth.generateAuthUrl()}"
    msg.send "Threaden use the command @hubot set code <code>"
    return

  robot.respond /livestream/i, (msg) ->

    # Thread the bot response if not in thread already
    if not msg.message.thread_ts
      msg.message.thread_ts = msg.message.id

    auth.validateToken (err, resp) ->
      if err
        console.log err
        return

      console.log resp

      youtube = auth.google.youtube('v3')
      youtube.liveBroadcasts.list {part: "id,snippet,status,contentDetails", broadcastStatus: 'upcoming'}, (err, res) ->
        if err
          console.log err
          return
        console.log res.pageInfo
        console.log res.items[0]

        # TODO: Fetch from meetup
        meetup =
          title: "Hacknight #0: Testing"
          url: "https://www.meetup.com/Civic-Tech-Toronto/events/rhrqhryznbcb/"
          date: "2019-10-01"

        matches = res.items.filter (x) -> x.snippet.description.indexOf meetup.url >= 0
        if matches.length > 0
          console.log "found livestream!"
          video = matches[0]
          msg.send "The stream is all set up!"
          msg.send "The video link to share is: #{video.snippet.title} https://youtu.be/#{video.id}"
          msg.send "1. Log into the Civic Tech Toronto YouTube account: https://link.civictech.ca/passwords"
          msg.send "2. Go to the YouTube Studio page: https://studio.youtube.com/channel/#{video.snippet.channelId}/livestreaming/dashboard?v=#{video.id}"
          msg.send "3. Note the 'stream key' and 'stream URL' on that page."
          msg.send "4. Install the Streamlabs mobile livestreaming app: https://streamlabs.com/mobile-app"
          msg.send "5. In the app settings, choose the 'Custom RTMP server' as streaming platform, as use the key and url."
          return

        data =
          snippet: {
            title: meetup.title,
            description: meetup.url,
            scheduledStartTime: "#{meetup.date}T23:00:00.000Z",
          }
          status: {privacyStatus: 'unlisted'} # TODO

        # TODO: Get this from envvar human name
        stream_id = "rHZ-KlM_dHYipdk5K59ysA1569741287601558"
        youtube.liveBroadcasts.insert part: 'snippet,status', resource: data , (err, res) ->
          if err
            console.log err
            return

          video = res

          youtube.liveBroadcasts.bind part: 'id', id: video.id, streamId: stream_id, (err, res) ->
            return

          console.log "created livestream!"
          msg.send "The stream is all set up!"
          msg.send "The video link to share is: #{video.snippet.title} https://youtu.be/#{video.id}"
          msg.send "1. Log into the Civic Tech Toronto YouTube account: https://link.civictech.ca/passwords"
          msg.send "2. Go to the YouTube Studio page: https://studio.youtube.com/channel/#{video.snippet.channelId}/livestreaming/dashboard?v=#{video.id}"
          msg.send "3. Note the 'stream key' and 'stream URL' on that page."
          msg.send "4. Install the Streamlabs mobile livestreaming app: https://streamlabs.com/mobile-app"
          msg.send "5. In the app settings, choose the 'Custom RTMP server' as streaming platform, as use the key and url."
