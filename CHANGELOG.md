# Toby Chatbot Changelog

All future user-facing changes to toby, the chatbot that lives in the
CivicTech Toronto slack team, will be listed here.

1. **`reddit-linker`**: Added script.
    - When the bot sees a link, it searches reddit for previous.
      submissions, and links the top two most upvoted threads.
1. **`reddit-linker`**: Changed sort type.
    - Now sorts by most commented instead of most upvoted.
1. **`reddit-linker`**: Added thread support.
    - Toby now replies in thread if the link was posted there, instead of
      in main channel.
1. **`reddit-linker`**: Links only top reddit thread.
    - Previously linked top 2, which was seen as too noisy.
1. **`reddit-linker`**: Ignores threads with under 10 comments.
    - Exempts r/toronto, which gets priority for being local even if under that.
1. **`changelog`**: Added script.
    - To show how hubot is changing.
1. **`reddit-linker`**: Force replies into threads.
    - toby will no longer reply in channel.
1. **`calendar-add`**: Added script.
    - Any community member can now add EventBrite events to the
      community calendar.
    - Also seeds the post with a :+1: and :question: reaction emoji, so
      people can express support or concern (in case the event doesn't
      seem to be a fit for the calendar)
