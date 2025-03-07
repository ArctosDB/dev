<cfinclude template="/includes/_includeHeader.cfm">
<script>
	function pt(partFld,part_name){
		opener.$('#' + partFld).val(part_name).removeClass().addClass('goodPick');
		self.close();
	}
</script>
<style>
	.theBlurb{
			font-weight: bold; 
			font-size: large;
			margin:1em 0em 1em 0em;
		}
	</style>
<cfoutput>
<cfif len(part_name) gt 0>
	<cfset search=true>
</cfif>
<form name="s" action="findPart.cfm" method="post">
	<br>Part Name: <input type="text" name="part_name" value="#part_name#">
	<br><input type="submit" value="Find Matches">
	<input type="hidden" name="search" value="true">
	<input type="hidden" name="guid_prefix" value="#guid_prefix#">
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
			<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> = any(ctspecimen_part_name.collections) and
	  		part_name ilike <cfqueryparam value="%#part_name#%" CFSQLType="CF_SQL_VARCHAR" >
	</cfquery>
	<cfif gp.recordcount is 0>
		Nothing Found
	<cfelseif gp.recordcount is 1 and left(gp.description,1) is not '['>
			<cfset ptnm=replace(gp.part_name,"'","\'","all")>
		<script>
			pt('#partFld#','#ptnm#');
		</script>
	<cfelse>
		<cfquery name="goodparts" dbtype="query">
			select part_name,description from gp where description not like <cfqueryparam value="[%" cfsqltype="cf_sql_varchar"> order by part_name
		</cfquery>
		<cfquery name="badparts" dbtype="query">
			select part_name,description from gp where description like <cfqueryparam value="[%" cfsqltype="cf_sql_varchar"> order by part_name
		</cfquery>
		<table border>
			<tr>
				<th>Part Name</th>
				<th>Description</th>
			</tr>
			<cfloop query="goodparts">
				<tr>
					<td>
						<cfset ptnm=replace(part_name,"'","\'","all")>
						<a href="##" onClick="pt('#partFld#','#ptnm#');">#part_name#</a>
					</td>
					<td>
						#description#
					</td>
				</tr>
			</cfloop>
			<cfloop query="badparts">
				<tr>
					<td>
						<cfset ptnm=replace(part_name,"'","\'","all")>
						<a href="##" onClick="pt('#partFld#','#ptnm#');">#part_name#</a>
					</td>
					<td>
						<cfset theBlurb=left(description,find(']',description))>
						<div class="theBlurb">
							#theBlurb#
						</div>
						<div>
							<cfset rd=replace(description, theBlurb, '')>
							#rd#
						</div>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfif>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">