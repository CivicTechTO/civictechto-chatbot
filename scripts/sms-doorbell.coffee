module.exports = (robot) ->
  robot.router.get '/doorbell', (req, res) ->
    sms_msg = req.query.message
    phone_re = /(\d+?)(\d{3})(\d{4})$/
    from = req.query.from.match(phone_re)[1..3].join('-')
    # Find this here: https://api.slack.com/methods/groups.list/test
    # Can use chan ID or the human-readable channel name.
    room='G08V58H6Y' #organize-the-things

    bot_msg = """
    @here there's someone at the door!
    Someone from #{from} texted our doorbell, 780-652-2649 (780-6LAB-6IX):
    > #{sms_msg}

    (Please use a reaction emoji if you're heading to help)
    """

    robot.messageRoom room, bot_msg

    res.send 'ok'
