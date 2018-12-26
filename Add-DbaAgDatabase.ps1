$User = "sa"
$PWord = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$SqlInstance = "$env:COMPUTERNAME\SQL2017"
$AvailabilityGroup = "MyExpenseAG"
$Query = "SELECT d.name FROM sys.databases d WHERE d.source_database_id IS NULL AND d.recovery_model_desc = 'FULL' AND d.replica_id IS NULL AND d.state_desc = 'ONLINE' AND d.database_id > 4"

$DBList = (Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query).name

<#
    Prequisites:
        DB is not a snapshot.
        DB is in FULL recovery mode.
        DB is not already in an Availability Group.
        DB is online.
        DB is not a system database.
        DB has been backed up at least once.
#>
foreach($Database in $DBList)
{
    $LastBackup = (Get-DbaLastBackup -SqlInstance $SqlInstance -Database $Database)

    if ($LastBackup.LastFullBackup -eq $null -or [string]::IsNullOrEmpty($LastBackup.LastFullBackup))
    {
        # Full database backup to default backup directory.
        Backup-DbaDatabase -SqlInstance $SqlInstance -Database $Database -CompressBackup -Type Full
    }

    if ($LastBackup.LastLogBackup -eq $null -or [string]::IsNullOrEmpty($LastBackup.LastLogBackup))
    {
        # Full database backup to default backup directory.
        Backup-DbaDatabase -SqlInstance $SqlInstance -Database $Database -CompressBackup -Type Log
    }

    Add-DbaAgDatabase -SqlInstance $SqlInstance -AvailabilityGroup $AvailabilityGroup -Database $Database -SqlCredential $Credential -SeedingMode Automatic
}
