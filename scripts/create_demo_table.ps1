<#
.SYNOPSIS
  Create a small demo table in northstar_lake_sbx.staging (via the Redshift Data API).

.DESCRIPTION
  Safe to re-run: the table is only created if missing, and sample rows are only
  inserted when the table is empty.

.EXAMPLE
  .\scripts\create_demo_table.ps1
  .\scripts\create_demo_table.ps1 -Table demo_vendor_test
#>
param(
    [string] $Table     = 'demo_vendor',
    [string] $Schema    = 'staging',
    [string] $Database  = 'northstar_lake_sbx',
    [string] $Workgroup = 'mdm-sbx-01',
    [string] $Profile   = 'TriMarkSandbox'
)

$ErrorActionPreference = 'Stop'
$fq = "$Schema.$Table"

$statements = @(
    @"
create table if not exists $fq (
    vendor_id    integer       not null,
    vendor_name  varchar(100)  not null,
    city         varchar(50),
    is_active    boolean       default true,
    created_at   timestamp     default getdate(),
    primary key (vendor_id)
)
"@,
    @"
insert into $fq (vendor_id, vendor_name, city, is_active)
select * from (
    select 1, 'Acme Supplies',     'Chicago',  true  union all
    select 2, 'Blue Ridge Foods',  'Denver',   true  union all
    select 3, 'Coastal Equipment', 'Miami',    false
)
where not exists (select 1 from $fq)
"@
)

Write-Host "Creating $Database.$fq on $Workgroup ..."
$id = (aws redshift-data batch-execute-statement --profile $Profile --output json `
        --workgroup-name $Workgroup --database $Database --sqls $statements | ConvertFrom-Json).Id

do {
    Start-Sleep -Milliseconds 800
    $desc = aws redshift-data describe-statement --profile $Profile --output json --id $id | ConvertFrom-Json
} while ($desc.Status -in 'SUBMITTED', 'PICKED', 'STARTED')

if ($desc.Status -ne 'FINISHED') { throw "Failed ($($desc.Status)): $($desc.Error)" }

Write-Host "Done. Table $Database.$fq is ready."
Write-Host "Check it with:  .\scripts\rsql.ps1 `"select * from $fq order by vendor_id`""
