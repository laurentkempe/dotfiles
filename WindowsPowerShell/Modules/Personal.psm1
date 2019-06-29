$global:me = @{
    Firstname = "Laurent"
    Name      = "Kempe"
}

# Personal Projects

# Git Diff Margin - https://github.com/laurentkempe/GitDiffMargin

$GitDiffMarginPath = '~\projects\GitDiffMargin'
$GitDiffMarginSolution = [IO.Path]::Combine($GitDiffMarginPath, 'GitDiffMargin.sln') | Resolve-Path

${function:gd} = { cd $GitDiffMarginPath }
${function:gdvs} = { gd; vs $GitDiffMarginSolution }

# Blog

$BlogPath = '~\laurentkempe.github.io'
${function:blog} = { cd $BlogPath; code . }

Export-ModuleMember -Function * -Alias * 