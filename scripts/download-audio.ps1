<#
.SYNOPSIS
    Downloads full Quran audio (114 surahs, 6236 ayahs) for 4 reciters from EveryAyah.com.

.DESCRIPTION
    Downloads per-ayah MP3 files into the audio/ folder:
      audio/ar.mahermuaiqly/   (128kbps)
      audio/ar.alafasy/        (128kbps)
      audio/ar.shuraim/        (128kbps)
      audio/ar.abdulbasit/     (192kbps)

    Files are named SSSAAA.mp3 (e.g. 001001.mp3 = Surah 1, Ayah 1).
    Skips files that already exist (resume-safe). ~4GB total.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1 -Reciters muaiqly,afasy
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1 -Surah 1
#>
param(
    [string[]]$Reciters = @('muaiqly', 'afasy', 'shuraim', 'basit'),
    [int]$Surah = 0,         # 0 = all surahs
    [int]$Parallel = 4,      # concurrent downloads
    [switch]$Force            # re-download even if file exists
)

$ErrorActionPreference = 'Stop'

# Reciter config: key → @{ Dir; Folder; Quality }
$ReciterMap = @{
    muaiqly = @{ Dir = 'ar.mahermuaiqly';  Folder = 'MaherAlMuaiqly128kbps';  Quality = '128kbps' }
    afasy   = @{ Dir = 'ar.alafasy';       Folder = 'Alafasy_128kbps';         Quality = '128kbps' }
    shuraim = @{ Dir = 'ar.shuraim';       Folder = 'Saood_ash-Shuraym_128kbps'; Quality = '128kbps' }
    basit   = @{ Dir = 'ar.abdulbasit';    Folder = 'Abdul_Basit_Murattal_192kbps'; Quality = '192kbps' }
}

# Ayah counts per surah (index 0 = Surah 1)
$AyahCounts = @(7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6)

$BaseUrl = 'https://www.everyayah.com/data'
$AudioRoot = Join-Path $PSScriptRoot '..' 'audio'

function Get-FileSize($path) {
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -gt 1MB) { return "{0:N1} MB" -f ($size / 1MB) }
        return "{0:N0} KB" -f ($size / 1KB)
    }
    return '0 B'
}

function Download-Ayah($reciterKey, $surahNum, $ayahNum) {
    $info = $ReciterMap[$reciterKey]
    $dir = Join-Path $AudioRoot $info.Dir
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $padSurah = $surahNum.ToString().PadLeft(3, '0')
    $padAyah  = $ayahNum.ToString().PadLeft(3, '0')
    $filename = "${padSurah}${padAyah}.mp3"
    $outPath  = Join-Path $dir $filename

    if (!$Force -and (Test-Path $outPath)) { return 'skip' }

    $url = "$BaseUrl/$($info.Folder)/$filename"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing -TimeoutSec 30
        return 'ok'
    } catch {
        if (Test-Path $outPath) { Remove-Item $outPath -Force }
        return 'fail'
    }
}

# Build work list
$work = @()
$surahRange = if ($Surah -gt 0) { @($Surah) } else { 1..114 }
foreach ($s in $surahRange) {
    $count = $AyahCounts[$s - 1]
    foreach ($a in 1..$count) {
        foreach ($r in $Reciters) {
            $work += @{ Reciter = $r; Surah = $s; Ayah = $a }
        }
    }
}

$total = $work.Count
$done  = 0
$skip  = 0
$ok    = 0
$fail  = 0
$startTime = Get-Date

Write-Host "`n=== Sabeel Quran Audio Downloader ===" -ForegroundColor Cyan
Write-Host "Reciters: $($Reciters -join ', ')"
Write-Host "Surahs:   $(if ($Surah -gt 0) { "Surah $Surah" } else { "All 114 surahs" })"
Write-Host "Files:    $total MP3s to download"
Write-Host "Parallel: $Parallel concurrent downloads`n"

# Process in batches
for ($i = 0; $i -lt $total; $i += $Parallel) {
    $batch = $work[$i..([Math]::Min($i + $Parallel - 1, $total - 1))]
    $jobs = $batch | ForEach-Object {
        $r = $_.Reciter; $s = $_.Surah; $a = $_.Ayah
        [PSCustomObject]@{
            Reciter = $r; Surah = $s; Ayah = $a
            Result  = (Download-Ayah $r $s $a)
        }
    }
    foreach ($j in $jobs) {
        $done++
        switch ($j.Result) {
            'skip' { $skip++ }
            'ok'   { $ok++ }
            'fail' { $fail++ }
        }
    }
    $pct  = [Math]::Round(($done / $total) * 100, 1)
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $eta = if ($done -gt 0) { [Math]::Round(($elapsed / $done) * ($total - $done)) } else { 0 }
    Write-Progress -Activity "Downloading Quran audio" -Status "$done / $total ($pct%) — ETA: $([Math]::Round($eta))s — OK: $ok | Skip: $skip | Fail: $fail" -PercentComplete $pct
}

Write-Progress -Activity "Downloading Quran audio" -Completed

$elapsed = ((Get-Date) - $startTime).ToString('mm\:ss')
Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Time:    $elapsed"
Write-Host "Total:   $total files"
Write-Host "Skipped: $skip (already exist)"
Write-Host "Downloaded: $ok"
Write-Host "Failed:  $fail"

if ($fail -gt 0) {
    Write-Host "`nSome files failed. Re-run the script to retry (existing files are skipped)." -ForegroundColor Yellow
}

# Summary per reciter
Write-Host "`nPer-reciter summary:" -ForegroundColor Cyan
foreach ($r in $Reciters) {
    $info = $ReciterMap[$r]
    $dir = Join-Path $AudioRoot $info.Dir
    if (Test-Path $dir) {
        $count = (Get-ChildItem $dir -Filter '*.mp3').Count
        Write-Host "  $($info.Dir): $count / 6236 ayahs"
    }
}
