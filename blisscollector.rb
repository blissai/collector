#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require_relative 'lib/bootstrap'

# The main program loop to accept commands for various tasks
def program_loop
  BlissRunner.new.choose_command
  puts 'Goodbye'
end
program_loop
