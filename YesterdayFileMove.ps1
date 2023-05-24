$sourceFolderPath = "C:\Source\" # Replace with your source folder path
$destinationFolderPath = "C:\Destination\" # Replace with your destination folder path

# Get the date for yesterday
$yesterday = (Get-Date).AddDays(-1).ToString("yyyyMMdd")

# Get all .zip files in the source folder that were modified yesterday
$filesToMove = Get-ChildItem -Path $sourceFolderPath -Filter "*.zip" | Where-Object {$_.LastWriteTime.ToString("yyyyMMdd") -eq $yesterday}

# Loop through the files and move them to the destination folder
foreach ($file in $filesToMove) {
    $destinationFilePath = Join-Path $destinationFolderPath $file.Name
    $destinationFile = New-Object System.IO.FileInfo($destinationFilePath)
    [System.IO.File]::Move($file.FullName, $destinationFile.FullName)
}