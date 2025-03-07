<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">


	<cfoutput>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ctspecimen_part_name where part_name='#part_name#'
	</cfquery>
	<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct collection_cde from ctcollection_cde order by collection_cde
	</cfquery>
	<cfquery name="p" dbtype="query">
		select distinct part_name from d
	</cfquery>
	<cfquery name="dec" dbtype="query">
		select distinct description from d
	</cfquery>


		<form name="f" method="post" action="">
			<input type="hidden" name="action" value="update">
			<p>
				Editing part name <strong>#part_name#</strong>
			</p>
			<input type="hidden" name="part_name" id="part_name" value="#p.part_name#" size="50" class="reqdClr" required="required">
			<cfset ctccde=valuelist(ctcollcde.collection_cde)>

			<cfloop query="d">
				<cfset ctccde=listdeleteat(ctccde,listfind(ctccde,'#collection_cde#'))>
				<label for="collection_cde_#CTSPNID#">Available for Collection Type</label>
				<select name="collection_cde_#CTSPNID#" id="collection_cde_#CTSPNID#" size="1">
					<option value="">Remove from this collection type</option>
					<option selected="selected" value="#d.collection_cde#">#d.collection_cde#</option>
				</select>
			</cfloop>
			<label for="collection_cde_new">Make available for Collection Type</label>
			<select name="collection_cde_new" id="collection_cde_new" size="1">
				<option value=""></option>
				<cfloop list="#ctccde#" index="ccde">
					<option	value="#ccde#">#ccde#</option>
				</cfloop>
			</select>
			<label for="description">Description</label>
			<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required="required">#dec.description#</textarea>
			<br>
			<input type="submit" value="Save Changes" class="savBtn">
			<p>
				Removing a part from all collection types will delete the record.
			</p>
		</form>
	</cfoutput>
</cfif>
<cfif action is "update">
	<cfoutput>
		<cftransaction>
			<!--- first, delete anything that needs deleted ---->
			<cfloop list="#FIELDNAMES#" index="f">
				<cfif left(f,15) is "COLLECTION_CDE_" and f is not "COLLECTION_CDE_NEW">
					<!--- if the value is NULL, we're deleting that record ---->
					<cfset thisCCVal=evaluate(f)>
					<cfif len(thisCCVal) is 0>
						<cfset thisPartID=listlast(f,"_")>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from ctspecimen_part_name where CTSPNID=<cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
			<!----
				second, update everything that's left
				If we've deleted everything this will just do nothing
			---->
			<cfquery name="upf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update ctspecimen_part_name set 
					DESCRIPTION=<cfqueryparam value="#DESCRIPTION#" CFSQLType="cf_sql_varchar"> 
					where part_name=<cfqueryparam value="#part_name#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<!--- last, insert new if there's one provided ---->
			<cfif len(COLLECTION_CDE_NEW) gt 0>
				<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into ctspecimen_part_name (
						PART_NAME,
						COLLECTION_CDE,
						DESCRIPTION
					) values (
						<cfqueryparam value="#part_name#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#COLLECTION_CDE_NEW#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#DESCRIPTION#" CFSQLType="cf_sql_varchar">
					)
				</cfquery>
			</cfif>
		</cftransaction>
		<cflocation url="f2_ctspecimen_part_name.cfm?part_name=#URLEncodedFormat(part_name)#" addtoken="false">
	</cfoutput>
</cfif>