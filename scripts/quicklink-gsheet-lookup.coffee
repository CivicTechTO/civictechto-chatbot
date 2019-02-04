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
#   !!<keyword> - Lookup quicklink & respond via PRIVATE hidden message.
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
{WebClient} = require "@slack/client"

config =
  # TODO: Allow gsheet key to be set from URL.
  gsheet_key: process.env.HUBOT_QUICKLINK_GSHEET_KEY || '1LCVxEXuv70R-NozOwhNxZFtTZUmn1FLMPVD5wgIor9o'
  # TODO: Allow worksheet to be either an int index or string to match against.
  worksheet_index: process.env.HUBOT_QUICKLINK_WORKSHEET_INDEX || 1

getQuicklink = (key, cb) ->
  # TODO: Cache and only refetch when updated.
  # TODO: Allow setting the gsheet columns for key/value lookup.
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
  web = new WebClient robot.adapter.options.token
  robot.hear /^!(!)?([a-zA-Z0-9-_]+)/i, (res) ->
    # Private if !! prefix.
    is_private = res.match[1]
    key = res.match[2]
    getQuicklink key, (url) ->
      # Thread reply on Slack
      if robot.adapterName == 'slack'
        if not !!res.message.thread_ts
          res.message.thread_ts = res.message.rawMessage.ts

      if not url
        res.send "No quicklink found for that key."
        return

      if is_private
        # Respond privately via epheral message.
        # TODO: Figure out why ephemeral msgs come through DM and channel.
        robot.messageRoom res.message.user.id, url
        payload =
          channel: res.message.room
          text: url
          user: res.message.user.id
          as_user: true

        # TODO: Figure out why ephemeral messages don't come through when threaded
        web.chat.postEphemeral payload
        return

      res.send url
      # TODO: Resolve redirects and parse from url, which will allow shortlink to be used.
      # TODO: Consider using a link button: https://api.slack.com/docs/message-attachments#link_buttons
      res.send "Want to add/change quicklink keywords? See <https://docs.google.com/spreadsheets/d/#{config.gsheet_key}|this spreadsheet>!"
