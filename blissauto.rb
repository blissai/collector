#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require_relative 'lib/bootstrap'

puts "Running scheduled Bliss job..."
BlissRunner.new.automate
