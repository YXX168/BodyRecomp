param(
    [string]$Source = (Join-Path $PSScriptRoot '..\assets\branding\bodyrecomp-icon.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resRoot = Join-Path $repoRoot 'android\app\src\main\res'
$sourceBitmap = [Drawing.Bitmap]::FromFile((Resolve-Path $Source))
$background = [Drawing.Color]::FromArgb(255, 3, 17, 38)

function New-Canvas([int]$size, [bool]$transparent) {
    $bitmap = New-Object Drawing.Bitmap $size, $size, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear($(if ($transparent) { [Drawing.Color]::Transparent } else { $background }))
    return @($bitmap, $graphics)
}

function Save-LegacyIcon([string]$path, [int]$size) {
    $canvas = New-Canvas $size $false
    $bitmap, $graphics = $canvas
    $inset = [Math]::Round($size * 0.07)
    $artSize = $size - (2 * $inset)
    $graphics.DrawImage($sourceBitmap, $inset, $inset, $artSize, $artSize)
    $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-RoundIcon([string]$path, [int]$size) {
    $canvas = New-Canvas $size $true
    $bitmap, $graphics = $canvas
    $clip = New-Object Drawing.Drawing2D.GraphicsPath
    $clip.AddEllipse(0, 0, $size, $size)
    $graphics.SetClip($clip)
    $graphics.Clear($background)
    $inset = [Math]::Round($size * 0.10)
    $artSize = $size - (2 * $inset)
    $graphics.DrawImage($sourceBitmap, $inset, $inset, $artSize, $artSize)
    $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $clip.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-Foreground([string]$path, [int]$size) {
    $canvas = New-Canvas $size $true
    $bitmap, $graphics = $canvas
    $inset = [Math]::Round($size * 0.19)
    $artSize = $size - (2 * $inset)
    $graphics.DrawImage($sourceBitmap, $inset, $inset, $artSize, $artSize)
    $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

$densities = @{
    'mdpi' = @{ legacy = 48; adaptive = 108 }
    'hdpi' = @{ legacy = 72; adaptive = 162 }
    'xhdpi' = @{ legacy = 96; adaptive = 216 }
    'xxhdpi' = @{ legacy = 144; adaptive = 324 }
    'xxxhdpi' = @{ legacy = 192; adaptive = 432 }
}

foreach ($entry in $densities.GetEnumerator()) {
    $folder = Join-Path $resRoot ('mipmap-' + $entry.Key)
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    Save-LegacyIcon (Join-Path $folder 'ic_launcher.png') $entry.Value.legacy
    Save-RoundIcon (Join-Path $folder 'ic_launcher_round.png') $entry.Value.legacy
    Save-Foreground (Join-Path $folder 'ic_launcher_foreground.png') $entry.Value.adaptive
}

$sourceBitmap.Dispose()
