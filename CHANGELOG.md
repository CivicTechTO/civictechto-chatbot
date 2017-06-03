# Toby Chatbot Changelog

All future user-facing changes to toby, the chatbot that lives in the
CivicTech Toronto slack team, will be listed here.

- **`reddit-linker`**: Added script.
  - When the bot sees a link, it searches reddit for previous.
    submissions, and links the top two most upvoted threads.
- **`reddit-linker`**: Changed sort type.
  - Now sorts by most commented instead of most upvoted.
- **`reddit-linker`**: Added thread support.
  - Toby now replies in thread if the link was posted there, instead of
    in main channel.
- **`reddit-linker`**: Links only top reddit thread.
  - Previously linked top 2, which was seen as too noisy.
- **`reddit-linker`**: Ignores threads with under 10 comments.
  - Exempts r/toronto, which gets priority for being local even if under that.
- **`changelog`**: Added script.
  - To show how hubot is changing.
