#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'cliqr'

def collect(top_dir_name, organization, git_base, api_key)
  #  root_url = 'https://app.founderbliss.com'
  root_url = 'http://local.encore.io:3000'
  
  agent = Mechanize.new
  headers = { 'X-User-Token' => api_key }

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
    repo_return = agent.post("#{root_url}/api/repo.json", params, headers)
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
    collect(dir_name, organization, git_base, api_key) if dir_name?
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
end

cli.execute(ARGV)
