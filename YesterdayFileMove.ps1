$source = "C:\Source\" # Replace with your source folder path
$destination = "C:\Destination\" # Replace with your destination folder path
$dateFormat = 'yyyyMMdd' # Prerequisite - define date format
$yesterday = (Get-Date).AddDays(-1).ToString('ddMMyyyy')
$files = Get-ChildItem -Path $source -File | Where-Object { $_.LastWriteTime.Date -eq $yesterday }

foreach ($file in $files) {
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    Move-Item -Path $file.FullName -Destination $destinationFile -Force
}

Write-Output "Moved $(($files | Measure-Object).Count) files from $source to $destination."