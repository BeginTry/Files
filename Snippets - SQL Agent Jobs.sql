/*
	List the "DBA" SQL Agent Jobs, job steps, and associated schedule.
*/
SELECT j.name JobName, j.description JobDescription, s.step_id StepNumber, 
	s.step_name StepName, ss.name ScheduleName
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s
	ON s.job_id = j.job_id 
LEFT JOIN msdb.dbo.sysjobschedules js
	ON js.job_id = j.job_id 
LEFT JOIN msdb.dbo.sysschedules ss
	ON ss.schedule_id = js.schedule_id
WHERE j.name LIKE 'DBA-%'
ORDER BY j.name, s.step_id

SELECT s.name, s.active_start_time
FROM msdb.dbo.sysschedules s
WHERE s.name LIKE 'DBA-%'
ORDER BY s.name
/******************************************************************************/
/*
	Template:  SQL Agent job email.
*/
DECLARE @HtmlTable VARCHAR(MAX)
DECLARE @EmailBody VARCHAR(MAX) = '
	<style>
		td {
			font-size: smaller;
		}
		p {
			padding: 0px;
			margin: 0px;
			margin-auto: 0px;
		}
		.ExternalClass * 
		{
			mso-line-height-rule: exactly;
			line-height: 100%;
		} 
    </style>
Database backups for <a href="http://crm2011.lkm.sungardps.lcl/SPS/userdefined/edit.aspx?etc=10061&id=%7bEDD55FFA-3A9B-E411-9CF2-005056B70DB4%7d">CSR 7 470</a> are complete.  The GIS Update can proceed.<br/>
If anyone needs further assistance with SQL Server issues, please contact <a href="mailto:Dave.Mason@SunGardPS.com?subject=Database Backups - CSR 7 470">Dave Mason</a>. (cell: 407-529-7123)<br/><br/><br/>	
'

SET @HtmlTable = '<table border="4" cellpadding="2" stle="font-size: smaller;">' + CHAR(13) + CHAR(10) + '
	<tr><th colspan="2" style="background-color: darkblue; color: white;">' + @@SERVERNAME + '</th></tr>
	<tr><th colspan="2" style="background-color: wheat;">FULL Backups</th></tr>
	<tr><th style="background-color: lightgrey;">Database Name</th>
		<th style="background-color: lightgrey;">Completion</th>
	</tr>' 	

SELECT @HtmlTable = @HtmlTable + 
	'<tr><td>' + lb.DbName + '</td>' +
	'<td style="white-space: nowrap">' + COALESCE(DATENAME(dw, lb.DateCompletedFull) + ' ' + 
		CONVERT(VARCHAR, lb.DateCompletedFull, 101) + '  ' + 
		CONVERT(VARCHAR, lb.DateCompletedFull, 108), '&nbsp;') + ' </td>' +
	'</tr>' + CHAR(13) + CHAR(10)
FROM DbaData.dba.LastBackups lb
WHERE lb.DbName NOT IN ('DbaData', 'master', 'model', 'msdb')
ORDER BY lb.DbName

SET @HtmlTable += '</table>' + CHAR(13) + CHAR(10)
SELECT @EmailBody += @HtmlTable 


EXEC msdb..sp_send_dbmail
	@recipients = 'Dave.Mason@SungardPS.com',
	--@copy_recipients = 'Dylan.Lintelman@Sungardps.com',
	@reply_to = 'DoNotReply@SunGardPS.com',
	@Subject = 'Database Backups - BRUN',
	@body = @EmailBody,
	@body_format = 'HTML'
