$User = "sa"
$PWord = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$SqlInstance = "$env:COMPUTERNAME\SQL2017"
$AvailabilityGroup = "MyExpenseAG"
$Query = "SELECT d.name FROM sys.databases d WHERE d.source_database_id IS NULL AND d.recovery_model_desc != 'SIMPLE' AND d.replica_id IS NULL AND d.state_desc = 'ONLINE' AND d.database_id > 4"

$DBList = (Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query).name

<#
    Prequisites:
        DB is not a snapshot.
        DB is in FULL (or BULK_LOGGED?) recovery mode.
        DB is not already in an Availability Group.
        DB is online.
        DB is not a system database.
        DB has been backed up at least once.
#>
foreach($Database in $DBList)
{
    $LastBackup = (Get-DbaLastBackup -SqlInstance $SqlInstance -Database $Database).LastFullBackup

    if ($LastBackup -eq $null)
    {
        # Full database backup to default backup directory.
        Backup-DbaDatabase -SqlInstance $SqlInstance -Database $Database -CompressBackup 
    }

    Add-DbaAgDatabase -SqlInstance $SqlInstance -AvailabilityGroup $AvailabilityGroup -Database $Database -SqlCredential $Credential -SeedingMode Automatic
}

