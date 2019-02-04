# Description:
#   Replies with quicklinks when !keyword is used.
#
# Dependencies:
#   get-sheet-done
#   node-fetch
#
# Configuration:
#   HUBOT_QUICKLINK_GSHEET_KEY
#   HUBOT_QUICKLINK_WORKSHEET_INDEX (optional)
#
# Commands:
#   !<keyword> - Lookup quicklink & share via PUBLIC reply in conversation.
#   !!<keyword> - Lookup quicklink & respond via PRIVATE direct message.
#
# Notes:
#
#   - Aside from being publicly-readable, your Google Sheet must be set to be "Published to the web".
#     See: https://support.google.com/docs/answer/183965?co=GENIE.Platform%3DDesktop&hl=en
#
# Author:
#   patcon

global.fetch = require 'node-fetch'
GetSheetDone = require 'get-sheet-done'

config =
  # TODO: Allow gsheet key to be set from URL.
  gsheet_key: process.env.HUBOT_QUICKLINK_GSHEET_KEY || '1LCVxEXuv70R-NozOwhNxZFtTZUmn1FLMPVD5wgIor9o'
  # TODO: Allow worksheet to be either an int index or string to match against.
  worksheet_index: process.env.HUBOT_QUICKLINK_WORKSHEET_INDEX || 1

getQuicklink = (key, cb) ->
  # TODO: Cache and only refetch when updated.
  GetSheetDone.labeledCols(config.gsheet_key, config.worksheet_index).then (sheet) ->
    data = sheet.data
    # Filter out keys without urls.
    data = (r for r in data when r.destinationurl)
    for r, _ in data
      if r.slashtag == key
        cb(r.destinationurl)
        return

    # No match found.
    cb(null)

module.exports = (robot) ->
  robot.hear /^!(!)?([a-zA-Z0-9-_]+)/i, (res) ->
    # Private if !! prefix.
    is_private = res.match[1]
    key = res.match[2]
    getQuicklink key, (url) ->
      if not url
        res.send "No quicklink found for that key."
        return

      if is_private
        # Respond privately via DM.
        robot.messageRoom res.message.user.name, url
      else
        res.send url
