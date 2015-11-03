#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require_relative 'lib/bootstrap'
include CliTasks

@args = ARGV

if auto?
  puts "Running scheduled Bliss job..."
  BlissRunner.new.automate
elsif scheduler?
    `@powershell schtasks /Create /SC HOURLY /MO 3 /TR "Powershell.exe -ExecutionPolicy ByPass -Command 'jruby #{pwd}'"`
    puts "Task Scheduled to run every hour."
elsif loop?
  # The main program loop to accept commands for various tasks
  def program_loop
    BlissRunner.new.choose_command
    puts 'Goodbye'
  end
  program_loop
else
  puts "Usage:"
  puts "collector [auto] / [schedule]"
  puts "collector auto\t\t Run Collector, Stats and Linter all in one"
  puts "collector schedule\t Schedule the task to run every 3 hours (Windows only. Unix users use wheneverize)"
end
