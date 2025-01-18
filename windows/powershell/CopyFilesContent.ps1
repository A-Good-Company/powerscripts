<#
.SYNOPSIS
    Formats and copies the content of specified files and directories, including word counts.

.DESCRIPTION
    This script processes specified files and directories, formats their content with Markdown code blocks, and copies the result to the clipboard. 
    It provides word counts for each file and a cumulative total. It can include specific file extensions and optionally print the output to the console.

.PARAMETER Targets
    An array of file and directory paths to process. If not specified, the current directory is used.

.PARAMETER IncludeExtensions
    An array of file extensions to include in processing. If not specified, all file extensions will be included.

.PARAMETER Recursive
    A switch parameter. If present, subdirectories will be included in the search when processing directories.

.PARAMETER PrintToScreen
    A switch parameter. If present, the formatted output will be printed to the console.

.EXAMPLE
    .\CopyFilesContent.ps1 -Targets @("C:\file1.txt", "C:\Projects\MyProject")
    Processes the specified file and directory.

.EXAMPLE
    .\CopyFilesContent.ps1 -Targets @("C:\Projects\MyProject") -Recursive -IncludeExtensions @(".py", ".java")
    Processes the specified directory and its subdirectories, including only .py and .java files.

.EXAMPLE
    .\CopyFilesContent.ps1 -PrintToScreen -Targets @("C:\file1.txt", "C:\file2.py", "C:\Projects\MyProject")
    Processes the specified files and directory, and prints the output to the console.

.NOTES
    If no targets are specified, the script will run on the current directory.
    If no extensions are specified, it will include all file types.
#>

param(
    [string[]]$Targets = @((Get-Location).Path),
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

# Function to process a file
function ProcessFile($file) {
    $content = Get-Content $file.FullName -Raw
    $wordCount = CountWords $content
    
    $fileOutput = "``````$($file.FullName)`n"
    $fileOutput += "$content`n"
    $fileOutput += "```````n`n"

    $script:processedFiles += [PSCustomObject]@{
        Path = $file.FullName
        WordCount = $wordCount
    }

    $script:totalWordCount += $wordCount

    return $fileOutput
}

# Function to process a directory
function ProcessDirectory($dir) {
    $getChildItemParams = @{
        Path = $dir
        File = $true
    }
    if ($Recursive) {
        $getChildItemParams.Add("Recurse", $true)
    }

    $dirOutput = ""

    Get-ChildItem @getChildItemParams | Where-Object { ShouldIncludeFile $_ } | ForEach-Object {
        $dirOutput += ProcessFile $_
    }

    return $dirOutput
}

# Process each target
foreach ($target in $Targets) {
    if (Test-Path -Path $target -PathType Leaf) {
        # Target is a file
        $file = Get-Item $target
        if (ShouldIncludeFile $file) {
            $output += ProcessFile $file
        }
    } elseif (Test-Path -Path $target -PathType Container) {
        # Target is a directory
        $output += ProcessDirectory $target
    } else {
        Write-Warning "The specified path does not exist: $target"
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

Write-Output "`nProcessed targets:"
$Targets | ForEach-Object { Write-Output "- $_" }

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