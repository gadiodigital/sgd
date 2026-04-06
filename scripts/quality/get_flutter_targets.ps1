param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
)

@(
    "$WorkspaceRoot\client\apps\gdms_app",
    "$WorkspaceRoot\client\packages\core",
    "$WorkspaceRoot\client\packages\design_system",
    "$WorkspaceRoot\client\packages\feature_auth",
    "$WorkspaceRoot\client\packages\feature_config",
    "$WorkspaceRoot\client\packages\feature_documents",
    "$WorkspaceRoot\client\packages\feature_integrations",
    "$WorkspaceRoot\client\packages\feature_notifications",
    "$WorkspaceRoot\client\packages\feature_records",
    "$WorkspaceRoot\client\packages\feature_reports",
    "$WorkspaceRoot\client\packages\feature_search",
    "$WorkspaceRoot\client\packages\feature_signature",
    "$WorkspaceRoot\client\packages\feature_sector_corporate",
    "$WorkspaceRoot\client\packages\feature_sector_legal",
    "$WorkspaceRoot\client\packages\feature_sector_real_estate",
    "$WorkspaceRoot\client\packages\feature_admin",
    "$WorkspaceRoot\client\packages\feature_audit",
    "$WorkspaceRoot\client\packages\feature_workflow"
)
