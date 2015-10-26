#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require 'bootstrap'

puts "Running scheduled Bliss job..."
BlissRunner.new.automate
