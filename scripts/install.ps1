# <#
.SYNOPSIS
    Instalador Oficial de Antigravity Zero-Token Suite para Windows (PowerShell)
.DESCRIPTION
    Copia las 8 skills optimizadoras a la carpeta de configuración de Antigravity
    en el perfil del usuario ($HOME\.gemini\config\skills) y actualiza AGENTS.md.
#>

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   🚀 Instalador Oficial: Antigravity Zero-Token Suite " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

$ConfigDir = Join-Path $HOME ".gemini\config"
$TargetSkillsDir = Join-Path $ConfigDir "skills"
$RulesFile = Join-Path $ConfigDir "AGENTS.md"

Write-Host "[1/4] Preparando directorios en Windows..." -ForegroundColor Yellow
if (-not (Test-Path $TargetSkillsDir)) {
    New-Item -ItemType Directory -Force -Path $TargetSkillsDir | Out-Null
}
Write-Host "  ✓ Directorio listo: $TargetSkillsDir" -ForegroundColor Green

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceSkillsDir = Join-Path $ScriptDir "..\skills"
if (-not (Test-Path $SourceSkillsDir)) {
    $SourceSkillsDir = Join-Path $ScriptDir "skills"
}

Write-Host "`n[2/4] Instalando las 8 Skills Optimizadoras a 0 Tokens..." -ForegroundColor Yellow
$Skills = @(
    "pdf-analysis-optimizer",
    "office-files-optimizer",
    "html-parser-optimizer",
    "audio-transcription-optimizer",
    "video-analysis-optimizer",
    "archive-inspector-optimizer",
    "ocr-image-optimizer",
    "web-background-automation"
)

foreach ($skill in $Skills) {
    $src = Join-Path $SourceSkillsDir $skill
    $dst = Join-Path $TargetSkillsDir $skill
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $TargetSkillsDir -Recurse -Force
        Write-Host "  ✓ Instalada: $skill" -ForegroundColor Green
    } else {
        Write-Host "  ✗ No se encontró: $skill" -ForegroundColor Red
    }
}

Write-Host "`n[3/4] Configurando reglas de enrutamiento automático..." -ForegroundColor Yellow
$RulesSource = Join-Path $ScriptDir "..\rules\token_optimization_rules.md"
if (-not (Test-Path $RulesSource)) {
    $RulesSource = Join-Path $ScriptDir "rules\token_optimization_rules.md"
}

if (Test-Path $RulesSource) {
    if (-not (Test-Path $RulesFile)) {
        New-Item -ItemType File -Force -Path $RulesFile | Out-Null
    }
    $rulesContent = Get-Content -Path $RulesFile -Raw -ErrorAction SilentlyContinue
    if ($rulesContent -notmatch "Filosofía de Consumo de Tokens") {
        Add-Content -Path $RulesFile -Value "`n`n"
        Get-Content -Path $RulesSource | Add-Content -Path $RulesFile
        Write-Host "  ✓ Reglas inyectadas en $RulesFile" -ForegroundColor Green
    } else {
        Write-Host "  ℹ Las reglas ya existen en $RulesFile. Omitiendo." -ForegroundColor Cyan
    }
}

Write-Host "`n[4/4] Verificando dependencias..." -ForegroundColor Yellow
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Python detectado" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Python no detectado en PATH." -ForegroundColor Yellow
}

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ uv detectado" -ForegroundColor Green
} else {
    Write-Host "  ℹ uv no detectado. Instálalo con: powershell -c ""irm https://astral.sh/uv/install.ps1 | iex""" -ForegroundColor Cyan
}

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "  🎉 ¡Instalación Completada con Éxito en Windows!   " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
