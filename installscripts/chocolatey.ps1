iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$env:path = $env:path += ";C:\ProgramData\chocolatey\bin"
