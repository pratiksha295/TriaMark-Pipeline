<#
.SYNOPSIS
  Run SQL on Redshift Serverless (mdm-sbx-01) through the Redshift Data API.

.EXAMPLE
  .\scripts\rsql.ps1 "select current_user, current_database()"
  .\scripts\rsql.ps1 -File .\analyses\check.sql
  .\scripts\rsql.ps1 "select * from staging.some_table limit 10" -Database northstar_lake_sbx
#>
param(
    [Parameter(Position = 0)] [string] $Sql,
    [string] $File,
    [string] $Database  = 'northstar_lake_sbx',
    [string] $Workgroup = 'mdm-sbx-01',
    [string] $Profile   = 'TriMarkSandbox',
    [int]    $TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
if ($File) { $Sql = Get-Content $File -Raw }
if (-not $Sql) { throw 'Provide SQL text or -File.' }

$common = @('--profile', $Profile, '--output', 'json')

$id = (aws redshift-data execute-statement @common --workgroup-name $Workgroup --database $Database --sql $Sql | ConvertFrom-Json).Id

$start = Get-Date
do {
    Start-Sleep -Milliseconds 800
    $desc = aws redshift-data describe-statement @common --id $id | ConvertFrom-Json
    if (((Get-Date) - $start).TotalSeconds -gt $TimeoutSeconds) {
        aws redshift-data cancel-statement --profile $Profile --id $id | Out-Null
        throw "Timed out after $TimeoutSeconds s (statement $id cancelled)."
    }
} while ($desc.Status -in 'SUBMITTED', 'PICKED', 'STARTED')

if ($desc.Status -ne 'FINISHED') { throw "Query $($desc.Status): $($desc.Error)" }

if (-not $desc.HasResultSet) {
    Write-Host "OK - $($desc.ResultRows) row(s) affected ($([math]::Round($desc.Duration / 1e9, 2)) s)"
    return
}

# Page through results and turn each record into an object.
$columns = $null
$rows = [System.Collections.Generic.List[object]]::new()
$token = $null
do {
    $pageArgs = @('--id', $id)
    if ($token) { $pageArgs += @('--next-token', $token) }
    $page = aws redshift-data get-statement-result @common @pageArgs | ConvertFrom-Json
    if (-not $columns) { $columns = $page.ColumnMetadata.name }
    foreach ($rec in $page.Records) {
        $obj = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $cell = $rec[$i]
            $obj[$columns[$i]] = if ($cell.isNull) { $null } else { ($cell.PSObject.Properties | Select-Object -First 1).Value }
        }
        $rows.Add([pscustomobject]$obj)
    }
    $token = $page.NextToken
} while ($token)

$rows | Format-Table -AutoSize
Write-Host "$($rows.Count) row(s) ($([math]::Round($desc.Duration / 1e9, 2)) s)"
