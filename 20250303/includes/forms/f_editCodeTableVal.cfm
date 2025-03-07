<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
	<cfoutput>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #tbl# where #fld#='#URLDecode(v)#'
	</cfquery>
	<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct collection_cde from ctcollection_cde order by collection_cde
	</cfquery>
	<cfquery name="p" dbtype="query">
		select distinct #fld# from d
	</cfquery>
	<cfquery name="dec" dbtype="query">
		select distinct description from d
	</cfquery>

		<form name="f" method="post" action="">
			<input type="hidden" name="action" value="update">
			<p>
				Editing <strong>#fld#=#URLDecode(v)#</strong>
			</p>
			<input type="hidden" name="fld" id="fld" value="#fld#">
			<input type="hidden" name="tbl" id="tbl" value="#tbl#">
			<input type="hidden" name="v" id="v" value="#URLEncodedFormat(v)#">
			<cfset ctccde=valuelist(ctcollcde.collection_cde)>
			<cfset c=1>
			<cfloop query="d">
				<cfset ctccde=listdeleteat(ctccde,listfind(ctccde,'#collection_cde#'))>
				<label for="collection_cde_#c#">Available for Collection Type</label>
				<select name="collection_cde_#c#" id="collection_cde_#c#" size="1" class="reqdClr" required>
					<option value="DELETE__#d.collection_cde#">Remove from this collection type</option>
					<option selected="selected" value="#d.collection_cde#">#d.collection_cde#</option>
				</select>
				<cfset c=c+1>
			</cfloop>
			<label for="collection_cde_new">Make available for Collection Type</label>
			<select name="collection_cde_new" id="collection_cde_new" size="1">
				<option value=""></option>
				<cfloop list="#ctccde#" index="ccde">
					<option	value="#ccde#">#ccde#</option>
				</cfloop>
			</select>
			<label for="description">Description</label>
			<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required>#dec.description#</textarea>
			<br>
			<input type="submit" value="Save Changes" class="savBtn">
			<p>
				Removing all collection types will delete the record.
				<br>Delete and re-create to change.
			</p>
		</form>
	</cfoutput>
</cfif>
<cfif action is "update">
	<cfoutput>
		<cftransaction>
			<cfloop list="#FIELDNAMES#" index="f">
				<cfif left(f,15) is "COLLECTION_CDE_" and f is not "COLLECTION_CDE_NEW">
					<cfset thisCCVal=evaluate(f)>
					<cfif left(thisCCVal,8) is 'DELETE__'>
						<cfset thisCCVal=mid(thisCCVal,9,500)>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from #tbl# where #fld#=<cfqueryparam value="#URLDecode(v)#" CFSQLType="CF_SQL_VARCHAR"> and collection_cde='#thisCCVal#'
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
			<!----
				second, update everything that's left
				If we've deleted everything this will just do nothing
			---->
			<cfquery name="upf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update #tbl# set DESCRIPTION=<cfqueryparam value="#DESCRIPTION#" CFSQLType="cf_sql_varchar"> where #fld#='#URLDecode(v)#'
			</cfquery>
			<!--- last, insert new if there's one provided ---->
			<cfif len(COLLECTION_CDE_NEW) gt 0>
				<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into  #tbl#  (#fld#,COLLECTION_CDE,DESCRIPTION
						) values (
					'#URLDecode(v)#','#COLLECTION_CDE_NEW#',<cfqueryparam value="#DESCRIPTION#" CFSQLType="cf_sql_varchar">)
				</cfquery>
			</cfif>
		</cftransaction>
		<cflocation url="f_editCodeTableVal.cfm?fld=#fld#&tbl=#tbl#&v=#v#" addtoken="false">
	</cfoutput>
</cfif>