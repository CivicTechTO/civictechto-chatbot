# Description:
#   Reminds people that toby is no more!

module.exports = (robot) ->

  old_name = 'toby'
  robot.hear ///^@?#{old_name}:? (.+)///i, (res) ->
    res.message.thread_ts = res.message.id
    res.send "Ohai! I'm the new #{old_name} :wave:"
    return
