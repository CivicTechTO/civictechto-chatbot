module.exports = (robot) ->
  robot.router.get '/doorbell', (req, res) ->
    message = req.query.message
    from = req.query.from
    # Find this here: https://api.slack.com/methods/groups.list/test
    room='G08V58H6Y' #organize-the-things

    robot.messageRoom room, "@channel there's someone at the door!"
    robot.messageRoom room, "#{from} says \"#{message}\""
