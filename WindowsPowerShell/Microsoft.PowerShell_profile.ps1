# Fix git log output encoding issues on Windows 10 command prompt https://stackoverflow.com/questions/41139067/git-log-output-encoding-issues-on-windows-10-command-prompt/41416262#41416262
$env:LC_ALL = 'C.UTF-8'

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
Import-Module oh-my-posh
Set-Theme Paradox

Import-Module 'Utils'
Import-Module 'Personal'

$global:innoveo = @{
    SolutionBasePath = ''
    RepoBaseUrl      = ''
    BoardBaseUrl     = ''
    CIBaseUrl        = ''
}
Import-Module 'Innoveo'

# posh-git provided prompt span two lines
$GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1))  '

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
