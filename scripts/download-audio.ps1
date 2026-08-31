<#
.SYNOPSIS
    Downloads full Quran audio (114 surahs, 6236 ayahs) for 4 reciters from EveryAyah.com.

.DESCRIPTION
    Downloads per-ayah MP3 files into the audio/ folder with progress, retries, and resume.
    Existing files are skipped (resume-safe). ~4GB total.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1 -Reciters muaiqly,afasy
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1 -Surah 2
    powershell -ExecutionPolicy Bypass -File scripts/download-audio.ps1 -Force
#>
param(
    [string[]]$Reciters = @('muaiqly', 'afasy', 'shuraim', 'basit'),
    [int]$Surah = 0,
    [int]$Retries = 3,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$BaseUrl   = 'https://www.everyayah.com/data'
$AudioRoot = Join-Path (Join-Path $PSScriptRoot '..') 'audio'

$RecitersCfg = @{}
$RecitersCfg['muaiqly'] = @{ Dir = 'ar.mahermuaiqly'; Folder = 'MaherAlMuaiqly128kbps'; }
$RecitersCfg['afasy']   = @{ Dir = 'ar.alafasy';       Folder = 'Alafasy_128kbps'; }
$RecitersCfg['shuraim'] = @{ Dir = 'ar.shuraim';       Folder = 'Saood_ash-Shuraym_128kbps'; }
$RecitersCfg['basit']   = @{ Dir = 'ar.abdulbasit';    Folder = 'Abdul_Basit_Murattal_192kbps'; }

$AyahCounts = @(
    7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
    112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,
    59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,
    52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,
    21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
)

function Format-Size([long]$Bytes) {
    if ($Bytes -ge 1GB) { return ([string]::Format('{0:N2} GB', $Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ([string]::Format('{0:N1} MB', $Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ([string]::Format('{0:N0} KB', $Bytes / 1KB)) }
    return "$Bytes B"
}

function Format-Duration([double]$Sec) {
    $ts = [TimeSpan]::FromSeconds([Math]::Max(0, $Sec))
    if ($ts.TotalHours -ge 1) { return $ts.ToString('hh\:mm\:ss') }
    return $ts.ToString('mm\:ss')
}

function Draw-Bar([double]$Pct) {
    $width = 35
    $filled = [Math]::Round($Pct / 100 * $width)
    if ($filled -gt $width) { $filled = $width }
    $empty = $width - $filled
    $bar = ('#' * $filled) + ('-' * $empty)
    return "[$bar]"
}

# Build work list
$surahRange = if ($Surah -gt 0) { ,($Surah) } else { 1..114 }
$work = @()
foreach ($r in $Reciters) {
    if (-not $RecitersCfg.ContainsKey($r)) {
        Write-Host "  WARNING: Unknown reciter '$r' - skipping (available: muaiqly, afasy, shuraim, basit)" -ForegroundColor Yellow
        continue
    }
    foreach ($s in $surahRange) {
        $count = $AyahCounts[$s - 1]
        for ($a = 1; $a -le $count; $a++) {
            $work += @{ Reciter = $r; Surah = $s; Ayah = $a }
        }
    }
}

if ($work.Count -eq 0) {
    Write-Host "  No work to do. Check your -Reciters and -Surah parameters." -ForegroundColor Red
    exit 1
}

$totalFiles  = $work.Count
$doneCount   = 0
$skipCount   = 0
$dlCount     = 0
$failCount   = 0
$totalBytes  = [long]0
$startTime   = Get-Date
$failedItems = @()

# Header
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "   Sabeel Quran Audio Downloader" -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Reciters:   $($Reciters -join ', ')" -ForegroundColor White
if ($Surah -gt 0) {
    Write-Host "  Surah:      $Surah ($($AyahCounts[$Surah-1]) ayahs)" -ForegroundColor White
} else {
    Write-Host "  Surahs:     All 114 (6,236 ayahs per reciter)" -ForegroundColor White
}
Write-Host "  Total:      $totalFiles files" -ForegroundColor White
Write-Host "  Retries:    $Retries per file" -ForegroundColor White
Write-Host ""
Write-Host "  Tip: Test with -Surah 1 first to verify everything works." -ForegroundColor DarkGray
Write-Host ""

# Main download loop
for ($i = 0; $i -lt $totalFiles; $i++) {
    $item = $work[$i]
    $cfg  = $RecitersCfg[$item.Reciter]
    $dir  = Join-Path $AudioRoot $cfg.Dir

    # Create reciter directory
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $padS  = $item.Surah.ToString().PadLeft(3, '0')
    $padA  = $item.Ayah.ToString().PadLeft(3, '0')
    $file  = "${padS}${padA}.mp3"
    $out   = Join-Path $dir $file
    $url   = "$BaseUrl/$($cfg.Folder)/$file"

    # Skip if already downloaded
    if (-not $Force -and (Test-Path $out)) {
        $sz = (Get-Item $out).Length
        if ($sz -gt 5000) {
            $skipCount++
            $totalBytes += $sz
            $doneCount++
            # Periodic progress for skips
            if ($doneCount % 500 -eq 0) {
                $pct = [Math]::Round($doneCount / $totalFiles * 100, 1)
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $eta = if ($doneCount -gt 0) { ($elapsed / $doneCount) * ($totalFiles - $doneCount) } else { 0 }
                Write-Host "`r  $(Draw-Bar $pct) $pct%  skip=$skipCount dl=$dlCount fail=$failCount  ETA $(Format-Duration $eta)  " -NoNewline
            }
            continue
        }
    }

    # Download with retries
    $success = $false
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $out)
            $webClient.Dispose()

            $sz = (Get-Item $out).Length
            if ($sz -gt 5000) {
                $totalBytes += $sz
                $dlCount++
                $success = $true
                break
            } else {
                Remove-Item $out -Force -ErrorAction SilentlyContinue
            }
        } catch {
            if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
            if ($attempt -lt $Retries) {
                Start-Sleep -Milliseconds (300 * $attempt)
            }
        }
    }

    if (-not $success) {
        $failCount++
        $failedItems += "$($item.Reciter) surah $($item.Surah) ayah $($item.Ayah)"
    }

    $doneCount++

    # Progress update every 20 downloads
    if ($doneCount % 20 -eq 0 -or $i -eq ($totalFiles - 1)) {
        $pct     = [Math]::Round($doneCount / $totalFiles * 100, 1)
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $speed   = if ($elapsed -gt 0 -and $dlCount -gt 0) { $totalBytes / $elapsed } else { 0 }
        $eta     = if ($doneCount -gt 0) { ($elapsed / $doneCount) * ($totalFiles - $doneCount) } else { 0 }

        $speedStr = Format-Size([long]$speed) + '/s'
        Write-Host "`r  $(Draw-Bar $pct) $pct%  dl=$dlCount skip=$skipCount fail=$failCount  $speedStr  ETA $(Format-Duration $eta)   " -NoNewline
    }
}

# Final newline after progress bar
Write-Host ""
Write-Host ""

# Summary
$elapsed = ((Get-Date) - $startTime).TotalSeconds
Write-Host "  ========================================" -ForegroundColor Green
Write-Host "   Done!" -ForegroundColor Green
Write-Host "  ========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Time:       $(Format-Duration $elapsed)" -ForegroundColor White
Write-Host "  Downloaded: $dlCount files ($(Format-Size $totalBytes))" -ForegroundColor White
Write-Host "  Skipped:    $skipCount (already existed)" -ForegroundColor White
if ($failCount -gt 0) {
    Write-Host "  Failed:     $failCount" -ForegroundColor Yellow
} else {
    Write-Host "  Failed:     0" -ForegroundColor Green
}

# Per-reciter breakdown
Write-Host ""
Write-Host "  Per-reciter:" -ForegroundColor Cyan
foreach ($r in $Reciters) {
    $cfg = $RecitersCfg[$r]
    $dir = Join-Path $AudioRoot $cfg.Dir
    if (Test-Path $dir) {
        $mp3s  = Get-ChildItem $dir -Filter '*.mp3' -ErrorAction SilentlyContinue
        $count = 0
        $size  = [long]0
        foreach ($f in $mp3s) { $count++; $size += $f.Length }
        $pct   = [Math]::Round($count / 6236.0 * 100, 1)
        if ($count -eq 6236) {
            Write-Host "    $($cfg.Dir):  $count / 6236 ($pct%)  $(Format-Size $size)" -ForegroundColor Green
        } elseif ($count -gt 0) {
            Write-Host "    $($cfg.Dir):  $count / 6236 ($pct%)  $(Format-Size $size)" -ForegroundColor Yellow
        } else {
            Write-Host "    $($cfg.Dir):  0 / 6236" -ForegroundColor Red
        }
    } else {
        Write-Host "    $($cfg.Dir):  folder not created" -ForegroundColor Red
    }
}

# List failures
if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "  Failed files (first 20):" -ForegroundColor Yellow
    $show = $failedItems
    if ($failedItems.Count -gt 20) { $show = $failedItems[0..19] }
    foreach ($f in $show) {
        Write-Host "    $f" -ForegroundColor Yellow
    }
    if ($failedItems.Count -gt 20) {
        Write-Host "    ... and $($failedItems.Count - 20) more" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  Re-run the script to retry. Existing files are skipped automatically." -ForegroundColor DarkGray
}

Write-Host ""
