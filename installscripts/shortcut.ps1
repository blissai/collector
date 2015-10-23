# Create a Shortcut with Windows PowerShell
$TargetFile = "C:\tools\blisscollector\bliss.rb"
$ShortcutFile = "$env:Public\Desktop\Bliss.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
