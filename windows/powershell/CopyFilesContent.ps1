<#
.SYNOPSIS
    Formats and copies the content of specified file types in a given directory and its subdirectories.

.DESCRIPTION
    This script recursively searches for files with specified extensions in a given directory (or the current directory if not specified) and its subdirectories,
    formats their content with Markdown code blocks, and copies the result to the clipboard.
    It can include specific file extensions and optionally print the output to the console.

.PARAMETER Path
    The path to the directory to process. If not specified, the current directory is used.

.PARAMETER IncludeExtensions
    An array of file extensions to include in processing. Default is @(".txt", ".md", ".cs", ".js", ".html", ".css").

.PARAMETER PrintToScreen
    A switch parameter. If present, the formatted output will be printed to the console.

.EXAMPLE
    .\CopyFilesContent.ps1
    Runs the script on the current directory with default settings.

.EXAMPLE
    .\CopyFilesContent.ps1 -Path "C:\Projects\MyProject"
    Runs the script on the specified directory with default settings.

.EXAMPLE
    .\CopyFilesContent.ps1 -PrintToScreen -Path "C:\Projects\MyProject"
    Runs the script on the specified directory and prints the output to the console.

.EXAMPLE
    .\CopyFilesContent.ps1 -IncludeExtensions @(".py", ".java", ".xml") -Path "C:\Projects\MyProject"
    Runs the script on the specified directory, including only .py, .java, and .xml files.

.EXAMPLE
    .\CopyFilesContent.ps1 -PrintToScreen -IncludeExtensions @(".py", ".java", ".xml") -Path "C:\Projects\MyProject"
    Runs the script on the specified directory, including specified files and printing the output to the console.

.NOTES
    If no path is specified, the script will run on the current directory.
    If no extensions are specified, it will default to common text-based file types.
#>

param(
    [string]$Path = (Get-Location),
    [string[]]$IncludeExtensions = @(".txt", ".md", ".cs", ".js", ".html", ".css"),
    [switch]$PrintToScreen = $false
)

$output = ""

# Function to check if a file should be included
function ShouldIncludeFile($file) {
    return $IncludeExtensions -contains $file.Extension.ToLower()
}

# Ensure the path exists
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "The specified path does not exist or is not a directory: $Path"
    exit 1
}

# Get the full path
$fullPath = Resolve-Path $Path

Get-ChildItem -Path $fullPath -Recurse -File | Where-Object { ShouldIncludeFile $_ } | ForEach-Object {
    $relativePath = $_.FullName.Substring($fullPath.Path.Length + 1)
    $content = Get-Content $_.FullName -Raw

    $output += "``````$relativePath`n"
    $output += "$content`n"
    $output += "```````n`n"
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
Write-Output "Included extensions: $($IncludeExtensions -join ', ')"
