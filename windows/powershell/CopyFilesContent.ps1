<#
.SYNOPSIS
    Formats and copies the content of specified file types in a given directory and optionally its subdirectories, including word counts.

.DESCRIPTION
    This script searches for files with specified extensions in a given directory (or the current directory if not specified) and optionally its subdirectories,
    formats their content with Markdown code blocks, and copies the result to the clipboard. It also provides word counts for each file and a cumulative total.
    It can include specific file extensions and optionally print the output to the console.

.PARAMETER Path
    The path to the directory to process. If not specified, the current directory is used.

.PARAMETER IncludeExtensions
    An array of file extensions to include in processing. If not specified, all file extensions will be included.

.PARAMETER Recursive
    A switch parameter. If present, subdirectories will be included in the search.

.PARAMETER PrintToScreen
    A switch parameter. If present, the formatted output will be printed to the console.

.EXAMPLE
    .\CopyFilesContent.ps1
    Runs the script on the current directory with default settings.

.EXAMPLE
    .\CopyFilesContent.ps1 -Path "C:\Projects\MyProject" -Recursive
    Runs the script on the specified directory and its subdirectories.

.EXAMPLE
    .\CopyFilesContent.ps1 -PrintToScreen -Path "C:\Projects\MyProject" -IncludeExtensions @(".py", ".java", ".xml")
    Runs the script on the specified directory, including only .py, .java, and .xml files, and prints the output to the console.

.NOTES
    If no path is specified, the script will run on the current directory.
    If no extensions are specified, it will include all file types.
#>

param(
    [string]$Path = (Get-Location),
    [string[]]$IncludeExtensions = @(),
    [switch]$Recursive = $false,
    [switch]$PrintToScreen = $false
)

$output = ""
$processedFiles = @()
$totalWordCount = 0

# Function to check if a file should be included
function ShouldIncludeFile($file) {
    return $IncludeExtensions.Count -eq 0 -or $IncludeExtensions -contains $file.Extension.ToLower()
}

# Function to count words in a string
function CountWords($text) {
    return ($text -split '[\s.,]+' | Where-Object { $_ -ne '' }).Count
}

# Ensure the path exists
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "The specified path does not exist or is not a directory: $Path"
    exit 1
}

# Get the full path
$fullPath = Resolve-Path $Path

# Set up the Get-ChildItem parameters
$getChildItemParams = @{
    Path = $fullPath
    File = $true
}
if ($Recursive) {
    $getChildItemParams.Add("Recurse", $true)
}

Get-ChildItem @getChildItemParams | Where-Object { ShouldIncludeFile $_ } | ForEach-Object {
    $relativePath = $_.FullName.Substring($fullPath.Path.Length + 1)
    $content = Get-Content $_.FullName -Raw
    $wordCount = CountWords $content
    $totalWordCount += $wordCount

    $output += "``````$relativePath`n"
    $output += "$content`n"
    $output += "```````n`n"

    $processedFiles += [PSCustomObject]@{
        Path = $relativePath
        WordCount = $wordCount
    }
}

# Output to console if option is set
if ($PrintToScreen) {
    Write-Output $output
}

# Copy to clipboard
$output | Set-Clipboard

Write-Output "The formatted output has been copied to your clipboard."
if ($PrintToScreen) {
    Write-Output "The output has also been printed to the console."
} else {
    Write-Output "The output was not printed to the console. Use -PrintToScreen to enable console output."
}

Write-Output "`nProcessed directory: $fullPath"
if ($Recursive) {
    Write-Output "Included subdirectories: Yes"
} else {
    Write-Output "Included subdirectories: No"
}
if ($IncludeExtensions.Count -eq 0) {
    Write-Output "Included extensions: All"
} else {
    Write-Output "Included extensions: $($IncludeExtensions -join ', ')"
}

Write-Output "`nProcessed files:"
$processedFiles | ForEach-Object { Write-Output "- $($_.Path) (Words: $($_.WordCount))" }
Write-Output "`nTotal files processed: $($processedFiles.Count)"
Write-Output "Total word count: $totalWordCount"