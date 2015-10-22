if Gem.win_platform?
  `Set-ExecutionPolicy RemoteSigned; powershell.exe installscripts/setup.ps1`
else
  
end
