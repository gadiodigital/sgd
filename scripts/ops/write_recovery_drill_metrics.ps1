param(
    [Parameter(Mandatory = $true)]
    [string]$DrillType,
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$MetricsProfile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$MetricsScenario = "local-idle",
    [Parameter(Mandatory = $true)]
    [string]$Status,
    [Parameter(Mandatory = $true)]
    [string]$StartedAtUtc,
    [Parameter(Mandatory = $true)]
    [string]$CompletedAtUtc,
    [int]$SeedFixtureDurationMs = 0,
    [int]$BackupDurationMs = 0,
    [int]$ReprovisionDurationMs = 0,
    [int]$RestoreDurationMs = 0,
    [int]$BusinessIntegrityDurationMs = 0,
    [int]$EvidencePackageDurationMs = 0,
    [int]$SmokeDurationMs = 0,
    [int]$TotalDrillDurationMs = 0,
    [string]$BackupBundlePath = "",
    [string]$BackupCreatedAtUtc = "",
    [string]$TargetDatabaseName = "",
    [string]$TargetStorageRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$repoRoot = Get-RepoRoot
$metricsRoot = Join-Path $repoRoot "artifacts\ops\recovery_metrics"
Ensure-Directory -Path $metricsRoot

$historyPath = Join-Path $metricsRoot "history.jsonl"
$latestJsonPath = Join-Path $metricsRoot "latest.json"
$latestMarkdownPath = Join-Path $metricsRoot "latest.md"

$leadInDurationMs = $SeedFixtureDurationMs + $BackupDurationMs
$recoveryExecutionMs = $ReprovisionDurationMs + $RestoreDurationMs
$validationExecutionMs = $BusinessIntegrityDurationMs + $EvidencePackageDurationMs + $SmokeDurationMs
$rtoObservedMs = $recoveryExecutionMs + $validationExecutionMs
$rpoObservedMs = 0

if (-not [string]::IsNullOrWhiteSpace($BackupCreatedAtUtc)) {
    $completedAt = [DateTimeOffset]::Parse($CompletedAtUtc)
    $backupCreatedAt = [DateTimeOffset]::Parse($BackupCreatedAtUtc)
    $rpoObservedMs = [math]::Round(($completedAt - $backupCreatedAt).TotalMilliseconds, 0)
}

$record = [ordered]@{
    DrillType = $DrillType
    MetricsProfile = $MetricsProfile
    MetricsScenario = $MetricsScenario
    Status = $Status
    StartedAtUtc = $StartedAtUtc
    CompletedAtUtc = $CompletedAtUtc
    LeadInDurationMs = $leadInDurationMs
    SeedFixtureDurationMs = $SeedFixtureDurationMs
    BackupDurationMs = $BackupDurationMs
    ReprovisionDurationMs = $ReprovisionDurationMs
    RestoreDurationMs = $RestoreDurationMs
    RecoveryExecutionMs = $recoveryExecutionMs
    BusinessIntegrityDurationMs = $BusinessIntegrityDurationMs
    EvidencePackageDurationMs = $EvidencePackageDurationMs
    SmokeDurationMs = $SmokeDurationMs
    ValidationExecutionMs = $validationExecutionMs
    RtoObservedMs = $rtoObservedMs
    RpoObservedMs = $rpoObservedMs
    TotalDrillDurationMs = $TotalDrillDurationMs
    BackupBundlePath = $BackupBundlePath
    BackupCreatedAtUtc = $BackupCreatedAtUtc
    TargetDatabaseName = $TargetDatabaseName
    TargetStorageRoot = $TargetStorageRoot
}

$jsonLine = $record | ConvertTo-Json -Compress
Add-Content -Path $historyPath -Value $jsonLine -Encoding utf8
$record | ConvertTo-Json -Depth 5 | Set-Content -Path $latestJsonPath -Encoding utf8

$markdown = @'
# Recovery Drill Metrics

- DrillType: `{0}`
- MetricsProfile: `{1}`
- MetricsScenario: `{2}`
- Status: `{3}`
- StartedAtUtc: `{4}`
- CompletedAtUtc: `{5}`
- LeadInDurationMs: `{6}`
- RecoveryExecutionMs: `{7}`
- ValidationExecutionMs: `{8}`
- RtoObservedMs: `{9}`
- RpoObservedMs: `{10}`
- TotalDrillDurationMs: `{11}`

## Breakdown

- SeedFixtureDurationMs: `{12}`
- BackupDurationMs: `{13}`
- ReprovisionDurationMs: `{14}`
- RestoreDurationMs: `{15}`
- BusinessIntegrityDurationMs: `{16}`
- EvidencePackageDurationMs: `{17}`
- SmokeDurationMs: `{18}`

## Targets

- BackupBundlePath: `{19}`
- BackupCreatedAtUtc: `{20}`
- TargetDatabaseName: `{21}`
- TargetStorageRoot: `{22}`
'@ -f `
    $DrillType,
    $MetricsProfile,
    $MetricsScenario,
    $Status,
    $StartedAtUtc,
    $CompletedAtUtc,
    $leadInDurationMs,
    $recoveryExecutionMs,
    $validationExecutionMs,
    $rtoObservedMs,
    $rpoObservedMs,
    $TotalDrillDurationMs,
    $SeedFixtureDurationMs,
    $BackupDurationMs,
    $ReprovisionDurationMs,
    $RestoreDurationMs,
    $BusinessIntegrityDurationMs,
    $EvidencePackageDurationMs,
    $SmokeDurationMs,
    $BackupBundlePath,
    $BackupCreatedAtUtc,
    $TargetDatabaseName,
    $TargetStorageRoot

Set-Content -Path $latestMarkdownPath -Value $markdown -Encoding utf8

[pscustomobject]$record | Format-List
