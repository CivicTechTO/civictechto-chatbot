# Description:
#   Watch for links and search for top-commented reddit post about them,
#   favouring toronto subreddits.
#
#   Any link from toronto subreddits are posted, but links from other
#   subreddits must have 10 comments.
#
# Configuration:
#   HUBOT_REDDIT_USERNAME
#   HUBOT_REDDIT_PASSWORD
#   HUBOT_REDDIT_APP_ID
#   HUBOT_REDDIT_APP_SECRET
#
# Author:
#   patcon@github

getUrls = require 'get-urls'
snoowrap = require 'snoowrap'
_ = require 'underscore'

config =
  username: process.env.HUBOT_REDDIT_USERNAME
  password: process.env.HUBOT_REDDIT_PASSWORD
  app_id: process.env.HUBOT_REDDIT_APP_ID
  app_secret: process.env.HUBOT_REDDIT_APP_SECRET

URL_REGEXP = /((https?|ftp):\/\/|www\.)[^\s\/$.?#].[^\s]*/i

module.exports = (robot) ->
  # Abort if not configured
  if not config.app_secret
    return

  robot.listen(
    (message) ->
      if typeof(message.text) == 'string'
        getUrls(message.text).size > 0
    (res) ->

      client = new snoowrap(
        userAgent: 'github.com/civictechto/hubot-toby',
        clientId: config.app_id,
        clientSecret: config.app_secret,
        username: config.username,
        password: config.password,
      )

      sortByCommentsWithMin = (links, min_comments) ->
        links = _.filter(links, (link) -> link.num_comments >= min_comments )
        links = _.sortBy(links, (link) -> link.num_comments ).reverse()
        return links

      sayResults = (links) ->
        toronto_links = _.filter(links, (link) -> /toronto/i.test link.subreddit.display_name)
        if toronto_links.length > 0
          links = toronto_links
          # if it's in a toronto subreddit, doesn't need comments
          min_comments = 0
        else
          # minimum that non-toronto subreddits require
          min_comments = 10

        links = sortByCommentsWithMin(links, min_comments)

        if links.length > 0
          # how many links we want to drop in chat
          num_links_in_reply = 1
          urls = ("https://www.reddit.com#{link.permalink}" for link in links.slice(0, num_links_in_reply))

          reply = ["Yay! I found a Reddit conversation about the link shared above."].concat urls
          # Start thread if in channel
          if not res.message.thread_ts?
            # in channel
            res.send {thread_ts: res.message.id, text: reply.join("\n")}
          else
            # in a thread already
            res.send reply.join("\n")


      # Reddit matching is very specific, so don't want to mangle too much.
      # See: https://github.com/sindresorhus/normalize-url
      urlNormalizationOpts =
        normalizeProtocol: false,
        removeTrailingSlash: false,
        stripWWW: false,

      for url in Array.from(getUrls(res.message.text, urlNormalizationOpts))
        robot.logger.info "Detected link to check reddit for: #{url}"
        client._get({uri: 'api/info', qs:{url: url}})
          .then(sayResults)
          .catch(console.error)
  )

