module.exports = (robot) ->
  robot.router.get '/doorbell', (req, res) ->
    sms_msg = req.query.message
    phone_re = /(\d+?)(\d{3})(\d{4})$/
    from = req.query.from.match(phone_re)[1..3].join('-')
    # Find this here: https://api.slack.com/methods/groups.list/test
    # Can use chan ID or the human-readable channel name.
    room_open='C4SHX39B2' #organizing-open
    room_priv='G08V58H6Y' #organizing-priv

    bot_msg_open = """
    @here there's someone at the door! Someone texted our doorbell, 780-652-2649 (780-6LAB-6IX):
    > #{sms_msg}
    (Please use a reaction emoji if you're heading to help.)
    """

    bot_msg_priv = """
    Here's the phone number that texted our doorbell: #{from}
    (See #organizing-open for full context.)
    """

    robot.messageRoom room_open, bot_msg_open
    robot.messageRoom room_priv, bot_msg_priv

    res.send 'ok'
