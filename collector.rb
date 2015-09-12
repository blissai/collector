#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require 'bootstrap'

# Stats class for collecting git LOC and other stats
class Collector < Cliqr.command
  include Common
  include Gitbase

  def execute(context)
    top_dir_name = context.option('dir_name').value
    organization = context.option('organization').value
    git_base = context.option('git_base').value
    api_key = context.option('api_key').value
    host = context.option('host').value
    aws_credentials = Aws::Credentials.new(
      context.option('aws_key').value,
      context.option('aws_secret').value)
    Aws.config.update(region: 'us-east-1', credentials: aws_credentials)

    agent = Mechanize.new
    auth_headers = { 'X-User-Token' => api_key }

    repos = {}

    dir_list = get_directory_list(top_dir_name)
    dir_list.each do |dir_name|
      name = dir_name.split('/').last
      params = {
        name: name,
        full_name: "#{organization}/#{name}",
        git_url: File.join(git_base.to_s, name)
      }

      log_fmt = '%H|%P|%ai|%aN|%aE|%s'
      cmd = get_cmd("cd #{dir_name};git log --all --pretty=format:'#{log_fmt}'")
      @lines = `#{cmd}`

      repo_return = agent.post("#{host}/api/repo.json", params, auth_headers)
      json_return = JSON.parse(repo_return.body)
      repos[name] = json_return
      repo_key = json_return['repo_key']

      s3 = Aws::S3::Resource.new(region: 'us-east-1')
      bucket = s3.bucket('founderbliss-temp-storage')
      obj = bucket.object("#{organization}_#{name}_git.log")

      # string data
      obj.put(body: @lines)
      log_url = obj.presigned_url(:get, expires_in: 86_400)

      agent.post(
        "#{host}/api/gitlog",
        { repo_key: repo_key, git_log_url: log_url },
        auth_headers)
    end

    save_bliss_file(top_dir_name, repos)
  end
end

cli = Cliqr.interface do
  name 'collector'
  description 'Repo collector command line for Bliss.'
  version '0.0.1' # optional; adds a version action to our simple command

  # main command handler
  handler Collector

  option :api_key do
    description 'Your user API key from bliss (under settings)'
  end

  option :git_base do
    description 'Base URL for git.'
  end

  option :organization do
    description 'Your organization name.'
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
