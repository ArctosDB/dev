<cfinclude template="/includes/_header.cfm">
<cfquery name="bulkSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		status,
		accn,
		enteredby,
		guid_prefix,
		count(*) cnt
	from
		bulkloader
	where
		bulkloader.status not like '% TEMPLATE%'
	group by
		status,
		accn,
		enteredby,
		guid_prefix
	order by
		guid_prefix,
		enteredby
</cfquery>
<cfoutput>
	What's In The Bulkloader:
	<table border="1">
		<tr>
			<td>Collection</td>
			<td>Accn</td>
			<td>Entered By</td>
			<td>Status</td>
			<td>Count</td>
		</tr>
	<cfloop query="bulkSummary">
		<tr>
			<td>#guid_prefix#</td>
			<td>#accn#</td>
			<td>#EnteredBy#</td>
			<td>#status#</td>
			<td>#cnt#</td>
		</tr>
	</cfloop>
	</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">