# Draws DreamFTP's icon and banner: a purple crescent on near-black.
# Run on Windows: powershell -ExecutionPolicy Bypass -File tools/make-art.ps1
# Writes meta/icon.png (48 x 48) and meta/banner.png (256 x 128).

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$icon = Join-Path $root 'meta\icon.png'
$banner = Join-Path $root 'meta\banner.png'
$fontFile = Join-Path $root 'assets\fonts\fredoka\Fredoka-Bold.ttf'

$bg = [System.Drawing.ColorTranslator]::FromHtml('#050308')
$ink = [System.Drawing.ColorTranslator]::FromHtml('#f4eefc')
$accent = [System.Drawing.ColorTranslator]::FromHtml('#b98cff')
$moonFrom = [System.Drawing.ColorTranslator]::FromHtml('#e9d5ff')
$moonTo = [System.Drawing.ColorTranslator]::FromHtml('#7c3aed')
$glow = [System.Drawing.ColorTranslator]::FromHtml('#6d28d9')

$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile($fontFile)
$family = $fonts.Families[0]

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return @($bmp, $g)
}

# a purple haze behind the moon; alpha fades out from the centre
function Add-Glow($g, [single]$cx, [single]$cy, [single]$r, [int]$alpha) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse($cx - $r, $cy - $r, 2 * $r, 2 * $r)
    $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $brush.CenterPoint = New-Object System.Drawing.PointF($cx, $cy)
    $brush.CenterColor = [System.Drawing.Color]::FromArgb($alpha, $glow)
    $brush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, $glow))
    $g.FillPath($brush, $path)
    $brush.Dispose()
    $path.Dispose()
}

# the crescent: one ellipse with another cut out of it (even-odd fill)
function Add-Moon($g, [single]$cx, [single]$cy, [single]$r, [single]$cut, [single]$dx, [single]$dy) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.FillMode = [System.Drawing.Drawing2D.FillMode]::Alternate
    $path.AddEllipse($cx - $r, $cy - $r, 2 * $r, 2 * $r)
    $path.AddEllipse($cx + $dx - $cut, $cy + $dy - $cut, 2 * $cut, 2 * $cut)
    $rect = New-Object System.Drawing.RectangleF(($cx - $r), ($cy - $r), (2 * $r), (2 * $r))
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, $moonFrom, $moonTo,
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
    $g.FillPath($brush, $path)
    $brush.Dispose()
    $path.Dispose()
}

function Save-Png($bmp, [string]$path, [int]$w, [int]$h, $format) {
    $out = New-Object System.Drawing.Bitmap($w, $h, $format)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($bmp, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)))
    $g.Dispose()
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

# --- icon: 384 px, scaled to 48 -------------------------------------------------
$size = 384
$pair = New-Canvas $size $size
$bmp = $pair[0]; $g = $pair[1]
$g.Clear($bg)

# a quiet rounded tile, like the HOME menu's own corners
$tile = New-Object System.Drawing.Drawing2D.GraphicsPath
$inset = 10.0
$rad = 84.0
$d = 2 * $rad
$rect = New-Object System.Drawing.RectangleF($inset, $inset, ($size - 2 * $inset), ($size - 2 * $inset))
$tile.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$tile.AddArc(($rect.Right - $d), $rect.Y, $d, $d, 270, 90)
$tile.AddArc(($rect.Right - $d), ($rect.Bottom - $d), $d, $d, 0, 90)
$tile.AddArc($rect.X, ($rect.Bottom - $d), $d, $d, 90, 90)
$tile.CloseFigure()
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 36, 21, 54), 5)
$g.DrawPath($pen, $tile)
$pen.Dispose()
$tile.Dispose()

Add-Glow $g 168 200 172 110
Add-Moon $g 178 192 126 106 46 -38

Save-Png $bmp $icon 48 48 ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g.Dispose(); $bmp.Dispose()

# --- banner: 1024 px, scaled to 256 x 128 ---------------------------------------
$w = 1024; $h = 512
$pair = New-Canvas $w $h
$bmp = $pair[0]; $g = $pair[1]
$g.Clear($bg)

Add-Glow $g 190 300 420 120

# the same rounded tile as the icon
$tile = New-Object System.Drawing.Drawing2D.GraphicsPath
$inset = 48.0
$rad = 108.0
$d = 2 * $rad
$rect = New-Object System.Drawing.RectangleF($inset, $inset, (416.0), (416.0))
$tile.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$tile.AddArc(($rect.Right - $d), $rect.Y, $d, $d, 270, 90)
$tile.AddArc(($rect.Right - $d), ($rect.Bottom - $d), $d, $d, 0, 90)
$tile.AddArc($rect.X, ($rect.Bottom - $d), $d, $d, 90, 90)
$tile.CloseFigure()
$fill = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0f0918'))
$g.FillPath($fill, $tile)
$fill.Dispose()
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 43, 27, 66), 5)
$g.DrawPath($pen, $tile)
$pen.Dispose()
$tile.Dispose()

Add-Moon $g 246 258 140 118 50 -42

# the wordmark: Dream in white, FTP in purple, shrunk to fit before the right edge
$fontSize = 104.0
do {
    $font = New-Object System.Drawing.Font($family, $fontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = [System.Drawing.StringFormat]::GenericTypographic
    $fmt.FormatFlags = $fmt.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces
    $one = $g.MeasureString('Dream', $font, (New-Object System.Drawing.PointF(0, 0)), $fmt)
    $two = $g.MeasureString('FTP', $font, (New-Object System.Drawing.PointF(0, 0)), $fmt)
    $fits = ($one.Width + $two.Width) -le 456
    if (-not $fits) { $font.Dispose(); $fontSize -= 2 }
} while (-not $fits)
$left = 508.0
$asc = $family.GetCellAscent([System.Drawing.FontStyle]::Regular) / $family.GetEmHeight([System.Drawing.FontStyle]::Regular) * $font.Size
$baseline = ($h / 2.0) + ($asc / 2.0) - 8.0
$g.DrawString('Dream', $font, (New-Object System.Drawing.SolidBrush($ink)), (New-Object System.Drawing.PointF($left, $baseline)), $fmt)
$g.DrawString('FTP', $font, (New-Object System.Drawing.SolidBrush($accent)), (New-Object System.Drawing.PointF(($left + $one.Width), $baseline)), $fmt)

Save-Png $bmp $banner 256 128 ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g.Dispose(); $bmp.Dispose()

"wrote $icon"
"wrote $banner"
