# Description:
#   Broadcast messages from a Voip.ms number into a chat room.
#
#   To use this script, you must:
#   - Buy an SMS-enabled VOIP phone number (aka your DID) from voip.ms. (The
#     cost is as low as USD$0.85/month.)
#   - Set up that DID's "SMS URL Callback" to point to
#     https://example-bot.herokuapp.com/doorbell (using whatever your base url is
#     for your hubot).
#
# Dependencies:
#   None.
#
# Configuration:
#   HUBOT_DOORBELL_PHONE_NUMBER
#   HUBOT_DOORBELL_CHANNEL_OPEN
#   HUBOT_DOORBELL_CHANNEL_PRIV
#
# Commands:
#   None.
#
# Author:
#   patcon

config =
  phone_number: process.env.HUBOT_DOORBELL_PHONE_NUMBER or '555-555-5555'
  # Find this here: https://api.slack.com/methods/groups.list/test
  # Can use chan ID or the human-readable channel name.
  channel_open: process.env.HUBOT_DOORBELL_CHANNEL_OPEN
  channel_priv: process.env.HUBOT_DOORBELL_CHANNEL_PRIV

module.exports = (robot) ->
  robot.router.get '/doorbell', (req, res) ->
    sms_msg = req.query.message
    phone_re = /(\d+?)(\d{3})(\d{4})$/
    from = req.query.from.match(phone_re)[1..3].join('-')

    if config.channel_open
      bot_msg_open = """
      @here there's someone at the door! Someone texted our doorbell, #{config.phone_number}:
      > #{sms_msg}
      (Please use a reaction emoji if you're heading to help.)
      """
      robot.messageRoom config.channel_open, bot_msg_open

    if config.channel_priv
      bot_msg_priv = """
      Here's the phone number that texted our doorbell: #{from}
      (See #organizing-open for full context.)
      """
      robot.messageRoom config.channel_priv, bot_msg_priv

      # Voip.ms expects this on successful messages, for their "callback retry"
      # feature to work.
    res.send 'ok'
