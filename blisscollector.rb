#!/usr/bin/env ruby
puts 'Initializing...'
$LOAD_PATH << 'lib'
require_relative 'lib/bootstrap'
include CliTasks
@args = ARGV

if auto?
  puts 'Running scheduled Bliss job...'
  BlissRunner.new(true).automate
elsif beta?
  puts 'Running scheduled Bliss job in beta...'
  BlissRunner.new(false, true)
elsif scheduler?
  cwd = `$pwd.Path`.gsub(/\n/, '')
  puts `@powershell schtasks /Create /SC HOURLY /MO 3 /TN BlissCollector /TR "Powershell.exe -ExecutionPolicy ByPass -Command 'jruby #{cwd}/blisscollector.rb auto'"`
  puts 'Task Scheduled to run every 3 hours.'.green
elsif loop?
  # The main program loop to accept commands for various tasks
  def program_loop
    BlissRunner.new.choose_command
    puts 'Goodbye'
  end
  program_loop
else
  puts 'Usage:'
  puts 'collector [auto] / [schedule]'
  puts "collector auto\t\t Run Collector, Stats and Linter all in one"
  puts "collector schedule\t Schedule the task to run every 3 hours (Windows only. Unix users use wheneverize)"
end
