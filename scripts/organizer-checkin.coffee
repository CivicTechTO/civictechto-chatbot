# Description:
#   Allow someone to initiate an organizer checkin in a channel.
#
# Configuration:
#   HUBOT_ORGANIZER_CHECKIN_URL
#
# Commands:
#   hubot run organizer checkin - perform a checkin
#
# Author:
#   patcon

axios = require 'axios'

config =
  checkin_url: process.env.HUBOT_ORGANIZER_CHECKIN_URL

module.exports = (robot) ->

  web = robot.adapter.client.web

  robot.on 'interactivity-loaded', ->
    robot.setActionHandler /organizer_checkin_.+/, (payload, respond) ->
      url = "#{config.checkin_url}?slack_id=#{payload.user.id}&slack_username=#{payload.user.name}&status=#{payload.actions[0].value}"
      axios.get(url)
        .then (response) ->
          # See: https://stackoverflow.com/a/51218544/504018
          # respond {delete_original: true}
          # TODO: Link to gsheet and website.
          respond {text: "Thanks! We've updated the check-in data and website!"}
          return
        .catch (error) ->
          console.log(error)
          return

  robot.respond /run organizer checkin/i, (msg) ->
    # TODO: Restrict to specific channel for now?
    public_msg = {
      text: ":ctto: Time for the monthly update of the <http://civictech.ca/about-us/organizers/|organizer list on the website>! :tada:",
      unfurl_links: false,
    }
    msg.send public_msg

    action_attachment = {
        title: "What do you feel best describes your organizing team status?",
        footer: "If not active, you'll simply be moved from active to <http://civictech.ca/about-us/organizers/#past|past organizer list on the website>.\nRe-activate yourself anytime by leaving and re-joining this channel :)"
        fallback: "Slack is unable to present you with an interactive message asking about your organizing team status.",
        callback_id: "organizer_checkin_123",
        color: "#cccccc",
        attachment_type: "default",
        actions: [
            {
                text: "Active",
                style: "primary",
                name: "active",
                type: "button",
                value: "active"
            }
            {
                text: "Alum",
                name: "alum",
                type: "button",
                value: "alum"
            }
        ]
    }

    web.conversations.members(msg.message.room)
      .then (res) ->
        members = res.members
        for mid in members
          web.chat.postEphemeral msg.message.room, '', mid, {attachments: [action_attachment]}
          break # TODO: Remove this once ready to ask everyone in-channel.
