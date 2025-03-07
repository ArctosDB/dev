<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<h2>Data for Identifier Builder</h2>
	<style>
		#theTbl tr:nth-child(even) {
 			background-color: #f2f2f2;
		}
	</style>
	<cfset title='Identifier Helper'>
	<cfoutput>
		<cfquery name="cf_identifier_helper" datasource="uam_god">
			select
				key,
				identifier_type,
				identifier_base_uri,
				identifier_issuer,
				getPreferredAgentName(identifier_issuer) as issuer,
				target_type,
				description,
				identifier_example,
				fragment_datatype
			from cf_identifier_helper
			order by
				identifier_type
		</cfquery>
		
		<table border="1" id="theTbl" class="sortable">
			<tr>
				<th>identifier_type</th>
				<th>identifier_base_uri</th>
				<th>issuer</th>
				<th>target_type</th>
				<th>identifier_example</th>
				<th>fragment_datatype</th>
				<th>description</th>
				<th></th>
			</tr>
			<tr class="newRec">
				<form method="post" action="identifier_helper.cfm">
					<input type="hidden" name="action" value="insert">
					<td>
						<input type="text" name="identifier_type" size="50">
					</td>
					<td>
						<input type="text" name="identifier_base_uri" size="50">
					</td>
					<td>
						<input type="hidden" name="identifier_issuer" id="new_identifier_issuer" size="50">
						<input type="text" name="issuer"  id="new_issuer" placeholder="issuer" 
							onchange="pickAgentModal('new_identifier_issuer',this.id,this.value);"
							onkeypress="return noenter(event);">
					</td>
					<td>
						<input type="text" name="target_type" value="identifier" size="20" placeholder="target_type">
						
					</td>
					<td>
						<input type="text" name="identifier_example" placeholder="identifier_example" size="50">
					</td>
					<td>
						<select name="fragment_datatype">
							<option></option>
							<option value="int" >int</option>
							<option value="text" >text</option>
						</select>
					</td>
					<td>
						<textarea class="largetextarea" name="description"></textarea>
					</td>
					<td><input type="submit" value="create" class="insBtn"></td>
				</form>
			</tr>

			<cfloop query="cf_identifier_helper">
				<tr id="tr#key#">
					<form method="post" action="identifier_helper.cfm">
						<input type="hidden" name="action" value="update">
						<input type="hidden" name="key" value="#key#">
						<td>
							<input type="text" name="identifier_type" value="#identifier_type#" size="50">
						</td>
						<td>
							<input type="text" name="identifier_base_uri" value="#identifier_base_uri#" size="50">
						</td>
						<td>
							<input type="hidden" name="identifier_issuer" id="#key#_identifier_issuer" size="50">
							<input type="text" name="issuer" value="#issuer#" id="#key#_issuer" placeholder="issuer" 
								onchange="pickAgentModal('#key#_identifier_issuer',this.id,this.value);"
								onkeypress="return noenter(event);">
						</td>
						<td>
							<input type="text" name="target_type" value="#target_type#" size="20" placeholder="target_type">
							
						</td>
						<td>
							<input type="text" name="identifier_example" value="#identifier_example#" placeholder="identifier_example" size="50">
						</td>
						<td>
							<select name="fragment_datatype">
								<option></option>
								<option value="int" <cfif fragment_datatype is "int"> selected="selected" </cfif> >int</option>
								<option value="text" <cfif fragment_datatype is "text"> selected="selected" </cfif> >text</option>
							</select>
						</td>
						<td>
							<textarea class="largetextarea" name="description">#description#</textarea>
						</td>
						<td><input type="submit" value="save" class="savBtn"></td>
					</form>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action is "insert">
	<cfoutput>
		<cfquery result="justmade" name="incf_identifier_helper" datasource="uam_god">
			insert into cf_identifier_helper (
				identifier_type,
				identifier_base_uri,
				identifier_issuer,
				target_type,
				description,
				identifier_example,
				fragment_datatype
			) values (
				<cfqueryparam value="#identifier_type#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#identifier_base_uri#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(identifier_base_uri))#">,
				<cfqueryparam value="#identifier_issuer#" cfsqltype="cf_sql_int" null="#Not Len(Trim(identifier_issuer))#">,
				<cfqueryparam value="#target_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(target_type))#">,
				<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(description))#">,
				<cfqueryparam value="#identifier_example#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(identifier_example))#">,
				<cfqueryparam value="#fragment_datatype#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(fragment_datatype))#">
			)
		</cfquery>
		<cflocation url="identifier_helper.cfm##tr#justmade.key#" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "update">
	<cfoutput>
		<cfquery name="upcf_identifier_helper" datasource="uam_god">
			update cf_identifier_helper set
				identifier_type=<cfqueryparam value="#identifier_type#" cfsqltype="cf_sql_varchar">,
				identifier_base_uri=<cfqueryparam value="#identifier_base_uri#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(identifier_base_uri))#">,
				identifier_issuer=<cfqueryparam value="#identifier_issuer#" cfsqltype="cf_sql_int" null="#Not Len(Trim(identifier_issuer))#">,
				target_type=<cfqueryparam value="#target_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(target_type))#">,
				description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(description))#">,
				identifier_example=<cfqueryparam value="#identifier_example#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(identifier_example))#">,
				fragment_datatype=<cfqueryparam value="#fragment_datatype#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(fragment_datatype))#">
			where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
		</cfquery>
		<cflocation url="identifier_helper.cfm##tr#key#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">