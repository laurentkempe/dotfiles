# Fix git log output encoding issues on Windows 10 command prompt https://stackoverflow.com/questions/41139067/git-log-output-encoding-issues-on-windows-10-command-prompt/41416262#41416262
$env:LC_ALL = 'C.UTF-8'

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
Import-Module oh-my-posh
Set-Theme Paradox
# Fix with ConEmu Fonts / Main console=JetBrains Mono and Alternative font=Cascadia Mono with Unicode range=Pseudographics: 2013-25C4;
$ThemeSettings.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0x25B6)
$ThemeSettings.GitSymbols.BranchIdenticalStatusToSymbol = [char]::ConvertFromUtf32(0x2261)
$ThemeSettings.GitSymbols.BranchUntrackedSymbol = [char]::ConvertFromUtf32(0x2504)

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

#Add MSBuild to user path
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\" 
