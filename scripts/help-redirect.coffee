# Description:
#   Makes help url more accessible, including redirect from root url.
#
# Dependencies:
#   hubot-help

module.exports = (robot) ->

  robot.router.get '/(help)?', (req, res) ->
    res.redirect "/#{robot.name}/help"
