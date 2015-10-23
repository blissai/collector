#Allow global confirmation on install
choco feature enable -n=allowGlobalConfirmation
#Install ruby and add to path
choco install ruby
$env:path = "$($env:Path);C:\tools\ruby21\bin";
choco install ruby2.devkit
$env:path = "$($env:Path);C:\tools\DevKit2\bin"
choco install strawberryperl
choco install nodejs
choco install vcredist2012
choco install php
$env:Path = "$($env:Path);C:\tools\php"
choco install python
bundle install
