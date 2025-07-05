$global:me = @{
    Firstname = "Laurent"
    Name      = "Kempe"
}

# Personal Projects

# Git Diff Margin

$GitDiffMarginPath = '~\projects\GitDiffMargin'
$GitDiffMarginGithubBaseUrl = 'https://github.com/laurentkempe/GitDiffMargin/'
$GitDiffMarginCIBaseUrl = 'https://dev.azure.com/techheadbrothers/GitDiffMargin/'
${function:gd} = { cd $GitDiffMarginPath }
${function:gdvs} = { gd; vs ([IO.Path]::Combine($GitDiffMarginPath, 'GitDiffMargin.sln') | Resolve-Path) }
${function:gdPRs} = { openUrl($GitDiffMarginGithubBaseUrl + 'pulls') }
${function:gdCI} = { openUrl($GitDiffMarginCIBaseUrl + '_build') }

# Blog

$BlogPath = '~\projects\blog'
${function:blog} = { cd $BlogPath; code . }

# Logseq 

${function:Sync-LogseqConfig} = {
    param(
        [int]$RetentionDays = 7,
        [switch]$SkipGit,
        [switch]$WhatIf
    )
    
    try {
        # Check for administrator privileges (required for symbolic links)
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning "⚠️ Administrator privileges required for symbolic link creation"
            Write-Output "Please run PowerShell as Administrator and try again"
            return
        }

        # Detect OneDrive and set paths with validation
        $oneDriveProperty = Get-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive" -ErrorAction Stop
        if (-not $oneDriveProperty.UserFolder) {
            throw "OneDrive UserFolder not found in registry"
        }
        $oneDrivePath = $oneDriveProperty.UserFolder
        
        if (-not (Test-Path $oneDrivePath)) {
            throw "OneDrive path does not exist: $oneDrivePath"
        }

        $syncedLogseq = Join-Path $oneDrivePath ".logseq"
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $backupFolder = Join-Path $oneDrivePath ".logseq_backup_$timestamp"
        $localLogseq = "$env:USERPROFILE\.logseq"

        Write-Output "🔄 Starting Logseq configuration sync..."

        # Backup current local .logseq to OneDrive with verification
        if (Test-Path $localLogseq) {
            Write-Output "🔐 Backing up .logseq to $backupFolder"
            
            if ($WhatIf) {
                Write-Output "WHATIF: Would backup $localLogseq to $backupFolder"
            } else {
                Copy-Item $localLogseq -Destination $backupFolder -Recurse -ErrorAction Stop
                
                # Verify backup was created successfully
                if (Test-Path $backupFolder) {
                    $backupSize = (Get-ChildItem $backupFolder -Recurse -ErrorAction SilentlyContinue | 
                                 Measure-Object -Property Length -Sum).Sum
                    $backupSizeMB = if ($backupSize) { ($backupSize/1MB).ToString('F2') } else { "0" }
                    Write-Output "📦 Backup created successfully ($backupSizeMB MB)"
                } else {
                    Write-Warning "⚠️ Backup creation may have failed"
                }
            }
        } else {
            Write-Output "ℹ️ No existing .logseq folder found to backup"
        }

        # Ensure OneDrive .logseq directory exists and copy files if needed
        if (-not (Test-Path $syncedLogseq)) {
            Write-Output "📁 Creating OneDrive .logseq directory"
            if (-not $WhatIf) {
                New-Item -ItemType Directory -Path $syncedLogseq -Force | Out-Null
            }
        }

        # Copy backed up files to OneDrive if they don't exist there
        $itemsToLink = @("config", "preferences.json", "plugins", "settings")
        foreach ($item in $itemsToLink) {
            $oneDriveItemPath = Join-Path $syncedLogseq $item
            $backupItemPath = Join-Path $backupFolder $item
            
            if (-not (Test-Path $oneDriveItemPath) -and (Test-Path $backupItemPath)) {
                Write-Output "📋 Copying $item to OneDrive location"
                if (-not $WhatIf) {
                    Copy-Item $backupItemPath -Destination $oneDriveItemPath -Recurse -ErrorAction SilentlyContinue
                }
            }
        }

        # Auto-delete older backups
        $oldBackups = Get-ChildItem -Path $oneDrivePath -Filter ".logseq_backup_*" -ErrorAction SilentlyContinue |
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
        
        if ($oldBackups) {
            foreach ($backup in $oldBackups) {
                Write-Output "🗑️ Deleting old backup: $($backup.Name)"
                if (-not $WhatIf) {
                    Remove-Item $backup.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Output "ℹ️ No old backups to clean up"
        }

        # Ensure .logseq directory exists locally
        if (-not (Test-Path $localLogseq)) {
            Write-Output "📁 Creating local .logseq directory"
            if (-not $WhatIf) {
                New-Item -ItemType Directory -Path $localLogseq -Force | Out-Null
            }
        }

        # Remove originals before linking
        foreach ($item in $itemsToLink) {
            $path = Join-Path $localLogseq $item
            if (Test-Path $path) {
                Write-Output "🧹 Removing existing $item"
                if (-not $WhatIf) {
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # Create symbolic links to OneDrive with verification
        $successfulLinks = 0
        foreach ($item in $itemsToLink) {
            $linkPath = Join-Path $localLogseq $item
            $targetPath = Join-Path $syncedLogseq $item
            
            if (Test-Path $targetPath) {
                try {
                    Write-Output "🔗 Creating symlink for $item"
                    if (-not $WhatIf) {
                        $link = New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -Force -ErrorAction Stop
                        $successfulLinks++
                    }
                } catch {
                    Write-Warning "⚠️ Failed to create symlink for $item`: $($_.Exception.Message)"
                }
            } else {
                Write-Warning "⚠️ Target not found, skipping: $item (Expected: $targetPath)"
            }
        }

        if (-not $WhatIf) {
            Write-Output "🔗 Successfully created $successfulLinks symbolic links"
        }

        # Optional: Commit and push to GitHub with safer handling
        if (-not $SkipGit -and (Test-Path "$oneDrivePath\.git")) {
            Write-Output "📤 Processing Git operations..."
            
            if ($WhatIf) {
                Write-Output "WHATIF: Would commit and push changes to Git"
            } else {
                Push-Location $oneDrivePath
                try {
                    # Check if there are changes to commit
                    $gitStatus = git status --porcelain 2>$null
                    if ($LASTEXITCODE -eq 0 -and $gitStatus) {
                        Write-Output "📝 Committing changes to Git..."
                        git add . 2>$null
                        git commit -m "Auto backup: $timestamp" 2>$null
                        
                        # Only push if commit succeeded
                        if ($LASTEXITCODE -eq 0) {
                            Write-Output "📤 Pushing to remote repository..."
                            git push origin main 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                Write-Output "✅ Successfully pushed to Git"
                            } else {
                                Write-Warning "⚠️ Git push failed (check network connection and credentials)"
                            }
                        } else {
                            Write-Warning "⚠️ Git commit failed"
                        }
                    } elseif ($LASTEXITCODE -eq 0) {
                        Write-Output "📝 No changes to commit"
                    } else {
                        Write-Warning "⚠️ Git status check failed - repository may have issues"
                    }
                } catch {
                    Write-Warning "⚠️ Git operation failed: $($_.Exception.Message)"
                } finally {
                    Pop-Location
                }
            }
        } elseif (-not (Test-Path "$oneDrivePath\.git")) {
            Write-Output "ℹ️ No Git repository found in OneDrive path"
        }

        Write-Output "✅ Logseq sync and backup complete!"
        
        if (-not $WhatIf) {
            Write-Output "📊 Summary:"
            Write-Output "   • Backup retention: $RetentionDays days"
            Write-Output "   • Symbolic links created: $successfulLinks/$($itemsToLink.Count)"
            Write-Output "   • Git operations: $(if ($SkipGit) { 'Skipped' } else { 'Processed' })"
        }

    } catch {
        Write-Error "❌ Failed to sync Logseq config: $($_.Exception.Message)"
        Write-Output "🔍 Please check:"
        Write-Output "   • OneDrive is properly installed and configured"
        Write-Output "   • You have administrator privileges"
        Write-Output "   • Target paths are accessible"
        return
    }
}
