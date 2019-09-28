# Description:
#   Reminds people that toby is no more!

module.exports = (robot) ->

  robot.hear /^@?toby:? (.+)/i, (res) ->
    res.reply "Ohai! I'm the new toby :wave:"
    return
