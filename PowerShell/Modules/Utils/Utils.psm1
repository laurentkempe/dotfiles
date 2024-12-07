# Easier Navigation: .., ..., ...., ....., and ~
${function:~} = { Set-Location ~ }
# PoSh won't allow ${function:..} because of an invalid path error, so...
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ..\.. }
${function:....} = { Set-Location ..\..\.. }
${function:.....} = { Set-Location ..\..\..\.. }
${function:......} = { Set-Location ..\..\..\..\.. }

# Navigation Shortcuts
${function:dt} = { Set-Location ~\Desktop }
${function:docs} = { Set-Location ~\Documents }
${function:dl} = { Set-Location ~\Downloads }
${function:p} = { Set-Location ~\projects }

# Windows
${function:e} = { explorer '.' }
${function:x} = { exit }
${function:vi} = {
    param ([string]$filepath)
    & "C:\Program Files\Notepad++\notepad++.exe" $filepath
}
function startProcessHigh ($cliCmd, $cmdWorkingDirectory, $cmdArgs) {
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $cliCmd
    $ProcessInfo.Arguments = $cmdArgs
    $ProcessInfo.WorkingDirectory = $cmdWorkingDirectory
    $ProcessInfo.UseShellExecute = $False
    $newProcess = [System.Diagnostics.Process]::Start($ProcessInfo)
    $newProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
}

# Winget
${function:wu} = { & "winget" source update; & "winget" upgrade }

# Chocolatey
${function:cu} = { & "choco" upgrade all -y }

# Devs
${function:cleanBin} = {
    param ([string]$path = (Get-Location).Path)
    write-host "Cleaning bin and obj from: $path"
    get-childitem $path -include bin -recurse | get-childitem -recurse | remove-item -recurse -force -confirm:$false
    get-childitem $path -include obj -recurse | get-childitem -recurse | remove-item -recurse -force -confirm:$false
    write-host "Cleaning Output from: $path"
    Remove-Item -LiteralPath ".\Output" -Force -Recurse -ErrorAction Ignore
}
${function:cleanNode} = {
    param ([string]$path = (Get-Location).Path)
    get-childitem -Path "$path" -Include "node_modules" -Recurse -Directory | Remove-Item -Recurse -Force
}
${function:vs} = {
    param ([string]$solution)

    $vsTempDir = "C:\VsTemp";
    $env:TEMP = $vsTempDir
    $env:TMP = $vsTempDir
    if (![System.IO.Directory]::Exists($vsTempDir)) { [System.IO.Directory]::CreateDirectory($vsTempDir) }

    if (!$solution) {
        $solution = (Get-ChildItem *.sln).FullName;
        if (!$solution) {
            $solution = (Get-ChildItem *.csproj).FullName;
        }
    }

    $open = ($solution.Split(" ") | Select-Object -First 1)

    startProcessHigh "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe" . $open
    #Clear-Host
}
${function:rider} = {
    param ([string]$solution)

    if (!$solution) {
        $solution = (Get-ChildItem -Filter *.slnx).FullName;
        if (!$solution) {
            $solution = (Get-ChildItem -Filter *.sln).FullName;
            if (!$solution) {
                $solution = (Get-ChildItem *.csproj).FullName;
            }
        }
    }

    $open = ($solution.Split(" ") | Select-Object -First 1)

    startProcessHigh "rider.cmd" . $open
}
# Function to run diff using Rider "rider diff '.\AppCenter 503.txt' '.\AppCenter 505.txt'" which use Resolve-Path to get the full path of both parameters
${function:dif} = {
    param ([string]$leftFile, [string]$rightFile)
    $leftFile = Resolve-Path $leftFile
    $rightFile = Resolve-Path $rightFile
    & rider.cmd diff "$leftFile" "$rightFile"
}
# PowerShell parameter completion shim for the dotnet CLI - https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Github Cli

#Github Cli completion
#https://github.com/cli/cli/issues/1775#issuecomment-706581004
gh completion -s powershell | Join-String {
    $_ -replace " ''\)$"," ' ')" -replace "(^\s+\)\s-join\s';')",'$1 -replace ";$wordToComplete$"' -replace "(\[CompletionResult\]::new\('[\w-]+)'",'$1 '''
} -Separator "`n" | Invoke-Expression


${function:pr} = {
    gh pr view --web
}

# Others
function openUrl([string]$url) {
    start $url
}

function Get-Web($url, 
    [switch]$self,
    $credential, 
    $toFile,
    [switch]$bytes) {
    #.Synopsis
    #    Downloads a file from the web
    #.Description
    #    Uses System.Net.Webclient (not the browser) to download data
    #    from the web.
    #.Parameter self
    #    Uses the default credentials when downloading that page (for downloading intranet pages)
    #.Parameter credential
    #    The credentials to use to download the web data
    #.Parameter url
    #    The page to download (e.g. www.msn.com)    
    #.Parameter toFile
    #    The file to save the web data to
    #.Parameter bytes
    #    Download the data as bytes   
    #.Example
    #    # Downloads www.live.com and outputs it as a string
    #    Get-Web http://www.live.com/
    #.Example
    #    # Downloads www.live.com and saves it to a file
    #    Get-Web http://wwww.msn.com/ -toFile www.msn.com.html
    $webclient = New-Object Net.Webclient
    if ($credential) {
        $webClient.Credentials = $credential
    }
    if ($self) {
        $webClient.UseDefaultCredentials = $true
    }
    if ($toFile) {
        if (-not "$toFile".Contains(":")) {
            $toFile = Join-Path $pwd $toFile
        }
        $webClient.DownloadFile($url, $toFile)
    }
    else {
        if ($bytes) {
            $webClient.DownloadData($url)
        }
        else {
            $webClient.DownloadString($url)
        }
    }
}

# PSReadline Thanks @martinskuta

function MergeFilesAllLinesByPrefix {
    param(
        [string]$prefix,
        [string]$folderPath,
        [string]$outfile
    )
 
    # Get all files with a given prefix
    Write-Host "Getting files in : $($folderPath) with prefix $($prefix)"
    $files = Get-ChildItem -Path $folderPath -Filter "$prefix*"
 
    # Initialize a hashset to hold unique lines
    $uniqueLines = New-Object "System.Collections.Generic.HashSet[string]"
 
    foreach ($file in $files) {
        # Read each line
        $lines = Get-Content $file.FullName
        foreach ($line in $lines) {
            # Add the line to the set, duplicates will be ignored automatically
            $null= $uniqueLines.Add($line)
        }
 
        # Delete file after reading its content.
        Remove-Item $file.FullName
    }
 
    # Write unique lines to an output file
    $uniqueLines | Out-File -FilePath $outFile
}

function ConsolidatePSReadlineSharedHistory(){
    # Get history file path
    $historyFilePath = (Get-PSReadlineOption).HistorySavePath
    # Get FileInfo
    $fileInfo = Get-Item $historyFilePath
    # Get directory
    $historyFileDirectory = $fileInfo.Directory
    # Get file base name without extension
    $historyFileNameWithoutExtension = $fileInfo.BaseName
 
    Write-Host "Consolidating powershell history in: $($fileInfo.Directory)"
    MergeFilesAllLinesByPrefix -prefix $historyFileNameWithoutExtension -folderPath $historyFileDirectory -outfile $historyFilePath
}

function AddAllProjectToSolution(){
    Get-ChildItem -Recurse -Filter "*.csproj" | ForEach-Object { dotnet sln add $_.FullName }
}
