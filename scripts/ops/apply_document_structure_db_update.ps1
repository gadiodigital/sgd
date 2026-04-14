param(
    [string]$ComposeRoot = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path ""),
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseName = "gdms",
    [string]$DatabaseUser = "gdms",
    [string]$SqlScriptPath = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "database\scripts\020_document_structure_hierarchy.sql"),
    [switch]$SkipVerification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-DockerComposeChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [string]$InputText = "",
        [switch]$SuppressOutput
    )

    Push-Location $ComposeRoot
    try {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            if ([string]::IsNullOrEmpty($InputText)) {
                $output = & docker compose @ArgumentList 2>&1
            }
            else {
                $output = $InputText | & docker compose @ArgumentList 2>&1
            }
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $exitCode = $LASTEXITCODE
        if ($output -and -not $SuppressOutput) {
            $output | ForEach-Object { Write-Host $_ }
        }

        if ($exitCode -ne 0) {
            throw "docker compose $($ArgumentList -join ' ') fallo con codigo $exitCode."
        }

        return $output
    }
    finally {
        Pop-Location
    }
}

$resolvedComposeRoot = [System.IO.Path]::GetFullPath($ComposeRoot)
$resolvedSqlScriptPath = [System.IO.Path]::GetFullPath($SqlScriptPath)
$ComposeRoot = $resolvedComposeRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "No se encontro docker en PATH."
}

if (-not (Test-Path -LiteralPath $resolvedSqlScriptPath)) {
    throw "No existe el script SQL: $resolvedSqlScriptPath"
}

$containerId = (Invoke-DockerComposeChecked -ArgumentList @("ps", "-q", $PostgresServiceName) -SuppressOutput | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace("$containerId")) {
    throw "El servicio '$PostgresServiceName' no esta levantado. Ejecutar docker compose up -d postgres."
}

Write-Host "Aplicando migracion de estructura documental..."
Write-Host " - ComposeRoot: $resolvedComposeRoot"
Write-Host " - Servicio PostgreSQL: $PostgresServiceName"
Write-Host " - Base: $DatabaseName"
Write-Host " - Script: $resolvedSqlScriptPath"

$sql = Get-Content -Raw -LiteralPath $resolvedSqlScriptPath
Invoke-DockerComposeChecked -ArgumentList @(
    "exec",
    "-T",
    $PostgresServiceName,
    "psql",
    "-U",
    $DatabaseUser,
    "-d",
    $DatabaseName,
    "-v",
    "ON_ERROR_STOP=1"
) -InputText $sql | Out-Null

if (-not $SkipVerification) {
    Write-Host "Verificando objetos creados..."
    $verificationSql = @"
WITH expected_tables(schema_name, table_name) AS (
    VALUES
        ('documents', 'projects'),
        ('configuration', 'container_types'),
        ('configuration', 'container_type_rules'),
        ('documents', 'containers'),
        ('documents', 'container_documents')
),
found_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE (table_schema, table_name) IN (SELECT schema_name, table_name FROM expected_tables)
),
expected_functions(schema_name, function_name) AS (
    VALUES
        ('documents', 'validate_container_hierarchy'),
        ('documents', 'validate_container_document_link')
),
found_functions AS (
    SELECT n.nspname AS schema_name, p.proname AS function_name
    FROM pg_proc p
    INNER JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE (n.nspname, p.proname) IN (SELECT schema_name, function_name FROM expected_functions)
),
expected_triggers(trigger_name) AS (
    VALUES
        ('trg_validate_container_hierarchy'),
        ('trg_validate_container_document_link')
),
found_triggers AS (
    SELECT tgname AS trigger_name
    FROM pg_trigger
    WHERE NOT tgisinternal
      AND tgname IN (SELECT trigger_name FROM expected_triggers)
)
SELECT
    (SELECT count(*) FROM found_tables) AS found_tables,
    (SELECT count(*) FROM expected_tables) AS expected_tables,
    (SELECT count(*) FROM found_functions) AS found_functions,
    (SELECT count(*) FROM expected_functions) AS expected_functions,
    (SELECT count(*) FROM found_triggers) AS found_triggers,
    (SELECT count(*) FROM expected_triggers) AS expected_triggers;
"@

    $verificationOutput = Invoke-DockerComposeChecked -ArgumentList @(
        "exec",
        "-T",
        $PostgresServiceName,
        "psql",
        "-U",
        $DatabaseUser,
        "-d",
        $DatabaseName,
        "-t",
        "-A",
        "-F",
        "|",
        "-v",
        "ON_ERROR_STOP=1",
        "-c",
        $verificationSql
    )

    $summaryLine = ($verificationOutput | Where-Object { $_ -match '^\d+\|\d+\|\d+\|\d+\|\d+\|\d+$' } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace("$summaryLine")) {
        throw "No se pudo interpretar la verificacion de objetos PostgreSQL."
    }

    $parts = "$summaryLine".Split("|")
    $foundTables = [int]$parts[0]
    $expectedTables = [int]$parts[1]
    $foundFunctions = [int]$parts[2]
    $expectedFunctions = [int]$parts[3]
    $foundTriggers = [int]$parts[4]
    $expectedTriggers = [int]$parts[5]

    if (
        $foundTables -ne $expectedTables -or
        $foundFunctions -ne $expectedFunctions -or
        $foundTriggers -ne $expectedTriggers
    ) {
        throw "Verificacion incompleta. Tablas $foundTables/$expectedTables, funciones $foundFunctions/$expectedFunctions, triggers $foundTriggers/$expectedTriggers."
    }

    Write-Host "Verificacion OK. Tablas $foundTables/$expectedTables, funciones $foundFunctions/$expectedFunctions, triggers $foundTriggers/$expectedTriggers."
}

Write-Host "Actualizacion de estructura documental aplicada correctamente."
