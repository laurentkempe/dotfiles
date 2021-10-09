$global:innoveo = @{
    SolutionBasePath = ''
    RepoBaseUrl      = ''
    BoardBaseUrl     = ''
    CIBaseUrl        = ''
}

Import-Module 'Utils'
Import-Module 'DockerCompletion'
Import-Module 'Personal'
Import-Module 'Innoveo'
Import-Module 'dapr'
Import-Module 'PSKubectlCompletion'

Import-Module -Name Terminal-Icons
Import-Module posh-git
#$GitPromptSettings.EnablePromptStatus = $false
Import-Module oh-my-posh
Set-PoshPrompt -Theme laurentkempe

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
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("wt --startingDirectory ""$env:userprofile\\projects\\blog"" ``; split-pane -p ""Powershell"" --startingDirectory ""$env:userprofile\\projects\\blog"" BlogOps.exe edit ``; split-pane --horizontal -p ""Powershell"" --startingDirectory ""$env:userprofile\\projects\\blog"" BlogOps.exe server --draft ``; move-focus up")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineOption -PredictionSource History

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
