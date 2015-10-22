choco feature enable -n=allowGlobalConfirmation
choco install ruby
choco install rubygems
choco install nodejs
choco install vcredist2012
choco install php
choco install python
$phpPath = "C:\tools\php"
$env:Path = "$($env:Path);$phpPath"
choco install strawberryperl
