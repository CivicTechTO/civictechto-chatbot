<img align="right" src="docs/roo-header.png" height="200" />

# Roobot: CivicTechTO Chatbot

:wave::vulcan_salute: A friendly chatbot that lives in _Civic Tech Toronto_'s Slack team. :speech_balloon::robot:

## Technologies Used

- [**Coffeescript.**][coffeescript] A little language with syntactic sugar that compiles into JavaScript.
  - [**Hubot.**][hubot] A chatbot framework for running/creating shared tasks.
- [**Heroku.**][heroku] A platform for easily deploying applications.
- [**Slack.**][slack] A user-friendly chat tool for large teams and communities.

   [hubot]: https://hubot.github.com/
   [coffeescript]: https://coffeescript.org/
   [heroku]: https://www.heroku.com/what
   [slack]: https://slack.com/intl/en-ca/help/articles/115004071768-what-is-slack-

## Commands & Helper Scripts

See [`scripts/`](/scripts) for the set of custom commands/scripts
enabled for our chat bot.

_Note for screenshots: Our chatbot used to be named "toby"._

### `calendar-add.coffee`

This command allows any member of our Slack team to easily add events to
[a shared community Google calendar][2] via:

   [2]: https://link.civictech.ca/calendar

```
>>> @ourbot gcal add https://eventbrite.com/xxxxxxxxxxxxx
```

This depends on another small service for parsing event data from urls:
https://github.com/CivicTechTO/event-metadata-parser

For now, this service only knows how to make sense of events on the
EventBrite and Universe platforms, but it could be improved to cover
other platforms.

### `collab-tweeter.coffee`

This script watches for Twitter links in top-level channels, and offered
to RT from organizational account

![screenshot of chat bot offering to tweet](/docs/collab-tweeter-screenshot.png)


### `quicklink-gsheet-lookup.coffee`

This bot command recognizes messages of the format `!keyword` and looks
up the keyword in a designated spreadsheet (like [this one][3]). It
replies with the URL. Using `!!keyword` will reply with a hidden message
than only the user who typed the message will see.

   [3]: https://link.civictech.ca/shortlinks

This relates to a scheduled task that we run, which updates our
shortlinks from this spreadsheet:
https://github.com/civictechto/civictechto-scripts#gsheet2shortlinkspy

### `sms-doorbell.coffee`

We have an internet number set up to notify us our chat channel whenever
someone texts us. We use this as a doorbell at meetups, so that all
organizers can easily take responsibility for answering and dealing with
issues.

It lives in its own code repository, so please see the
[`civictechto/hubot-sms-doorbell`
README](https://github.com/civictechto/hubot-sms-doorbell#readme) for full details

### `task-runner.coffee`

This bot command is used to manually kickstart scripted jobs or tasks,
which are otherwise usually scheduled to run at certain times. These
scripts are run by CircleCI, and in our case, are defined in the
[`CivicTechTO/civictechto-scripts` repo][5] and [accompanying config
file][6]. The command allows this ability through the use of
[`CivicTechTO/circleci-job-runner`][4], a small app that offers an API
for initiating these runs. There is no authentication on these tasks,
and so it's assumed that all tasks are safe to run at any time.

   [4]: https://github.com/CivicTechTO/circleci-job-runner
   [5]: https://github.com/CivicTechTO/civictechto-scripts
   [6]: https://github.com/CivicTechTO/civictechto-scripts/blob/master/.circleci/config.yml

![screenshot of task-runner chatbot command](https://i.imgur.com/yhO1pjx.png)

## Contributing

This app is hosted on the Heroku platform, and configured using their automatic deployment feature.

This means that pushing or merging changes specifically to the `master` branch will make the changes live within several minutes.

## FAQ

### How do a rename this chatbot?

You'll need to change the name in several places, some of which are
critical :star: and some of which are just to keep things consistent:
- :star: username of [Slack integration](https://civictechto.slack.com/services/B0M281RPA)
- this GitHub repo
  - README title
  - [`bin/hubot`](/bin/hubot) (used to local testing)
  - optional: screenshots

### Can I rename the Heroku app?

Yes, but just note that you'll need to update some configuration for our
SMS doorbell. Specifically, you'll need to re-point our internet
number's _SMS URL Callback_. Details on this configuration/setup linked from
[`CivicTechTO/hubot-sms-doorbell`](https://github.com/CivicTechTO/hubot-sms-doorbell/).
