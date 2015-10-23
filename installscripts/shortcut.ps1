# Create a Shortcut with Windows PowerShell
$TargetFile = "C:\tools\blisscollector\blisscollector.rb"
$ShortcutFile = "$env:Public\Desktop\Collector.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
