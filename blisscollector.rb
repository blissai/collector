#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require_relative 'lib/bootstrap'

if ARGV.size == 1 && ARGV[0] == "--auto"
  puts "Running scheduled Bliss job..."
  BlissRunner.new.automate
elsif ARGV.size == 0
  # The main program loop to accept commands for various tasks
  def program_loop
    BlissRunner.new.choose_command
    puts 'Goodbye'
  end
  program_loop
else
  puts "Usage:"
  puts "collector [--auto]"
  puts "--auto\t\t Run Collector, Stats and Linter all in one."
end
