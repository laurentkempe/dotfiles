# Innoveo Skye Business Canvas

# Development

${function:bc} = { Set-Location $global:innoveo.SolutionBasePath }
${function:i} = { bc; .. }
${function:bcvs} = { bc; vs ([IO.Path]::Combine($global:innoveo.SolutionBasePath, 'Skye.BusinessCanvas.sln') | Resolve-Path) }
${function:bcDev} = { bcvs; bcb; }
${function:bcClean} = { bc; Remove-Item -Recurse packages; Remove-Item -Recurse Output }
${function:bcReview} = { Param([string] $jiran) i; cd business-canvas-wt; if ($jiran) { git cfb $jiran } }
${function:bcReviewReady} = { $jiran = git jiran; Set-Clipboard "$jiran is ready for @Review @JiraHelp"; Write-Host (Get-Clipboard) }
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
    $branch = Get-GitBranch
    $branch = $branch.Replace("review/", "")
    $branch = $branch.Replace("feature/", "")
    $branch = $branch.Replace("release/", "")
    $branch = $branch.Replace("bugfix/", "")

    $url = $global:innoveo.CIBaseUrl + "viewType.html?buildTypeId=SkyeEditor_Features&branch_SkyeEditor_Features=" + $branch + "&tab=buildTypeStatusDiv"

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
