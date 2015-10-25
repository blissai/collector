Write-Host "Installing Chocolatey Package Manager..."
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$env:path = $env:path += ";C:\ProgramData\chocolatey\bin"

#Allow global confirmation on install
choco feature enable -n=allowGlobalConfirmation
#Install ruby and add to path
Write-Host "Installing Ruby..."
choco install ruby
$env:path = "$($env:Path);C:\tools\ruby21\bin";
Write-Host "Installing Ruby Devkit..."
choco install ruby2.devkit
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+';C:\tools\DevKit2\bin'
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
$env:Path = "$($env:Path);C:\tools\DevKit2\bin"
Write-Host "Installing Perl..."
choco install strawberryperl
Write-Host "Installing nodeJS..."
choco install nodejs
choco install vcredist2012
Write-Host "Installing PHP..."
choco install php
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+';C:\tools\php'
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
$env:Path = "$($env:Path);C:\tools\php"
Write-Host "Installing Python..."
choco install python
Write-Host "Installing Bundler..."
gem install bundler
Write-Host "Installing rake..."
gem install rake
Write-Host "Bundle installing..."
bundle install

Write-Host "Creating shortcut..."
# Create a Shortcut with Windows PowerShell
$TargetFile = "C:\tools\blisscollector\bliss.rb"
$ShortcutFile = "$($env:Public)\Desktop\Bliss.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
