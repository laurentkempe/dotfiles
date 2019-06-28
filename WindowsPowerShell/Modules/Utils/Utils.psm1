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
${function:prj} = { Set-Location ~\projects }

# Windows
${function:e} = { explorer '.' }
${function:vi} = { 'C:\Program Files\Notepad++\notepad++.exe' }

# Chocolatey
${function:cu} = { & "choco" upgrade all -y }

# Devs
${function:cleanBin} = {
    param ([string]$path = (Get-Location).Path)
    write-host "Cleaning bin and obj from: $path"
    get-childitem $path -include bin -recurse | remove-item -recurse -confirm:$false
    get-childitem $path -include obj -recurse | remove-item -recurse -confirm:$false
}
${function:dev} = {
    param ([string]$options)
    & "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe" $options
}
${function:vs} = {
    param ([string]$solution)
    $vsTempDir = "C:\VsTemp";
    $env:TEMP = $vsTempDir
    $env:TMP = $vsTempDir
    if (![System.IO.Directory]::Exists($vsTempDir)) { [System.IO.Directory]::CreateDirectory($vsTempDir) }
    dev $solution
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
