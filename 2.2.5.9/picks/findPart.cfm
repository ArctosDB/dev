<cfinclude template="/includes/_includeHeader.cfm">
<script>
	function pt(partFld,part_name){
		opener.$('#' + partFld).val(part_name);
		self.close();
	}
</script>
<cfoutput>
<cfif len(part_name) gt 0>
	<cfset search=true>
</cfif>
<form name="s" action="findPart.cfm" method="post">
	<br>Part Name: <input type="text" name="part_name" value="#part_name#">
	<br><input type="submit" value="Find Matches">
	<input type="hidden" name="search" value="true">
	<input type="hidden" name="collCde" value="#collCde#">
	<input type="hidden" name="partFld" value="#partFld#">
</form>
<cfif isdefined("search") and search is "true">
	<!--- make sure we're searching for something --->
	<cfif len(part_name) is 0>
		<cfabort>
	</cfif>
	<cfquery name="gp" datasource="uam_god">
		select
			part_name,description
		from
			ctspecimen_part_name
		where
			ctspecimen_part_name.collection_cde=<cfqueryparam value="#collCde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collCde))#"> and
	  		part_name ilike <cfqueryparam value="%#part_name#%" CFSQLType="CF_SQL_VARCHAR" >
		order by part_name
	</cfquery>
	<cfif gp.recordcount is 0>
		Nothing Found
	<cfelseif gp.recordcount is 1>
			<cfset ptnm=replace(gp.part_name,"'","\'","all")>
		<script>
			pt('#partFld#','#ptnm#');
		</script>
	<cfelse>
		<table border>
			<tr>
				<th>Part Name</th>
				<th>Description</th>
			</tr>
			<cfloop query="gp">
				<tr>
					<td>
						<cfset ptnm=replace(gp.part_name,"'","\'","all")>
						<a href="##" onClick="pt('#partFld#','#ptnm#');">#part_name#</a>
					</td>
					<td>
						#description#
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfif>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">