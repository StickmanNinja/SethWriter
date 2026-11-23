# Builds build\Writer-Setup.exe (installer and app in one) with the C# compiler that comes with Windows. Nothing to install.
# The editor (app\Writer.html) is packed inside the exe as a complete web page.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }

# 1. Wrap the editor in a full HTML document (doctype, UTF-8, viewport and a small reset)
$build = Join-Path $here 'build'
New-Item -ItemType Directory -Force $build | Out-Null
$body = [System.IO.File]::ReadAllText((Join-Path $here 'app\Writer.html'), [System.Text.Encoding]::UTF8)
$head = '<!doctype html><html lang="en"><head><meta charset="utf-8">' +
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">' +
        '<style>:root{color-scheme:light}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>' +
        '</head><body>'
$page = Join-Path $build 'Writer.html'
[System.IO.File]::WriteAllText($page, $head + "`n" + $body + "`n</body></html>`n", (New-Object System.Text.UTF8Encoding $false))

# 2. Compile the launcher with the page packed inside
& $csc /nologo /target:winexe /optimize+ `
    /reference:System.Windows.Forms.dll `
    "/win32icon:$here\assets\icon.ico" "/win32manifest:$here\assets\app.manifest" `
    "/resource:$page,Writer.html" `
    "/out:$build\Writer-Setup.exe" "$here\launcher\Program.cs"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Built $build\Writer-Setup.exe"
