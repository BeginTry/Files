/*
	Identifying External Memory Pressure with dm_os_ring_buffers and RING_BUFFER_RESOURCE_MONITOR
	Windows API - QueryMemoryResourceNotification()
	https://www.sqlskills.com/blogs/jonathan/identifying-external-memory-pressure-with-dm_os_ring_buffers-and-ring_buffer_resource_monitor/
	http://www.sqlskills.com/blogs/jonathan/wow-an-online-calculator-to-misconfigure-your-sql-server-memory/
*/
--	SELECT CURRENT_TIMESTAMP
SELECT 
    EventTime,
	--record.value('(/Record/@id)[1]', 'int') as RecordId,
    record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') as [Type],

	--Indicator for "internal" (SQL Server) memory pressure.
    record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') as [IndicatorsProcess - Internal SQL Server],

	--Indicator for "external" (Windows OS) memory pressure.
    record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') as [IndicatorsSystem - External Windows],
    
	record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') / 1024 AS [Avail Phys Mem, Mb],
    record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') / 1024 AS [Avail VAS, Mb]
FROM (
    SELECT
        DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - 
			[timestamp])/1000), GETDATE()) AS EventTime,
        CONVERT (xml, record) AS record
    FROM sys.dm_os_ring_buffers 
    CROSS JOIN sys.dm_os_sys_info
    WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS tab
WHERE 1 = 1
AND EventTime > (CURRENT_TIMESTAMP - 1)
--AND record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') <> 0
--OR record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') <> 0
ORDER BY EventTime DESC, record.value('(/Record/@id)[1]', 'int') DESC;
GO
