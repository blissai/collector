if Gem.win_platform?
  `@powershell Set-ExecutionPolicy RemoteSigned; powershell.exe installscripts/setup.ps1`
else

end
