<cfset title="block autoblock">
<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<script>
		function sv(i){
			$("#ac" + i).val('save');
			$("#f" + i).submit();
		}
		function dl(i){
			$("#ac" + i).val('delete');
			$("#f" + i).submit();
		}
	</script>
	<cfoutput>
	<h3>
		bot trap word/phrases
	</h3>
		<form id="f" method="post" action="block.cfm">
			<input type="hidden" name="action"  value="create">
			<input type="text" name="phrase" size="60">
			<select name="check_as">
				<option  value="word">word</option>
				<option  value="anywhere">anywhere</option>
			</select>
			<input type="submit" class="insBtn" value="create">
		</form>

		<cfquery name="d" datasource="uam_god">
			select block_phrase_id, phrase,check_as  from block_phrase order by phrase,check_as
		</cfquery>
		<cfset i=0>
		<cfloop query="d">
		<cfset i=i+1>
		<div id="#block_phrase_id#"  #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			<form id="f#i#" method="post" action="block.cfm">
				<input type="hidden" name="block_phrase_id"  value="#block_phrase_id#">
				<input type="hidden" name="action" id="ac#i#" value="">
				<input type="text" name="phrase" value="#phrase#" size="60">

				<select name="check_as">
					<option <cfif check_as is "word"> selected </cfif> value="word">word</option>
					<option <cfif check_as is "anywhere"> selected </cfif> value="anywhere">anywhere</option>
				</select>
				<input type="button" class="savBtn" value="save" onclick="sv(#i#);">
				<input type="button" class="delBtn" value="delete" onclick="dl(#i#);">
			</form>
			</div>
		</cfloop>
	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfquery name="d" datasource="uam_god">
		delete from block_phrase where block_phrase_id=#val(block_phrase_id)#
	</cfquery>
	<cflocation url='block.cfm' addtoken="false">
</cfif>
<cfif action is "save">
	<cfquery name="d" datasource="uam_god">
		update block_phrase set
		phrase=<cfqueryparam value = "#phrase#" CFSQLType="CF_SQL_VARCHAR">,
		check_as=<cfqueryparam value = "#check_as#" CFSQLType="CF_SQL_VARCHAR">
		where block_phrase_id=#val(block_phrase_id)#
	</cfquery>
	<cflocation url='block.cfm###block_phrase_id#' addtoken="false">
</cfif>

<cfif action is "create">
	<cfquery name="d" datasource="uam_god">
		insert into block_phrase (phrase,check_as) values (
		<cfqueryparam value = "#phrase#" CFSQLType="CF_SQL_VARCHAR">,
		<cfqueryparam value = "#check_as#" CFSQLType="CF_SQL_VARCHAR">
		)
	</cfquery>
	<cflocation url='block.cfm' addtoken="false">
</cfif>



<cfinclude template="/includes/_footer.cfm">