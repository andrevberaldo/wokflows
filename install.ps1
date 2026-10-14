<#
.SYNOPSIS
    Instala o workflow spec-driven em um projeto alvo.
.EXAMPLE
    .\install.ps1 -Target C:\projetos\meu-app
    .\install.ps1 -Target C:\projetos\meu-app -Force
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "Diretório não encontrado: $Target"
    exit 1
}

$Target = (Resolve-Path -LiteralPath $Target).Path
$Src = Join-Path $PSScriptRoot '.claude'
$Dirs = @('agents', 'commands', 'workflow/templates')

$copied = 0
$skipped = 0

foreach ($dir in $Dirs) {
    $srcDir = Join-Path $Src $dir
    Get-ChildItem -LiteralPath $srcDir -Filter '*.md' -File -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($Src.Length).TrimStart('\', '/')
        $dest = Join-Path (Join-Path $Target '.claude') $rel
        $relDisplay = ".claude/" + ($rel -replace '\\', '/')

        if ((Test-Path -LiteralPath $dest) -and -not $Force) {
            Write-Host "pulado (já existe): $relDisplay"
            $script:skipped++
            return
        }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
        Write-Host "instalado: $relDisplay"
        $script:copied++
    }
}

Write-Host "Pronto: $copied instalados, $skipped pulados. Use /feature <descrição> no projeto."
if ($skipped -gt 0) { Write-Host "Use -Force para sobrescrever arquivos existentes." }
