# Draws the app icon (a white serif "S" on a blue tile, with a green cursor for Focus Mode)
# and saves assets\icon.ico with sizes from 16 to 256 pixels. Run it again only if you change the design.
Add-Type -AssemblyName System.Drawing
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $here '..\assets\icon.ico'

function Draw-Icon([int]$size) {
    $k = $size / 32.0
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    # Rounded blue tile
    $r = New-Object System.Drawing.RectangleF (1 * $k), (1 * $k), (30 * $k), (30 * $k)
    $d = 12 * $k
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($r.X, $r.Y, $d, $d, 180, 90)
    $p.AddArc($r.Right - $d, $r.Y, $d, $d, 270, 90)
    $p.AddArc($r.Right - $d, $r.Bottom - $d, $d, $d, 0, 90)
    $p.AddArc($r.X, $r.Bottom - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    $lg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $r, ([System.Drawing.Color]::FromArgb(58, 108, 182)), ([System.Drawing.Color]::FromArgb(30, 66, 122)), 90.0
    $g.FillPath($lg, $p)

    # White serif S, drawn as a path so it stays crisp at every size
    $font = New-Object System.Drawing.FontFamily 'Georgia'
    $sp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $box = New-Object System.Drawing.RectangleF (0 * $k), (0.5 * $k), (30 * $k), (30 * $k)
    $sp.AddString('S', $font, [int][System.Drawing.FontStyle]::Bold, (24 * $k), $box, $fmt)
    $g.FillPath([System.Drawing.Brushes]::White, $sp)

    # Green cursor, bottom right
    $green = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(51, 255, 102))
    $g.FillRectangle($green, (22.5 * $k), (24 * $k), (5 * $k), [math]::Max(1, 2 * $k))
    $g.Dispose()
    return $bmp
}

# The 256 size is stored as a PNG; smaller sizes as plain bitmaps, which every Windows icon reader understands
function Icon-Bitmap([System.Drawing.Bitmap]$b) {
    $s = $b.Width
    $rect = New-Object System.Drawing.Rectangle 0, 0, $s, $s
    $data = $b.LockBits($rect, 'ReadOnly', ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb))
    $pixels = New-Object byte[] ($s * $s * 4)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $pixels.Length)
    $b.UnlockBits($data)
    $maskRow = [int]([math]::Ceiling($s / 32.0) * 4)
    $ms = New-Object System.IO.MemoryStream
    $w = New-Object System.IO.BinaryWriter $ms
    $w.Write([uint32]40); $w.Write([int32]$s); $w.Write([int32]($s * 2))
    $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]0)
    $w.Write([uint32]($s * $s * 4 + $maskRow * $s)); $w.Write([int32]0); $w.Write([int32]0); $w.Write([uint32]0); $w.Write([uint32]0)
    for ($y = $s - 1; $y -ge 0; $y--) { $w.Write($pixels, $y * $s * 4, $s * 4) }
    $w.Write((New-Object byte[] ($maskRow * $s)))
    $w.Flush()
    return , $ms.ToArray()
}

$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($s in $sizes) {
    $b = Draw-Icon $s
    if ($s -ge 256) {
        $ms = New-Object System.IO.MemoryStream
        $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $ms.ToArray()
    } else { $bytes = Icon-Bitmap $b }
    $b.Dispose()
    , $bytes
}

$fs = [System.IO.File]::Create($out)
$w = New-Object System.IO.BinaryWriter $fs
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $dim = if ($s -ge 256) { 0 } else { $s }
    $w.Write([byte]$dim); $w.Write([byte]$dim); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]1); $w.Write([uint16]32)
    $w.Write([uint32]$pngs[$i].Length); $w.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($png in $pngs) { $w.Write($png) }
$w.Close()
Write-Host "Saved $((Resolve-Path $out).Path)"
