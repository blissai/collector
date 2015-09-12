#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require 'bootstrap'

# Stats class for collecting git LOC and other stats
class Stats < Cliqr.command
  include Common
  include Gitbase

  def execute(context)
    top_dir_name = context.option('dir_name').value
    api_key = context.option('api_key').value
    host = context.option('host').value
    aws_credentials = Aws::Credentials.new(
      context.option('aws_key').value,
      context.option('aws_secret').value)
    Aws.config.update(region: 'us-east-1', credentials: aws_credentials)

    agent = Mechanize.new
    auth_headers = { 'X-User-Token' => api_key }

    repos = read_bliss_file(top_dir_name)
    dir_names = []

    dir_list = get_directory_list(top_dir_name)
    dir_list.each do |git_dir|
      name = git_dir.split('/').last
      repo = repos[name]
      repo_key = repo['repo_key']

      repo_return = agent.get(
        "#{host}/api/gitlog/stats_todo?repo_key=#{repo_key}",
        auth_headers)
      json_return = JSON.parse(repo_return.body)

      puts "Working on repo: #{git_dir}"
      json_return.each do |metric|
        commit = metric['commit']
        puts "\tget stats for #{commit}"

        stat_command = "git log --pretty=tformat: --numstat #{commit}"
        cmd = get_cmd("cd #{git_dir}; #{stat_command}")
        added_lines = 0
        deleted_lines = 0
        @stats = `#{cmd}`
        @stats.split("\n").each do |stt|
          match = stt.match(/(\d+)\t(\d+)/)
          if match
            added_lines += match[1].to_i
            deleted_lines += match[2].to_i
          end
        end
        checkout_commit(git_dir, commit)
        total_cloc = `perl #{cloc_command} #{git_dir} #{cloc_options}`
        remove_open_source_files(git_dir)
        cloc = `perl #{cloc_command} #{git_dir} #{cloc_options}`

        stat_payload = {
          repo_key: repo_key,
          commit: commit,
          added_lines: added_lines,
          deleted_lines: deleted_lines,
          total_cloc: total_cloc,
          cloc: cloc
        }

        stats_response = agent.post(
          "#{host}/api/commit/stats",
          stat_payload,
          auth_headers)
        stats_return = JSON.parse(stats_response.body)
        puts "\t\tstats_response: #{stats_response.inspect}"
      end

      # Go back to master at the end
      checkout_commit(git_dir, 'master')
    end

    puts dir_names.join
  end
end

cli = Cliqr.interface do
  name 'stats'
  description 'Repo stats for Bliss.'
  version '0.0.1' # optional; adds a version action to our simple command

  # main command handler
  handler Stats

  option :api_key do
    description 'Your user API key from bliss (under settings)'
  end

  option :dir_name do
    description 'Your directory name.'
  end

  option :aws_key do
    description 'Your AWS S3 key (or taken from ENV[\'AWS_ACCESS_KEY_ID\'])'
    default ENV['AWS_ACCESS_KEY_ID']
  end

  option :aws_secret do
    description 'Your AWS secret (or taken from ENV[\'AWS_SECRET_ACCESS_KEY\'])'
    default ENV['AWS_SECRET_ACCESS_KEY']
  end

  option :host do
    description 'The host for your bliss instance (e.g. http://localhost)'
    default 'http://local.encore.io:3000'
  end
end

cli.execute(ARGV)
