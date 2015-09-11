#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'aws-sdk'
require 'pry'
require 'cliqr'

def get_cmd(cmd)
  if Gem.win_platform?
    @tmpbatchfile = Tempfile.new(['batch', '.ps1'])
    @tmpbatchfile.write(cmd.gsub(';', "\r\n"))
    @tmpbatchfile.close
    "powershell #{@tmpbatchfile.path}"
  else
    "(#{cmd})"
  end
end

def collect(top_dir_name, organization, git_base, api_key, host)
  #  root_url = 'https://app.founderbliss.com'
  host = 'http://local.encore.io:3000' unless host?

  agent = Mechanize.new
  auth_headers = { 'X-User-Token' => api_key }

  dir_names = []
  top_dir_with_star = File.join(top_dir_name.to_s, '*')
  dir_list = Dir.glob(top_dir_with_star).select { |f| File.directory? f }
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
    repo_key = json_return['repo_key']

    s3 = Aws::S3::Resource.new(region: 'us-east-1')
    bucket = s3.bucket('founderbliss-temp-storage')
    obj = bucket.object("#{organization}_#{name}_git.log")

    # string data
    obj.put(body: @lines)
    log_url = obj.presigned_url(:get, expires_in: 86_400)

    repo_return = agent.post(
      "#{root_url}/api/gitlog",
      { repo_key: repo_key, git_log_url: log_url },
      auth_headers)
    dir_names << repo_return.body
  end

  puts dir_names.join
end

cli = Cliqr.interface do
  name 'collector'
  description 'Repo collector command line for Bliss.'
  version '0.0.1' # optional; adds a version action to our simple command

  # main command handler
  handler do
    aws_credentials = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'] || aws_key.to_s,
      ENV['AWS_SECRET_ACCESS_KEY'] || aws_secret.to_s)
    Aws.config.update(region: 'us-east-1', credentials: aws_credentials)

    collect(dir_name, organization, git_base, api_key, host) if dir_name?
    puts 'Please tell me directory name with the repositories' unless dir_name?
  end

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
  end

  option :aws_secret do
    description 'Your AWS secret (or taken from ENV[\'AWS_SECRET_ACCESS_KEY\'])'
  end

  option :host do
    description 'The host for your bliss instance (e.g. http://localhost)'
  end
end

cli.execute(ARGV)
