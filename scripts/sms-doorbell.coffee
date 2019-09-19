# Description:
#   Broadcast messages from a Voip.ms number into a chat room.
#
#   To use this script, you must:
#   - Buy an SMS-enabled VOIP phone number (aka your DID) from voip.ms. (The
#     cost is as low as USD$0.85/month.)
#   - Set up that DID's "SMS URL Callback" to point to
#     https://example-bot.herokuapp.com/doorbell?... (using whatever your base url is
#     for your hubot).
#   - Full instructions: https://github.com/CivicTechTO/hubot-toby/wiki/Script:-SMS-Doorbell
#
# Dependencies:
#   node-emoji
#   proxy-agent
#   querystring
#
# Configuration:
#   HUBOT_DOORBELL_PHONE_NUMBER
#   HUBOT_DOORBELL_CHANNEL_OPEN
#   HUBOT_DOORBELL_CHANNEL_PRIV
#   HUBOT_VOIPMS_API_PROXY_URL
#   HUBOT_VOIPMS_API_USER
#   HUBOT_VOIPMS_API_PASS
#
# Commands:
#   None.
#
# Author:
#   patcon

emoji = require 'node-emoji'
querystring = require 'querystring'
ProxyAgent = require 'proxy-agent'

config =
  phone_number: process.env.HUBOT_DOORBELL_PHONE_NUMBER or '555-555-5555'
  # Find this here: https://api.slack.com/methods/groups.list/test
  # Can use chan ID or the human-readable channel name.
  channel_open: process.env.HUBOT_DOORBELL_CHANNEL_OPEN
  channel_priv: process.env.HUBOT_DOORBELL_CHANNEL_PRIV
  voipms_user: process.env.HUBOT_VOIPMS_API_USER
  voipms_pass: process.env.HUBOT_VOIPMS_API_PASS
  # Because the Voip.ms API requires a static IP to authorize access to it,
  # we use a fixie heroku add-on as a proxy, which gets 500 free connections/month
  # See: https://elements.heroku.com/addons/fixie
  proxy_url: process.env.HUBOT_VOIPMS_API_PROXY_URL || 'http://fixie:HZOy3W1xBMA76KC@velodrome.usefixie.com:80'

module.exports = (robot) ->
  web = robot.adapter.client.web

  robot.router.get '/doorbell', (req, res) ->
    sms_msg = req.query.message
    phone_re = /(\d+?)(\d{3})(\d{4})$/
    if req.query.from
      from = req.query.from.match(phone_re)[1..3].join('-')

    if config.channel_open
      bot_msg_open = """
      @here there's someone at the door! Someone texted our doorbell, #{config.phone_number}:
      > #{sms_msg}
      (Please use a reaction emoji if you're heading to help.)
      """
      robot.adapter.client.web.chat.postMessage(config.channel_priv, bot_msg_open, {
        as_user: true,
        parse: 'full',
        attachments: [
          {
            fallback: '',
            callback_id: 'hubot_doorbell_caller_' + from.replace(/-/g, '')
          }
        ]
      })

    if config.channel_priv
      bot_msg_priv = """
      Here's the phone number that texted our doorbell: #{from}
      (See #organizing-open for full context.)
      """
      robot.adapter.client.web.chat.postMessage(config.channel_priv, bot_msg_priv, {
        as_user: true,
        parse: 'full',
        attachments: [
          {
            fallback: '',
            callback_id: 'hubot_doorbell_caller_' + from.replace(/-/g, ''),
          }
        ]
      })

    # Voip.ms expects this on successful messages, for their "callback retry"
    # feature to work.
    res.send 'ok'

  robot.hearReaction (res) ->
    if not isSmsSendingConfigured()
      return

    if not reactingToBot(res)
      return

    if res.message.type != 'added'
      return

    reacted_msg = res.message.item
    reacting_user = res.message.user.name
    reacting_emoji = res.message.reaction
    robot.logger.info "we're reacting to a bot message: " + reacted_msg.ts
    web.conversations.history reacted_msg.channel, {latest: reacted_msg.ts, limit: 1, inclusive: true}
      .then (resp) ->
        reacted_message = resp.messages[0]
        if reacted_message.attachments? and reacted_message.attachments[0].callback_id.startsWith 'hubot_doorbell'
          dst_phone = reacted_message.attachments[0].callback_id.replace 'hubot_doorbell_caller_', ''
          robot.logger.info reacted_message.attachments[0]
          sms_auto_response = "Auto-response: #{reacting_user} acknowledged your message with a :#{reacting_emoji}: emoji"
          sms_auto_response = emoji.emojify(sms_auto_response)
          params =
            api_username: config.voipms_user
            api_password: config.voipms_pass
            method: 'sendSMS'
            did: '6478122649'
            dst: dst_phone
            message: sms_auto_response

          qs = querystring.stringify(params)
          robot.http('https://voip.ms/api/v1/rest.php?'+qs, {agent: new ProxyAgent config.proxy_url})
            .get() (err, res, body) ->
              data = JSON.parse body
              if data.status isnt 'success'
                # TODO: Better error surfacings in Slack
                robot.logger.warning "Something went wrong with SMS"
                return

              slack_response = "Sent this SMS to texter:\n> #{sms_auto_response}"
              robot.adapter.client.web.chat.postMessage(reacted_msg.channel, slack_response, {thread_ts: reacted_msg.ts, as_user: true})
              return

  reactingToBot = (res) ->
    return res.robot.name == res.message.item_user.name

  isSmsSendingConfigured = ->
    return config.voipms_user? and config.voipms_pass?
