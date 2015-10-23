#!/usr/bin/env ruby
puts 'Installing Bliss Collector... please wait'
`git clone https://github.com/founderbliss/collector.git C:/tools/blisscollector`
puts 'Installing dependencies... please wait'
`@powershell Set-ExecutionPolicy RemoteSigned; powershell.exe C:/tools/blisscollector/installscripts/setup.ps1`
puts `gem install bundler` unless Gem::Specification::find_all_by_name('bundler').any?
puts `gem install rake` unless Gem::Specification::find_all_by_name('rake').any?
puts `bundle install`
puts "Adding shortcut to desktop."
`@powershell powershell.exe C:/tools/blisscollector/installscripts/shortcut.ps1`
puts 'Installation complete.'
