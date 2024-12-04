$global:innoveo = @{
    InnoveoBasePath  = ''
    SolutionBasePath = ''
    RepoBaseUrl      = ''
    BoardBaseUrl     = ''
    CIBaseUrl        = ''
    TeamId           = ''
    ReviewChannelId  = ''
    JiraAPIToken     = ''
    QADefinitionRepo = ''
}

[console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Environment]::SetEnvironmentVariable("MSBUILDTERMINALLOGGER", "auto", "User")

Import-Module 'Utils'
Import-Module 'DockerCompletion'
Import-Module 'Personal'
Import-Module 'Innoveo'
Import-Module 'dapr'
Import-Module 'PSKubectlCompletion'
Import-Module z
Set-Alias -Name q -value z

Import-Module -Name Terminal-Icons
Import-Module posh-git
#$GitPromptSettings.EnablePromptStatus = $false
Import-Module oh-my-posh
Set-PoshPrompt -Theme ~/laurentkempe.omp.json

Set-PSReadlineOption -HistorySavePath "~\OneDrive\Documents\PowerShell\History\ConsoleHost_history.txt"
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

Set-PSReadLineKeyHandler -Key Ctrl+Shift+b `
                         -BriefDescription BuildCurrentDirectory `
                         -LongDescription "dotnet Build the current directory" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+o `
                         -BriefDescription OpenInRider `
                         -LongDescription "Open sln or csproj in Rider" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rider")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+j `
                         -BriefDescription OpenJiraTicketInBrowser `
                         -LongDescription "Open Jira ticket description" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("git j")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+t `
                         -BriefDescription OpenBCTeamCityBranchInBrowser `
                         -LongDescription "Open BC TeamCity build on the branch" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("bcCIBranch")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+p `
                         -BriefDescription OpenGitHubPRInBrowser `
                         -LongDescription "Open GitHub pull request on the web" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("gh pr view --web")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Ctrl+b `
                         -BriefDescription StartToBlog `
                         -LongDescription "Start environment to blog" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("wt --startingDirectory ""$env:userprofile\\projects\\blog"" ``; split-pane -p ""Powershell"" --startingDirectory ""$env:userprofile\\projects\\blog"" BlogOps.exe edit ``; split-pane --horizontal -p ""Powershell"" --startingDirectory ""$env:userprofile\\projects\\blog"" BlogOps.exe server --draft ``; move-focus up; code ""$env:userprofile\\projects\\blog""")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineOption -PredictionSource History

# Related: https://github.com/PowerShell/PSReadLine/issues/1778
Set-PSReadLineKeyHandler -Key Shift+Delete `
    -BriefDescription RemoveFromHistory `
    -LongDescription "Removes the content of the current line from history" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $toRemove = [Regex]::Escape(($line -replace "\n", "```n"))
    $history = Get-Content (Get-PSReadLineOption).HistorySavePath -Raw
    $history = $history -replace "(?m)^$toRemove\r\n", ""
	Set-Content (Get-PSReadLineOption).HistorySavePath $history -NoNewline
}

# Nuke build
Register-ArgumentCompleter -Native -CommandName nuke -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        nuke :complete "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

#Add MSBuild to user path
$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\" 
