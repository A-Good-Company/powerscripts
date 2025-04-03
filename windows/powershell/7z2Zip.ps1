#winget install 7zip.7zip


Get-ChildItem -Filter "*.7z" | ForEach-Object {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $tempDir = "7zconv-temp-$(Get-Random)"
    
    # Create unique temporary directory
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Extract 7z contents directly to temp directory root
    & "C:\Program Files\7-Zip\7z.exe" x $_.FullName "-o$tempDir" -y
    
    # Create zip from temp directory contents (without parent folder)
    Push-Location $tempDir
    & "C:\Program Files\7-Zip\7z.exe" a -tzip "$PWD\..\$baseName.zip" "*" -r
    Pop-Location
    
    # Cleanup temporary directory
    Remove-Item -Path $tempDir -Recurse -Force
}
