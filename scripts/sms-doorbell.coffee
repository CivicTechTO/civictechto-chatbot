module.exports = (robot) ->
  robot.router.get '/doorbell', (req, res) ->
    message = req.query.message
    phone_re = /(\d+?)(\d{3})(\d{4})$/
    from = req.query.from.match(phone_re)[1..3].join('-')
    # Find this here: https://api.slack.com/methods/groups.list/test
    room='G08V58H6Y' #organize-the-things

    robot.messageRoom room, "@channel there's someone at the door!"
    robot.messageRoom room, "#{from} says \"#{message}\""

    res.send 'ok'
