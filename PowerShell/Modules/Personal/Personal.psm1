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
