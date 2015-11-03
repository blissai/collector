Set-ExecutionPolicy RemoteSigned
Write-Host "Installing Chocolatey Package Manager...";
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'));
$env:path = $env:path += ";C:\ProgramData\chocolatey\bin";

#Install Java/JRuby
choco install javaruntime
choco install jruby
#Allow global confirmation on install
choco feature enable -n=allowGlobalConfirmation;
Write-Host "Installing Perl...";
choco install strawberryperl;
Write-Host "Installing nodeJS...";
choco install nodejs;
choco install vcredist2012;
Write-Host "Installing Python...";
choco install python;
