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
${function:gdvs} = { gd; vs (Get-Location).Path + "GitDiffMargin.sln" }
${function:gdPRs} = { openUrl($GitDiffMarginGithubBaseUrl + 'pulls') }
${function:gdCI} = { openUrl($GitDiffMarginCIBaseUrl + '_build') }

# Blog

$BlogPath = '~\laurentkempe.github.io'
${function:blog} = { cd $BlogPath; code . }
