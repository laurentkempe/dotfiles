# Innoveo Skye Business Canvas

# Development

${function:i} = { Set-Location $global:innoveo.InnoveoBasePath }
${function:com} = { & "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --profile-directory="Profile 1" --launch-workspace="75cf39d6-4326-48df-ae5c-ec9388cc0074" }
${function:bc} = { Set-Location ($global:innoveo.InnoveoBasePath + "\business-canvas") }
${function:bc2} = { Set-Location ($global:innoveo.InnoveoBasePath + "\business-canvas-2") }
${function:bcvs} = { bc; vs ([IO.Path]::Combine($global:innoveo.SolutionBasePath, 'Skye.BusinessCanvas.sln') | Resolve-Path) }
${function:bcDev} = { bcvs; bcb; }
${function:bcClean} = { bc; Remove-Item -Recurse packages; Remove-Item -Recurse Output }
${function:bcReview} = { Param([string] $jiran) i; cd business-canvas-wt; if ($jiran) { git cfb $jiran } }
${function:cpr} = { git cpr } 
${function:pr} = { 
    # Try to view existing PR, if not found, create a new one
    $output = gh pr view --web 2>&1
    if ($output -like "no pull requests found*") {
        Write-Host "No PR found, creating a new one..."
        cpr
    }
}
${function:bcCleanupCode} = { 
    <#

	.SYNOPSIS
	This is a Powershell script to run ReSharper Command Line Tool cleanupcode.exe.

	.DESCRIPTION
	This Powershell script will run ReSharper Command Line Tool cleanupcode.exe to clean your files prior a Git commit.

	#>

    $files = git diff --cached --name-only --diff-filter=ACMR

    $include = $files -join ';' -replace '/', '\'

    $command = """cleanupcode.exe"" -d --include=$include --exclude=$exclude --profile=""Skye"" "".\Skye.BusinessCanvas.sln"""

    Write-Host "Executing: " $command

    & "cleanupcode.exe" --caches-home="C:\Temp\CleanupCodeCache" --include=$include --profile="Skye" ".\Skye.BusinessCanvas.sln"
}
${function:bcNDepend} = { 
    Param([string] $baseVersion, [string] $currentVersion)

    cd $global:innoveo.SolutionBasePath

    $previousBranch = Get-GitBranch
	
    $currentVersionWithoutRevision = % { $versionParts = $($currentVersion).Split("(.)"); Write-Output "$($versionParts[0]).$($versionParts[1]).$($versionParts[2])" }
 	
    $ndarFilepath = (gci C:\Users\Laurent\Dropbox\NDependOut\$($baseVersion)\ -rec -filter *.ndar | Select-Object -first 1).fullname
	
    Write-output $ndarFilepath

    #git add -A
    #git commit -m 'SAVEPOINT'
	
    $tagName = "skye-editor-" + $currentVersionWithoutRevision
	
    & git checkout $tagName

    msbuild Skye.BusinessCanvas.sln
	
    $outputFolder = "c:\temp\NDependOut\Output_" + $currentVersion + "_" + $baseVersion
	
    New-Item -ItemType directory -Path $outputFolder

    & "C:\@Tools\Development\NDepend_6.0.0.8710_Alpha4TeamCity_v1\NDepend.Console.exe" "$($global:innoveo.SolutionBasePath)\Skye.BusinessCanvas.ndproj" /Concurrent /PersistHistoricAnalysisResult /HistoricAnalysisResultsDir "c:\temp\NDependOut\HistoricAnalysisResults" /CoverageFiles "C:\Users\Laurent\Dropbox\NDependOut\$($currentVersion)\dotCoverNDepend.xml" /InDirs "C:\@Innoveo\Projects\@Src\business-canvas\Output" "C:\Windows\Microsoft.NET\Framework\v4.0.30319" "C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF" /OutDir "$($outputFolder)" /TrendStoreDir "c:\temp\NDependOut\TrendStore" /AnalysisResultToCompareWith "$($ndarFilepath)"
	
    & explorer $outputFolder
}

${function:cleanMergedBranches} = {

    $local_branches = git branch --list

    foreach ($local_branch in $local_branches)
    {
        $result  = Invoke-Expression "& git ls-remote --heads origin $local_branch"
        if ([string]::IsNullOrWhiteSpace($result))
        {
            $jiran = $local_branch | Select-String "SKYE+-[0-9]+" | Select-Object -Expand Matches | Select-Object -Expand Groups | Select-Object -Expand Value
    
            if (![string]::IsNullOrWhiteSpace($jiran))
            {
                $json = curl -S -s -u $global:innoveo.JiraAPIToken -X GET -H 'Content-Type: application/json' https://innoveo.atlassian.net/rest/api/2/search?jql=key%20%3D%20$jiran | jq-win64.exe '.issues[0].fields.customfield_11920'
    
                $merged = $json | Select-String "state=MERGED" | Select-Object -Expand Matches | Select-Object -Expand Groups | Select-Object -Expand Value
    
                $local_branch_trimmed = $local_branch.Trim()
 
                if (![string]::IsNullOrWhiteSpace($merged))
                {
                    Write-Host "$local_branch_trimmed [https://innoveo.atlassian.net/browse/$jiran] is not on remote and ticket is merged"
                    git branch -D $local_branch_trimmed
                    Write-Host
                }
                else {
                    Write-Host "$local_branch_trimmed is not merged"
                }
            }
        }
    }
}

${function:cleanRemoteMergedBranches} = {

    $remoteBranches = Invoke-Expression "& git allfb"

    foreach ($remoteBranch in $remoteBranches) {
        # $remoteBranch look like "feature/SKYE-15134-V2-Try-Guid-With-MinOccurs - SKYE-15134 Fix failing tests for creation in ProductBrick, ProductPolicyAttribute - Laurent Kempé (7 days ago) - 21b489bbde"
        # Extract the branch name "feature/SKYE-15134-V2-Try-Guid-With-MinOccurs" and the Jira number "SKYE-15134"
        $branch = $remoteBranch.Split(" - ")[0].Trim()
        # Remove ANSI color codes if present
        $branch = $branch -replace '\x1b\[[0-9;]*m', ''
        $jiran = $branch | Select-String "SKYE+-[0-9]+" | Select-Object -Expand Matches | Select-Object -Expand Groups | Select-Object -Expand Value
        
        if (![string]::IsNullOrWhiteSpace($jiran)) {
            $json = curl -S -s -u $global:innoveo.JiraAPIToken -X GET -H 'Content-Type: application/json' https://innoveo.atlassian.net/rest/api/2/search?jql=key%20%3D%20$jiran | jq '.issues[0].fields.customfield_11920'
    
            $merged = $json | Select-String "state=MERGED" | Select-Object -Expand Matches | Select-Object -Expand Groups | Select-Object -Expand Value

            if (![string]::IsNullOrWhiteSpace($merged))
            {
                Write-Host "❌ $branch [https://github.com/Innoveo/skye-business-canvas/branches/all?query=$jiran&lastTab=overview] [https://innoveo.atlassian.net/browse/$jiran] is on remote and ticket is merged"
                
                # Delete remote branch
                Write-Host "Deleting remote branch: $branch"
                git push origin --delete $branch
                
                # Delete local branch if it exists
                $localBranchExists = git branch --list $branch
                if (![string]::IsNullOrWhiteSpace($localBranchExists)) {
                    Write-Host "Deleting local branch: $branch"
                    git branch -D $branch
                }
                
                Write-Host
            }
            else {
                Write-Host "⚠️ $branch [https://innoveo.atlassian.net/browse/$jiran] is not merged"
            }
        }
    }
}

# Jira

Set-JiraConfigServer $global:innoveo.BoardBaseUrl  

${function:bcb} = { openUrl('https://innoveo.atlassian.net/secure/RapidBoard.jspa?rapidView=1') }
${function:j} = {
    param([string]$branch)

    if (!$branch) {
        $branch = Get-GitBranch
    }

   $branch = $branch.Replace("review/", "")
   $branch = $branch.Replace("feature/", "")
   $branch = $branch.Replace("release/", "")
   $branch = $branch.Replace("bugfix/", "")
   $splittedBranch = $branch.split("-")
	
    if ("master" -eq $splittedBranch[0]) {
        $url = $global:innoveo.BoardBaseUrl + "/secure/RapidBoard.jspa?rapidView=1"
    }
    else {
        $url = $global:innoveo.BoardBaseUrl + "browse/" + $splittedBranch[0] + "-" + $splittedBranch[1]
    }
	
    openUrl($url)
}
${function:jBranches} = { # Browse all feature branches in Jira
    $branches = git branch
    $featureBranches = $branches.Split("`n`r") | Where-Object { $_ -like "*feature/*" } | ForEach-Object { $_ -replace "  " }

    $featureBranches | ForEach-Object { j($_) }
}
${function:bcbugs} = { # List all BC open bugs
    Get-JiraIssue -Query 'project = SKYE AND component = BC AND type = Bug AND resolution = Unresolved AND status not in ("In Progress", Closed, Review, Documentation, QA) ORDER BY createdDate ASC, status ASC, Rank2 ASC'
}
${function:bcbugscount} = { # Count all BC open bugs
    bcbugs | Measure-Object | Select-Object -expand Count
}
${function:bcreviews} = { # Count all BC open bugs
    Get-JiraIssue -Query 'project = Skye AND component in (BC) AND assignee = 557058:7782605d-41bc-4aa6-8ea8-5d64ee5ce126 AND status in (Review) ORDER BY Rank2 ASC'
}

# Jira & GitHub

${function:assignReview} = { # Assign current ticket linked to the current branch to a user on Jira and add the user as reviewer on GitHub
    
    $jiran = git jiran

    $userIndex = Show-Menu -Title "Select a user for $jiran" -Options $global:innoveo.BCTeam
        if ($null -eq $userIndex) {
            Write-Host "No user selected. Exiting."
            return
        }

    jira issue assign $jiran $global:innoveo.BCTeam[$userIndex].Name
    gh pr edit '--add-reviewer' $global:innoveo.BCTeam[$userIndex].GitHubUsername
}

# Github

${function:bcBranch} = { $branch = Get-GitBranch; openUrl($global:innoveo.RepoBaseUrl + 'tree/' + $branch) }
${function:bcPRs} = { openUrl($global:innoveo.RepoBaseUrl + 'pulls') }
${function:bcCommits} = { 
    param([string] $commitSHA1)
    openUrl($global:innoveo.RepoBaseUrl + 'commits/' + $commitSHA1)
}

# TeamCity 

${function:bcCI} = { openUrl($global:innoveo.CIBaseUrl) }
${function:bcCIBranch} = {
    $branch = git currentbranch
    $branch = $branch.Replace("review/", "")
    $branch = $branch.Replace("feature/", "")
    $branch = $branch.Replace("release/", "")
    $branch = $branch.Replace("bugfix/", "")

    $url = $global:innoveo.CIBaseUrl + "buildConfiguration/BusinessCanvas_Features_Build?branch=" + $branch + "&buildTypeTab=overview&mode=builds"

    openUrl($url)
}
${function:bcCIBuild} = {
    param([string]$branch)

    # Skye EditorCI - Feature Branches - Unit Tests, Code Coverage Zip 
    $url = $global:innoveo.CIBaseUrl + "httpAuth/action.html?add2Queue=SkyeEditor_Features"

    if (!$branch) {
        $branch = Get-GitBranch
    }

    $url = $url + "&name=BuildRefName&value=" + $branch
	
    $credentials = Get-Credential -Credential $global:me.Innoveo.TeamCityUser

    Write-Host Started personal build for branch $branch
    Get-FromWeb $url -credential $credentials
}

# Teams

${function:toReview} = {
   
    $jiran = git jiran

    Import-Module Microsoft.Graph.Teams

    Connect-MgGraph -Scopes "ChannelMessage.Send"

    $params = @{
        body = @{
            contentType = "html"
            content = "$jiran is ready for <at id=""0"">Review</at> <at id=""1"">JiraHelp</at>"
        }
        mentions = @(
            @{
                id = 0
                mentionText = "Review"
                mentioned = @{
                    application = @{
                        displayName = "Review"
                        id = "c70570ad-458d-4f42-ac47-e30926cd74b5"
                        applicationIdentityType = "bot"
                    }
                }
            },
            @{
                id = 1
                mentionText = "JiraHelp"
                mentioned = @{
                    application = @{
                        displayName = "JiraHelp"
                        id = "65b2a0a7-7449-4ee5-b728-b2d51627c9bb"
                        applicationIdentityType = "bot"
                    }
                }
            }
        )
    }

    New-MgTeamChannelMessage -TeamId $global:innoveo.TeamId -ChannelId $global:innoveo.ReviewChannelId -BodyParameter $params
}

# Slack
# Note: To post as a user (not a bot), use a User OAuth Token with 'chat:write' scope
# Generate one at: https://api.slack.com/apps -> Your App -> OAuth & Permissions -> User Token Scopes

$function:toReview = {
    param(
        [string]$SlackToken = $global:innoveo.SlackUserToken,
        [string]$SlackChannel = $global:innoveo.ReviewSlackChannelId,
        [string]$ReviewBotId = $global:innoveo.ReviewBotId,
        [switch]$WhatIf,
        [int]$TimeoutSeconds = 60,
        [int]$PollIntervalSeconds = 5,
        [switch]$Quiet
    )

    if (-not $SlackToken) {
        Write-Error "SLACK_TOKEN is not set. Use a User OAuth Token and provide via `$global:innoveo.SlackUserToken or -SlackToken parameter."
        return 1
    }
    if (-not $SlackChannel) {
        Write-Error "SLACK_CHANNEL is not set. Provide via `$global:innoveo.ReviewSlackChannelId` or -SlackChannel parameter."
        return 1
    }
    if(-not $ReviewBotId) {
        Write-Error "REVIEW_BOT_ID is not set. Provide via `$global:innoveo.ReviewBotId` or -ReviewBotId parameter."
        return 1
    }

    # Get current branch name
    $branch = (& git rev-parse --abbrev-ref HEAD 2>$null)
    if (-not $branch) {
        Write-Error "Failed to detect current git branch. Run this script from a git repository."
        return 1
    }
    $branch = $branch.Trim()

    # Extract JIRA ticket (e.g. SKYE-17043)
    $ticketMatch = [regex]::Match($branch, '[A-Z]+-\d+')
    if (-not $ticketMatch.Success) {
        Write-Error "No JIRA ticket found in branch name '$branch'."
        return 1
    }
    $ticket = $ticketMatch.Value

    $message = "$ticket is ready for <@$ReviewBotId>"

    if ($WhatIf) {
        if (-not $Quiet) {
            Write-Host "[WhatIf] Would post to Slack channel '$SlackChannel': $message"
            Write-Host "[WhatIf] Would also wait for first threaded reply (timeout: $TimeoutSeconds seconds)."
        }
        return 0
    }

    $payload = @{ channel = $SlackChannel; text = $message }

    try {
        $response = Invoke-RestMethod -Uri 'https://slack.com/api/chat.postMessage' -Method Post -Headers @{ Authorization = "Bearer $SlackToken" } -Body ($payload | ConvertTo-Json -Depth 3) -ContentType 'application/json' -TimeoutSec 30
    } catch {
        Write-Error "HTTP request to Slack failed: $_"
        return 1
    }

    if ($null -eq $response -or $response.ok -ne $true) {
        $err = if ($response -and $response.error) { $response.error } else { 'unknown_error' }
        Write-Error "Slack API returned an error: $err"
        return 1
    }

    # Successfully posted; thread timestamp is in 'ts'
    $thread_ts = $response.ts
    if (-not $Quiet) {
        Write-Host "Posted to Slack channel '$SlackChannel': $message (ts=$thread_ts)"
    }

    function Get-FirstThreadReply {
        param(
            [string]$Channel,
            [string]$ThreadTs,
            [string]$Token
        )
        try {
            $encodedChannel = [System.Uri]::EscapeDataString($Channel)
            $uri = "https://slack.com/api/conversations.replies?channel=$encodedChannel&ts=$ThreadTs&limit=10"
            $repliesResp = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ Authorization = "Bearer $Token" }
        } catch {
            Write-Error "Failed to fetch thread replies: $_"
            return $null
        }
        if ($null -eq $repliesResp -or $repliesResp.ok -ne $true) { 
            if (-not $Quiet) {
                Write-Host "API response not OK: $($repliesResp | ConvertTo-Json -Depth 2)"
            }
            return $null 
        }
        $messages = $repliesResp.messages
        if (-not $messages) { return $null }
        # Filter for bot replies only (messages with bot_id or app_id, excluding the root message)
        $firstReply = $messages | Where-Object { 
            $_.ts -ne $ThreadTs -and ($_.bot_id -or $_.app_id)
        } | Select-Object -First 1
        return $firstReply
    }

    # Always wait for reply
    if (-not $Quiet) {
        Write-Host "Waiting for reply (timeout: $TimeoutSeconds seconds)..."
    }
    $firstReply = $null
    $endTime = (Get-Date).AddSeconds($TimeoutSeconds)
    $attemptCount = 0
    while ((Get-Date) -lt $endTime) {
        $attemptCount++
        if (-not $Quiet) {
            Write-Host "Polling attempt #$attemptCount..."
        }
        $firstReply = Get-FirstThreadReply -Channel $SlackChannel -ThreadTs $thread_ts -Token $SlackToken
        if ($firstReply) { break }
        Start-Sleep -Seconds $PollIntervalSeconds
    }
    
    if ($firstReply) {
        # Handle both user replies and bot replies
        $sender = if ($firstReply.user) { 
            $firstReply.user 
        } elseif ($firstReply.bot_id) { 
            "bot:$($firstReply.bot_id)" 
        } elseif ($firstReply.username) {
            $firstReply.username
        } else { 
            '<unknown>' 
        }
        $text = if ($firstReply.text) { $firstReply.text } else { '<no text>' }
        if (-not $Quiet) {
            Write-Host "First threaded reply: $text (by $sender, ts=$($firstReply.ts))"
        }
        # Output the full object as JSON to stdout for scripting consumers
        $firstReply | ConvertTo-Json -Depth 5 | Write-Output
        return 0
    } else {
        if (-not $Quiet) {
            Write-Host "No threaded replies found for message ts=$thread_ts within timeout ($attemptCount attempts)."
        }
        return 0
    }
}

${function:createPatch} = {
    param([string]$newPatchVersion) # e.g. 9.11.1

    $previousPatchNumber = [int]$newPatchVersion.Split(".")[2] - 1
    $majorMinorVersion = $newPatchVersion.Substring(0, $newPatchVersion.LastIndexOf("."))
    $previousTagVersion = "skye-editor-$majorMinorVersion.$previousPatchNumber"

    Write-Host "Create patch $newPatchVersion on top of $previousTagVersion"

    git fetch --tags
    git checkout -b release/skye-editor-$newPatchVersion $previousTagVersion

    # Update version in build file
    $buildFile = ".\build\Build.cs"
    $buildFileContent = Get-Content $buildFile
    $buildFileContent = $buildFileContent -replace 'const string ReleaseCandidateBuildNumber = ".*";', "const string ReleaseCandidateBuildNumber = ""$newPatchVersion"";"
    Set-Content $buildFile $buildFileContent

    git add -A $buildFile
    git commit -m "NOTICKET Update version to $newPatchVersion"

    Write-Host "🎗️ Reminder: Push branch release/skye-editor-$newPatchVersion"
}
${function:downloadQADefinitions} = {
    param([string]$version) # e.g. 10.0.0

    if ([string]::IsNullOrWhiteSpace($version)) {
        Write-Host "Please provide a version number to download the QA definitions, e.g. 10.0.0"
        return
    }

    $outputFile = "skye-qa-test-definitions-skye-$version.zip"
    if (Test-Path $outputFile) {
        #Ask the user if he wants to remove the file
        $response = Read-Host "File $outputFile already exists. Do you want to remove it? (y/n)"
        if ($response -eq "y") {
            Remove-Item $outputFile
        }
        else {
            Write-Host "Download aborted"
            return
        }
    }

    $spinner =  @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷")
    $spinnerIndex = 0

    # Start the gh api command as a background job
    $job = Start-Job -ArgumentList $version, $global:innoveo.QADefinitionRepo -ScriptBlock {
        param ($version, $repo)
        gh api -H "Accept: application/vnd.github.v3+json" ("/repos/" + $repo + "/zipball/skye-$version") >> "skye-qa-test-definitions-skye-$version.zip"
    }

    # Display the spinner while the job is running
    while ($job.State -eq 'Running') {
        Write-Host -NoNewline -ForegroundColor Yellow "`r$($spinner[$spinnerIndex]) Downloading QA Definitions..."
        Start-Sleep -Milliseconds 200
        $spinnerIndex = ($spinnerIndex + 1) % $spinner.Length
    }

    # Wait for the job to complete and get the result
    $result = Receive-Job -Job $job
    Remove-Job -Job $job

    Write-Host "`rDownload complete!                             "
}
