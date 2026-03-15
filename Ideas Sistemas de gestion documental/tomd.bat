@echo off
setlocal

set "TARGET_DIR=%~1"
if not defined TARGET_DIR set "TARGET_DIR=%CD%"

where pandoc >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No se encontro pandoc en el PATH.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {" ^
  "param([string]$TargetDir)" ^
  "$ErrorActionPreference = 'Stop'" ^
  "$hasPdfToText = [bool](Get-Command pdftotext -ErrorAction SilentlyContinue)" ^
  "$hasPython = [bool](Get-Command python -ErrorAction SilentlyContinue)" ^
  "$hasPyPdf = $false" ^
  "if ($hasPython) {" ^
  "  & python '-c' 'import pypdf' 2>$null" ^
  "  if ($LASTEXITCODE -eq 0) { $hasPyPdf = $true }" ^
  "}" ^
  "if (-not $hasPdfToText -and -not $hasPyPdf) {" ^
  "  throw 'No se encontro un extractor PDF compatible. Instala pdftotext o python con pypdf.'" ^
  "}" ^
  "if (-not (Test-Path -LiteralPath $TargetDir)) { throw ('El directorio no existe: ' + $TargetDir) }" ^
  "$pdfFiles = Get-ChildItem -LiteralPath $TargetDir -Filter *.pdf -File | Sort-Object Name" ^
  "if (-not $pdfFiles) { Write-Host '[INFO] No se encontraron archivos PDF.'; exit 0 }" ^
  "if ($hasPdfToText) { Write-Host '[INFO] Extraccion: pdftotext' } elseif ($hasPyPdf) { Write-Host '[INFO] Extraccion: python + pypdf' }" ^
  "foreach ($pdf in $pdfFiles) {" ^
  "  $tempText = Join-Path $env:TEMP (([System.IO.Path]::GetRandomFileName()) + '.txt')" ^
  "  $outputMd = [System.IO.Path]::ChangeExtension($pdf.FullName, '.md')" ^
  "  try {" ^
  "    if ($hasPdfToText) {" ^
  "      & pdftotext -enc UTF-8 -layout -- $pdf.FullName $tempText" ^
  "      if ($LASTEXITCODE -ne 0) { throw ('pdftotext fallo con ' + $pdf.Name) }" ^
  "    } else {" ^
  "      & python '-c' 'from pathlib import Path; from pypdf import PdfReader; import sys; pdf_path, out_path = sys.argv[1], sys.argv[2]; reader = PdfReader(pdf_path); text = ''\n\n''.join((page.extract_text() or '''') for page in reader.pages); Path(out_path).write_text(text, encoding=''utf-8'')' $pdf.FullName $tempText" ^
  "      if ($LASTEXITCODE -ne 0) { throw ('python/pypdf fallo con ' + $pdf.Name) }" ^
  "    }" ^
  "    & pandoc --from=plain --to=gfm --wrap=none --output $outputMd $tempText" ^
  "    if ($LASTEXITCODE -ne 0) { throw ('pandoc fallo con ' + $pdf.Name) }" ^
  "    Write-Host ('[OK] ' + $pdf.Name + ' -> ' + [System.IO.Path]::GetFileName($outputMd))" ^
  "  } finally {" ^
  "    Remove-Item -LiteralPath $tempText -ErrorAction SilentlyContinue" ^
  "  }" ^
  "}" ^
  "}" "%TARGET_DIR%"

exit /b %ERRORLEVEL%
