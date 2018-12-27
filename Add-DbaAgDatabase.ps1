$SqlInstance = "$env:COMPUTERNAME\SQL2017"
$AvailabilityGroup = "MyExpenseAG"

<#
    Reference: https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability?view=sql-server-2017#PrerequisitesForDbs

    Prerequisites - to be eligible to be added to an availability group, a database must:
        Be a user database. System databases cannot belong to an availability group.
        Be a read-write database. Read-only databases cannot be added to an availability group.
        Be a multi-user database.
        Not use AUTO_CLOSE.
        Use the full recovery model (also known as, full recovery mode).
        Possess at least one full database backup.
            Note: After setting a database to full recovery mode, a full backup is required to initiate the full-recovery log chain.
        Not belong to any existing availability group.
        Not be configured for database mirroring.

        (Additional prerequisites)
        Not a snapshot.
        Be online.
#>
$Query = "SELECT d.name, s.last_log_backup_lsn
    FROM master.sys.databases d
    JOIN master.sys.database_recovery_status s
	    ON s.database_id = d.database_id
    LEFT JOIN master.sys.database_mirroring m
	    ON m.database_id = d.database_id
    WHERE d.name NOT IN ('master', 'model', 'msdb', 'tempdb')
    AND d.is_read_only = 0
    AND d.user_access_desc = 'MULTI_USER'
    AND d.is_auto_close_on = 0
    AND d.recovery_model_desc = 'FULL'
    AND d.replica_id IS NULL 
    AND m.mirroring_state IS NULL
    AND d.source_database_id IS NULL 
    AND d.state_desc = 'ONLINE' 
    ORDER BY d.name"

#$DBList = (Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query).name
$DBList = Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $Query

foreach($Database in $DBList)
{
    if ($Database.last_log_backup_lsn -eq $null -or [string]::IsNullOrEmpty($Database.last_log_backup_lsn))
    {
        <#
            If last_log_backup_lsn IS NULL, the log chain is broken.
            Take a FULL database backup to default backup directory.
        #>
        Backup-DbaDatabase -SqlInstance $SqlInstance -Database $Database.name -CompressBackup -Type Full
    }

    <# TODO?: 
        Compression can be used for automatic seeding, but it is disabled by default. 
        Turning on compression reduces network bandwidth and possibly speeds up the process, 
        but the tradeoff is additional processor overhead. To use compression during automatic 
        seeding, enable trace flag 9567.

        Reference: https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/automatic-seeding-secondary-replicas?view=sql-server-2017#considerations
    #>
    Add-DbaAgDatabase -SqlInstance $SqlInstance -AvailabilityGroup $AvailabilityGroup -Database $Database.name -SeedingMode Automatic
}
