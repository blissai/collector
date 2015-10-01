#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require 'bootstrap'

# a custom command handler for base command
class MyCommandHandler < Cliqr.command
  def execute(context)
    command = context.option('command').value
    if command == 'collector'
      Collector.new.execute(context)
    elsif command == 'stats'
      puts 'run collector'
    elsif command == 'linter'
      puts 'run collector'
    end
  end
end

cli = Cliqr.interface do
  name 'collector'
  description 'Repo collector command line for Bliss.'
  version '0.0.1' # optional; adds a version action to our simple command

  # main command handler
  handler MyCommandHandler

  option :command do
    description 'Command to run (collector, stats or linter)'
    default 'collector'
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
