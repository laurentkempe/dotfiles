# Innoveo Skye Business Canvas

# Development

${function:bc} = { Set-Location $global:innoveo.SolutionBasePath }
${function:i} = { bc; .. }
${function:bcvs} = { bc; vs ([IO.Path]::Combine($global:innoveo.SolutionBasePath, 'Skye.BusinessCanvas.sln') | Resolve-Path) }
${function:bcDev} = { bcvs; bcb; }
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

# Jira

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
