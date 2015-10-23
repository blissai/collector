puts 'Installing Bliss Collector... please wait'
puts 'Installing dependencies...'
`gem install bundler`
`bundle install`
`@powershell Set-ExecutionPolicy RemoteSigned; powershell.exe installscripts/setup.ps1`
`git clone https://github.com/founderbliss/collector.git C:/tools/blisscollector`
puts 'Installation complete.'
