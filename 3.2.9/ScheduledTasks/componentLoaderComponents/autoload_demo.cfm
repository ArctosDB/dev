<cfquery name="d" datasource="uam_god">
	select * from cf_temp_demotable
</cfquery>
<cfdump var=#d#>
<cfset thisRan=true>
