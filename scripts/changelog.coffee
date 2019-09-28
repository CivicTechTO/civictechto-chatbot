# Description:
#   Show the hubot changelog on GitHub.
#
# Dependencies:
#   None.
#
# Configuration:
#   None.
#
# Commands:
#   hubot changelog - Link to recent changes to this hubot
#
# Author:
#   patcon

module.exports = (robot) ->
  robot.respond /changelog/i, (msg) ->
    msg.send """Here's a list of recent changes to my programming:
https://github.com/CivicTechTO/civictechto-chatbot/blob/master/CHANGELOG.md#readme"""
