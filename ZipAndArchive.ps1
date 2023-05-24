param (
   [string] $ParentFolder = "S:\ParentFolder\",
   $Filter = { $_.LastWriteTime -lt (Get-Date).AddHour(-1)},
   [string] $ZipPath = "S:\Destination\archive-$(get-date -f yyyy-MM-dd).zip", 
   [System.IO.Compression.CompressionLevel]$CompressionLevel = [System.IO.Compression.CompressionLevel]::Fastest, 
   [switch] $DeleteAfterArchiving = $true,
   [switch] $Verbose = $true,
   [switch] $Recurse = $true
)
@( 'System.IO.Compression','System.IO.Compression.FileSystem') | % { [void][System.Reflection.Assembly]::LoadWithPartialName($_) }
Push-Location $ParentFolder
$FileList = (Get-ChildItem -File -Recurse:$Recurse  | Where-Object $Filter)
$totalcount = $FileList.Count
$countdown = $totalcount
$skipped = @()
$batchSize = 60
$processedCount = 5
Try{
    $WriteArchive = [IO.Compression.ZipFile]::Open( $ZipPath, [System.IO.Compression.ZipArchiveMode]::Update)
    ForEach ($File in $FileList){
        if ($processedCount -ge $batchSize) {
            break
        }
        Write-Progress -Activity "Archiving files" -Status  "Archiving file $($totalcount - $countdown) of $totalcount : $($File.Name)"  -PercentComplete (($totalcount - $countdown)/$totalcount * 100)
        $ArchivedFile = $null
        $RelativePath = (Resolve-Path -LiteralPath "$($File.FullName)" -Relative) -replace '^.\\'
        $AlreadyArchivedFile = ($WriteArchive.Entries | Where-Object {
                (($_.FullName -eq $RelativePath) -and ($_.Length -eq $File.Length) )  -and 
                ([math]::Abs(($_.LastWriteTime.UtcDateTime - $File.LastWriteTimeUtc).Seconds) -le 2) 
            })     
        If($AlreadyArchivedFile -eq $null){
            If($Verbose){Write-Host "Archiving $RelativePath $($File.LastWriteTimeUtc -f "yyyyMMdd-HHmmss") $($File.Length)" }
            Try{
                $ArchivedFile = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($WriteArchive, $File.FullName, $RelativePath, $CompressionLevel)
            }Catch{
                Write-Warning  "$($File.FullName) could not be archived. `n $($_.Exception.Message)"  
                $skipped += [psobject]@{Path=$file.FullName; Reason=$_.Exception.Message}
            }
            If($File.LastWriteTime.IsDaylightSavingTime() -and $ArchivedFile){ 
                $entry = $WriteArchive.GetEntry($RelativePath)    
                $entry.LastWriteTime = ($File.LastWriteTime.ToLocalTime() - (New-TimeSpan -Hours 1)) 
            }
        }Else{#Write-Warning "$($File.FullName) is already archived$(If($DeleteAfterArchiving){' and will be deleted.'}Else{'. No action taken.'})" 
            Write-Warning "$($File.FullName) is already archived - No action taken." 
            $skipped += [psobject]@{Path=$file.FullName; Reason="Already archived"}
        }
        If((($ArchivedFile -ne $null) -and ($ArchivedFile.FullName -eq $RelativePath)) -and $DeleteAfterArchiving) { 
            Try {
                Remove-Item $File.FullName -Verbose:$Verbose
            }Catch{
                Write-Warning "$($File.FullName) could not be deleted. `n $($_.Exception.Message)"
            }
        } 
        $countdown = $countdown - 1
        $processedCount++
    }
}Catch [Exception]{
    Write-Error $_.Exception
}Finally{
    $WriteArchive.Dispose() 
    Write-Host "Sent $($totalcount - $countdown - $($skipped.Count)) of $totalcount files to archive: $ZipPath"
    $skipped | Format-Table -Autosize -Wrap
}
Pop-Location