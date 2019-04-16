# Description:
#   Allow users to run safe tasks/scripts on CircleCI.
#
#   It depends on a tiny app called `circleci-job-runner` in order to work.
#   See: https://github.com/CivicTechTO/circleci-job-runner
#
# Configuration:
#   HUBOT_CIRCLECI_RUNNER_BASE_URL
#
# Commands:
#   hubot tasks - list the tasks/scripts that can be run
#   hubot tasks run <task-name> - run a specific task/script
#
# Author:
#   patcon

config =
  base_url: process.env.HUBOT_CIRCLECI_RUNNER_BASE_URL or 'https://circleci-job-runner.herokuapp.com'

module.exports = (robot) ->
  robot.respond /tasks( list)?$/i, (msg) ->
    jobs_url = "#{config.base_url}/jobs"
    robot.http(jobs_url)
      .get() (err, res, body) ->
        if err
          msg.send "Encountered an error :( #{err}"
          return

        jobs = JSON.parse body
        jobs = ("`#{j}`" for j in jobs)
        jobs = jobs.join(', ')
        msg.send "Here are the runnable tasks: #{jobs}"

  robot.respond /tasks run ([a-zA-Z_-]+)/i, (msg) ->
    task_name = msg.match[1]
    job_start_url = "#{config.base_url}/jobs/#{task_name}"
    robot.http(job_start_url)
      .post() (err, res, body) ->
        if err
          msg.send "Encountered an error :( #{err}"
          return

        data = JSON.parse body
        build_url = data.build_url
        msg.send
          unfurl_links: false
          unfurl_media: false
          text: """Manually started automated task/script! <#{build_url}|Monitor progress logs :scroll:>"""
