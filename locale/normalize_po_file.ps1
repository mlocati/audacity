param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$InputFile,
    [Parameter(Position = 1, Mandatory = $false)]
    [string]$OutputFile = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not(Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    throw "Unable to find the input file $InputFile"
}
if ($null -eq $OutputFile -or $OutputFile -eq '') {
    $OutputFile = $InputFile
}
$contents = (Get-Content -Path $InputFile -Encoding utf8NoBOM) -join "`n"
# replace Windows line endings with Posix line endings
$contents = $contents -creplace "\r\n", "`n"
# replace old Mac line endings with Posix line endings
$contents = $contents -creplace "\r", "`n"
if (-not($contents -cmatch "\nmsgstr\s")) {
    throw "The input file $InputFile is not a .pot/.po gettext file!"
}
# trim trailing spaces/tabs
$contents = $contents -creplace "[ \t]+\n", "`n"
# make it so we have only one line for every msgid/msgid_plural/msgstr
$contents = $contents -creplace '"\n"', ''
# split strings at '\n'
$contents = $contents -creplace '\\n', "\n`"`n`""
# remove lines containing only ""
$contents = $contents -creplace '\n""', "`n"
Set-Content -LiteralPath $OutputFile  -Value $contents -Encoding utf8NoBOM