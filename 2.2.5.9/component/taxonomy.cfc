<cfcomponent>

<cffunction name="updateWormsArctosByAphiaID" access="remote">
		<!----
			This is simplified for https://github.com/ArctosDB/arctos/issues/2926
			The last old version is v1.5.1.2
		---->
		<cfargument name="aphiaID" type="string" required="true">
		<cfargument name="taxon_name_id" type="string" required="true">
		<cfargument name="auth_key" required="yes" type="string">
		<cfquery name="auth" datasource="uam_god">
			select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
		</cfquery>
		<cfif len(auth.auth_key) lt 1>
			<cfthrow message="failed authorization">
		</cfif>
		<cfparam name="debug" default="false">
		<cfoutput>
			<cftry>
				<cfset ct=queryNew("t,v,o")>
				<cfset nct=queryNew("t,v")>
				<cfquery name="ctclasification_terms" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select taxon_term from cttaxon_term where is_classification=1
				</cfquery>
				<!--- first call: get only nonclassification terms ---->
				<cfhttp  result="ga" url="http://www.marinespecies.org/rest/AphiaRecordByAphiaID/#aphiaID#" method="get"></cfhttp>
				<cfif debug is true>
					<cfdump var=#ga#>
				</cfif>
				<cfif ga.statusCode is "200 OK" and len(ga.filecontent) gt 0 and isjson(ga.filecontent)>
					<cfset gao=DeserializeJSON(ga.filecontent)>
					<cfif debug is true>
						<cfdump var=#gao#>
					</cfif>
					<cfset pc=1>
					<cfloop collection="#gao#" item="lkey">

						<cfif debug is true>
							<br>looping over gao for #lkey#
						</cfif>
	    				<cfif structKeyExists(gao,lkey)>
	    					<cfif debug is true>
								<br>lgot a lkey
							</cfif>


	    					<cfquery name="isctrm" dbtype="query">
	    						select taxon_term from ctclasification_terms where taxon_term=<cfqueryparam value = "#lkey#" CFSQLType="CF_SQL_VARCHAR">
	    					</cfquery>
							<cfif debug is true>
								<cfdump var="#isctrm#">
							</cfif>

	    					<cfif len(isctrm.taxon_term) eq 0>
	    						<cfset queryAddRow(nct,{t=lkey,v=gao[lkey]})>
	    						<cfif debug is true>
									<br>added#lkey#==#gao[lkey]#
								</cfif>
	    					</cfif>
	    				</cfif>
					</cfloop>
				</cfif>

				<!--- second call: get ranked classification terms ---->
				<cfhttp  result="ga" url="http://www.marinespecies.org/rest/AphiaClassificationByAphiaID/#aphiaID#" method="get"></cfhttp>
				<cfif ga.statusCode is "200 OK" and len(ga.filecontent) gt 0 and isjson(ga.filecontent)>
					<cfset gao=DeserializeJSON(ga.filecontent)>
					<cfif debug is true>
						<cfdump var=#gao#>
					</cfif>
					<cfset aos=StructFindKey(gao,"AphiaID","all")>
					<cfset pos=1>
					<cfloop from="1" to="#arraylen(aos)#" index="i">
						<cfset thisS=aos[i].owner>
						<cfset queryAddRow(ct,{t=lcase(thisS.rank),v=thisS.scientificname,o=pos})>
						<cfset pos=pos+1>
					</cfloop>
				</cfif>


				<cfif debug is true>
					<cfdump var=#nct#>
					<cfdump var=#ct#>
				</cfif>


				<cfif nct.recordcount gt 0 and ct.recordcount gt 0>
					<!--- got something, run with it ---->
					<cftransaction>
						<cfset thisSrcName="WoRMS (via Arctos)">
						<cfquery name="getSrcID" datasource="uam_god">
							select classification_id from taxon_term where 
								taxon_name_id=<cfqueryparam value = "#taxon_name_id#" CFSQLType="cf_sql_int"> and 
								source=<cfqueryparam value = "#thisSrcName#" CFSQLType="CF_SQL_VARCHAR">
							group by classification_id
						</cfquery>
						<cfif getSrcID.recordcount is 1 and len(getSrcID.classification_id) gt 0>
							<cfset thisSourceID=getSrcID.classification_id>
						<cfelse>
							<cfset thisSourceID=CreateUUID()>
						</cfif>
						<cfquery name="flushOld" datasource="uam_god">
							delete from taxon_term where 
								taxon_name_id=<cfqueryparam value = "#taxon_name_id#" CFSQLType="cf_sql_int"> and 
								source=<cfqueryparam value = "#thisSrcName#" CFSQLType="CF_SQL_VARCHAR">
						</cfquery>
						<cfloop query="nct">
							<cfquery name="meta" datasource="uam_god">
								insert into taxon_term (
									taxon_term_id,
									taxon_name_id,
									term_type,
									term,
									source,
									classification_id
								) values (
									nextval('sq_taxon_term_id'),
									<cfqueryparam value = "#taxon_name_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#v#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#thisSrcName#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#thisSourceID#" CFSQLType="CF_SQL_VARCHAR">
								)
							</cfquery>
						</cfloop>
						<cfloop query="ct">
							<cfquery name="trms" datasource="uam_god">
								insert into taxon_term (
									taxon_term_id,
									taxon_name_id,
									term_type,
									term,
									source,
									classification_id,
									position_in_classification
								) values (
									nextval('sq_taxon_term_id'),
									<cfqueryparam value = "#taxon_name_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#v#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#thisSrcName#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#thisSourceID#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value = "#o#" CFSQLType="cf_sql_int">
								)
							</cfquery>
						</cfloop>
					</cftransaction>
				<cfelse>
					<cfset r.status='fail'>
					<cfset r.msg='not found at WoRMS'>
					<cfreturn r>
				</cfif>
			<cfcatch>
				<cfif debug is true>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfset r.status='fail'>
				<cfset r.msg=cfcatch.detail>
				<cfreturn r>
			</cfcatch>
			</cftry>
			<cfset r.status='success'>
			<cfreturn r>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="saveHierParentEdit" access="remote">
		<cfargument name="hierarchy_term_id" type="string" required="true">
		<cfargument name="parent_term" type="string" required="true">
		<cfoutput>
			<cftry>
				<cfif parent_term is "root">
					<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set parent_term_id=null where hierarchy_term_id=#hierarchy_term_id#
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<br>set nptv status success
					</cfif>
					<cfset myStruct = {}>
					<cfset myStruct.status='success'>
					<cfset myStruct.child=hierarchy_term_id>
					<cfset myStruct.parent=0>
				<cfelse>
					<cfif isdefined("debug") and debug is 1>
						<br>got nptv
					</cfif>
					<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select * from hierarchy_term where term=<cfqueryparam value = "#URLDecode(parent_term)#" CFSQLType="CF_SQL_VARCHAR"> and hierarchy_id in (select hierarchy_id from hierarchy_term where hierarchy_term_id=#hierarchy_term_id#)
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<p>-------------------==============================--------------------------- d dump</p>
						<cfdump var=#d#>
					</cfif>
					<cfif d.recordcount is 1 and len(d.hierarchy_term_id) gt 0>
						<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update hierarchy_term set parent_term_id=#d.hierarchy_term_id# where hierarchy_term_id=#hierarchy_term_id#
						</cfquery>
						<!--- return
							1) the parent; it's what we'll need to expand;
							2) the child so we can focus it
						---->
						<cfif isdefined("debug") and debug is 1>
							<br>set nptv status success
						</cfif>
						<cfset myStruct = {}>
						<cfset myStruct.status='success'>
						<cfset myStruct.child=hierarchy_term_id>
						<cfset myStruct.parent=d.hierarchy_term_id>
					<cfelse>
						<cfif isdefined("debug") and debug is 1>
							<br>set nptv status fail
						</cfif>
						<!----
						<cfdump var=#d#>
						---->
						<cfset myStruct = {}>
						<cfset myStruct.status='fail'>
						<cfset myStruct.message='unable to find parent term'>
						<cfset myStruct.child=thisID.QVAL>
						<cfset myStruct.parent=-1>
					</cfif>
				</cfif>
				<cfreturn myStruct>
			<cfcatch>
				<!----
				<cfdump var=#cfcatch#>
				---->
				<cfset myStruct = {}>
				<cfset myStruct.status='fail'>
				<cfset myStruct.message=cfcatch.message & cfcatch.detail>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>

<!--------------------------------------------------------------------------------------->

	<cffunction name="getHierSearch" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="hierarchy_id" type="numeric" required="true"/>
	   <cfargument name="schtrm" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<!---- https://goo.gl/TWqGAo is the quest for a better query. For now, ugly though it be..... ---->
		<cfoutput>
			<cftry>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						coalesce(parent_term_id,0) parent_term_id,
						hierarchy_term_id,
						term,
						rank
					from hierarchy_term
					where term like '%#schtrm#%'
					order by parent_term_id
				</cfquery>
				<!--- cf's query-->JSON is dumb and dhtmlxtree is too so....---->
				<cfset x="[">
				<cfset i=1>
				<cfloop query="d">
					<cfset x=x & '["#hierarchy_term_id#","#parent_term_id#","#term# (#rank#)"]'>
					<cfif i lt d.recordcount>
						<cfset x=x & ",">
					</cfif>
					<cfset i=i+1>
				</cfloop>
				<cfset x=x & "]">


				<cfreturn x>

	<cfcatch>
		<cfreturn 'ERROR: ' & cfcatch.message & ' ' & cfcatch.detail>
	</cfcatch>
		</cftry>

		</cfoutput>

	</cffunction>




<!--------------------------------------------------------------------------------------->
	<cffunction name="saveHierMetaEdit" access="remote">
		<!---- hierarchical taxonomy editor ---->
		 <cfargument name="q" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
	<cfoutput>
		<!----
			de-serialize q
			throw it in a query because easy
		---->
		<cfset qry=queryNew("qtrm,qval")>
		<cfloop list="#q#" delimiters="&?" index="i">
			<cfif listlen(i,"=") eq 2>
				<cfset t=listGetAt(i,1,"=")>
				<cfset v=listGetAt(i,2,"=")>
				<cfset queryAddRow(qry, {qtrm=t,qval=v})>
				<cfif isdefined("debug") and debug is 1>
					<p>
						---- added #t#===#v# to query
					</p>
				</cfif>
			</cfif>
		</cfloop>
		<cfif isdefined("debug") and debug is 1>
			<cfdump var=#qry#>
		</cfif>
		<!--- should always have this; fail if no --->
		<cfquery name="x" dbtype="query">
			select qval from qry where qtrm='hierarchy_term_id'
		</cfquery>
		<cfset hierarchy_term_id=x.qval>
		<cftry>
		<cftransaction>
			<cfloop query="qry">
				<cfif isdefined("debug") and debug is 1>
					<br>loopy @ #qtrm#
				</cfif>
				<cfif left(qtrm,15) is "nctermtype_new_">
					<!--- there should be a corresponding nctermvalue_new_1 ---->
					<cfset thisIndex=listlast(qtrm,"_")>
					<cfquery name="thisval" dbtype="query">
						select QVAL from qry where qtrm='nctermvalue_new_#thisIndex#'
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<br>nctermtype_new_
						<br>qval: #qval#
						<cfdump var=#thisval#>
						<br>thisval.qval: #thisval.qval#
						<br>not dead??
					</cfif>


					<cfquery name="insone" result="sfasdas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into hierarchy_supporting_term (
							hierarchy_term_id,
							TERM_TYPE,
							TERM_VALUE
						) values (
							#hierarchy_term_id#,
							'#qval#',
							'#URLDecode(thisval.qval)#'
						)
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<p>------------sfasdas dump-------</p>
						<cfdump var=#sfasdas#>
						<p>------------END sfasdas dump-------</p>
					</cfif>

				<cfelseif left(qtrm,11) is "nctermtype_">
					<cfif isdefined("debug") and debug is 1>
						<br>nctermtype_ ==== thisthing
						<br>qval: #qval#
						<br>still not dead??
					</cfif>
					<cfset thisIndex=listlast(qtrm,"_")>
					<cfquery name="thisval" dbtype="query">
						select QVAL from qry where qtrm='nctermvalue_#thisIndex#'
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<p>------------thisval dump-------</p>
						<cfdump var=#thisval#>
						<p>------------END thisval dump-------</p>
					</cfif>


					<cfif isdefined("debug") and debug is 1>
						<p>
							qval=============================================================>#qval#
						</p>
						<p>
							URLDecode(thisval.qval)===============================================>#URLDecode(thisval.qval)#
						</p>
					</cfif>


					<cfif URLDecode(thisval.qval) is "DELETE">
						<cfif isdefined("debug") and debug is 1>
							<p>
								delete from hierarchy_supporting_term where hierarchy_hierarchy_supporting_term_id=#thisIndex#
							</p>
						</cfif>
						<cfquery name="done" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from hierarchy_supporting_term where hierarchy_hierarchy_supporting_term_id=#thisIndex#
						</cfquery>
					<cfelse>
						<cfif isdefined("debug") and debug is 1>
							<p>
								update hierarchy_supporting_term set TERM_TYPE='#qval#',TERM_VALUE='#URLDecode(thisval.qval)#' where hierarchy_hierarchy_supporting_term_id=#thisIndex#
							</p>
						</cfif>
						<cfquery name="uone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update hierarchy_supporting_term set TERM_TYPE='#qval#',TERM_VALUE='#URLDecode(thisval.qval)#' where hierarchy_hierarchy_supporting_term_id=#thisIndex#
						</cfquery>
					</cfif>
					<!----
				<cfelseif qtrm is "newParentTermValue">
					<cfset nptv=qval>
					<cfif isdefined("debug") and debug is 1>
						<br>got nptv::#nptv#
					</cfif>
					---->
				<cfelseif qtrm is "rank">
					<cfif isdefined("debug") and debug is 1>
						<br>--------->updating rank to #URLDecode(qval)#
					</cfif>
					<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set rank=<cfqueryparam value = "#qval#" CFSQLType="CF_SQL_VARCHAR"> where hierarchy_term_id=#hierarchy_term_id#
					</cfquery>

				<cfelse>
					<cfif isdefined("debug") and debug is 1>
						<br>--------->#qtrm# is not handled
					</cfif>
				</cfif>
			</cfloop>
			<!----
			<!--- if we got in newParentTermValue, move the child --->
			<cfif isdefined("nptv") and len(nptv) gt 0>
				<cfif nptv is "root">
					<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set parent_term_id=null where hierarchy_term_id=#hierarchy_term_id#
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<br>set nptv status success
					</cfif>
					<cfset myStruct = {}>
					<cfset myStruct.status='success'>
					<cfset myStruct.child=hierarchy_term_id>
					<cfset myStruct.parent=0>
				<cfelse>
					<cfif isdefined("debug") and debug is 1>
						<br>got nptv
					</cfif>
					<cfquery name="thisID" dbtype="query">
						select QVAL from qry where QTRM='hierarchy_term_id'
					</cfquery>
					<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select * from hierarchy_term where term=<cfqueryparam value = "#URLDecode(nptv)#" CFSQLType="CF_SQL_VARCHAR"> and hierarchy_id in (select hierarchy_id from hierarchy_term where hierarchy_term_id=#hierarchy_term_id#)
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
					<p>-------------------==============================--------------------------- d dump</p>
						<cfdump var=#d#>
					</cfif>
					<!----

						---->
					<cfif d.recordcount is 1 and len(d.hierarchy_term_id) gt 0>
						<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update hierarchy_term set parent_term_id=#d.hierarchy_term_id# where hierarchy_term_id=#thisID.QVAL#
						</cfquery>
						<!--- return
							1) the parent; it's what we'll need to expand;
							2) the child so we can focus it
						---->
						<cfif isdefined("debug") and debug is 1>
							<br>set nptv status success
						</cfif>
						<cfset myStruct = {}>
						<cfset myStruct.status='success'>
						<cfset myStruct.child=thisID.QVAL>
						<cfset myStruct.parent=d.hierarchy_term_id>
					<cfelse>
						<cfif isdefined("debug") and debug is 1>
							<br>set nptv status fail
						</cfif>
						<!----
						<cfdump var=#d#>
						---->
						<cfset myStruct = {}>
						<cfset myStruct.status='fail'>
						<cfset myStruct.message='unable to find parent term'>
						<cfset myStruct.child=thisID.QVAL>
						<cfset myStruct.parent=-1>
					</cfif>
				</cfif>
			<cfelse>

				<cfif isdefined("debug") and debug is 1>
					<br>set NON-nptv status success
				</cfif>
				<!---- not changing parent, just return success. We'll be in the catch if the normal update failed --->
				<cfset myStruct = {}>
				<cfset myStruct.status='success'>
			</cfif>
			---->

			<cfset myStruct = {}>
			<cfset myStruct.status='success'>
		</cftransaction>
		<cfif isdefined("debug") and debug is 1>
			<br>returning this:<cfdump var=#myStruct#>
		</cfif>

		<cfreturn myStruct>
		<cfcatch>
			<!----
			<cfdump var=#cfcatch#>
			---->
			<cfset myStruct = {}>
			<cfset myStruct.status='fail'>
			<cfset myStruct.message=cfcatch.message & cfcatch.detail>
		</cfcatch>
		</cftry>

		</cfoutput>
	</cffunction>





<cffunction name="deleteHierTerm" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="id" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
			<cftransaction>

				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select * from hierarchy_term where hierarchy_term_id=#id#
				</cfquery>

				<cfquery name="deorphan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from hierarchy_supporting_term where hierarchy_term_id=#id#
				</cfquery>
				<cfif len(d.parent_term_id) is 0>
					<cfquery name="udc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set parent_term_id=NULL where parent_term_id=#id#
					</cfquery>
				<cfelse>
					<cfquery name="udc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set parent_term_id=#d.parent_term_id# where parent_term_id=#id#
					</cfquery>
				</cfif>
				<cfquery name="bye" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from hierarchy_term where hierarchy_term_id=#id#
				</cfquery>
			</cftransaction>
			<cfreturn 'success'>
			<cfcatch>
				<cfreturn 'FAIL: ' & cfcatch.message & '; ' & cfcatch.detail >
			</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="createHierTerm" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="id" type="numeric" required="true">
		<cfargument name="newChildTerm" type="string" required="true">
		<cfargument name="newChildTermRank" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cftry>
			<cfoutput>
				<cfif len(newChildTerm) is 0 or len(newChildTermRank) is 0>
					<cfthrow message="newChildTerm and newChildTermRank are required">
				</cfif>
			<cftransaction>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select * from hierarchy_term where hierarchy_term_id=#id#
				</cfquery>
				<cfquery result="insQ" name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into hierarchy_term (
						parent_term_id,
						term,
						rank,
						hierarchy_id
					) values (
						#id#,
						'#newChildTerm#',
						'#newChildTermRank#',
						#d.hierarchy_id#
					)
				</cfquery>
			</cftransaction>
			<cfset r={}>
			<cfset r.status='success'>
			<cfset r.parent_id=id>
			<cfset r.child_id=insQ.hierarchy_term_id>
			<cfreturn r>
		</cfoutput>
		<cfcatch>
			<cfset r={}>
			<cfset r.status='fail'>
			<cfset r.parent_id=id>
			<cfset r.child_id="">
			<cfset r.message=cfcatch.message & '; ' & cfcatch.detail>
			<cfreturn r>
		</cfcatch>
		</cftry>
	</cffunction>

<!--------------------------------------------------------------------------------------->
	<cffunction name="expandHierNode" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="hierarchy_id" type="numeric" required="true"/>
		<cfargument name="id" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select term,hierarchy_term_id,coalesce(parent_term_id,0) parent_term_id, rank from hierarchy_term where
					hierarchy_id=#hierarchy_id# and parent_term_id = #id# order by term
				</cfquery>
				<cfreturn d>
				<cfcatch>
					<cfreturn 'ERROR: ' & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="saveParentHierarchyUpdate" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="hierarchy_id" type="numeric" required="true"/>
		<cfargument name="hierarchy_term_id" type="numeric" required="true">
		<cfargument name="parent_term_id" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update hierarchy_term set
					parent_term_id=#parent_term_id# where
					hierarchy_id=#hierarchy_id# and
					hierarchy_term_id=#hierarchy_term_id#
				</cfquery>
				<cfreturn 'success'>
				<cfcatch>
					<cfreturn 'ERROR: ' & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getInitHierarchy" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="hierarchy_id" type="numeric" required="true"/>

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					coalesce(parent_term_id,0) as parent_term_id,
					hierarchy_term_id,
					term,
					rank
				from
					hierarchy_term
				where
					hierarchy_id=#hierarchy_id# and parent_term_id is null order by term
			</cfquery>


			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfset x=x & '[#hierarchy_term_id#,#parent_term_id#,"#term# (#rank#)"]'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">
			<cfreturn x>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->




<cffunction name="updateArctosLegalClassData_guts" access="public">
	<cfargument name="tid" type="numeric" required="true">
	<cfargument name="thisConcept" type="any" required="true">
	<cfif not isdefined("debug")>
			<cfset debug=false>
		</cfif>
		<cfoutput>
		<cftry>
			<cfset runstatus="SUCCESS">
			<cfif debug is true>
				<cfdump var=#thisConcept#>
			</cfif>

				<cfif isdefined("debug") and debug is true>
					<cfdump var=#thisConcept#>
				</cfif>
				<cfset thisID=thisConcept.id>
				<cfset thisName=thisConcept.full_name>
				<cfset thisNameRank=thisConcept.rank>

				<cftry>
					<cfset thisNameAuth=thisConcept.author_year>
				<cfcatch>
					<cfset thisNameAuth="">
				</cfcatch>
				</cftry>
				<cfset thisClassificationID=CreateUUID()>
				<cfset pic=1>
				<!---- flush all old 'legal' data ---->
				<cfquery name="flushOld" datasource="uam_god">
					delete from taxon_term where taxon_name_id=#tid# and source='Arctos Legal'
				</cfquery>
				<cfif structkeyexists(thisConcept,"higher_taxa")>
					<!---- OMFG it's not in order!! ---->
					<cfloop collection="#thisConcept.higher_taxa#" item="key">
						<cftry>
							<cfset "#key#"="#thisConcept.higher_taxa[key]#">
					    <cfcatch><!---- whatever, they don't have values sometimes --->
							<cfif isdefined("debug") and debug is true>
								<br>funky #key# probably undefined
							</cfif>
						</cfcatch>
					    </cftry>
					</cfloop>
				</cfif>

				<cfif isdefined("kingdom") and len(kingdom) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'kingdom',
							'#kingdom#',
							'Arctos Legal',
							#pic#,
							sysdate
						)
					</cfquery>
					<cfset pic=pic+1>
				</cfif>
				<cfif isdefined("phylum") and len(phylum) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'phylum',
							'#phylum#',
							'Arctos Legal',
							#pic#,
							sysdate
						)
					</cfquery>
					<cfset pic=pic+1>
				</cfif>

				<cfif isdefined("class") and len(class) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'class',
							'#class#',
							'Arctos Legal',
							#pic#,
							sysdate
						)
					</cfquery>
					<cfset pic=pic+1>
				</cfif>

				<cfif isdefined("order") and len(order) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'order',
							'#order#',
							'Arctos Legal',
							#pic#,
							sysdate
						)
					</cfquery>
					<cfset pic=pic+1>
				</cfif>

				<cfif isdefined("family") and len(family) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'family',
							'#family#',
							'Arctos Legal',
							#pic#,
							sysdate
						)
					</cfquery>
					<cfset pic=pic+1>
				</cfif>




				<!--- now the data from the name ---->
				<cfquery name="insC" datasource="uam_god">
					insert into taxon_term (
						TAXON_TERM_ID,
						TAXON_NAME_ID,
						CLASSIFICATION_ID,
						TERM_TYPE,
						TERM,
						SOURCE,
						POSITION_IN_CLASSIFICATION,
						LASTDATE
					) values (
						sq_TAXON_TERM_ID.nextval,
						#tid#,
						'#thisClassificationID#',
						'#lcase(thisNameRank)#',
						'#thisName#',
						'Arctos Legal',
						#pic#,
						sysdate
					)
				</cfquery>
				<!---- attribution ---->
				<cfquery name="insC" datasource="uam_god">
					insert into taxon_term (
						TAXON_TERM_ID,
						TAXON_NAME_ID,
						CLASSIFICATION_ID,
						TERM_TYPE,
						TERM,
						SOURCE,
						POSITION_IN_CLASSIFICATION,
						LASTDATE
					) values (
						sq_TAXON_TERM_ID.nextval,
						#tid#,
						'#thisClassificationID#',
						'citation',
						'UNEP (2019). The Species+ Website. Nairobi, Kenya. Compiled by UNEP-WCMC, Cambridge, UK. Available at: www.speciesplus.net. Accessed #dateformat(now(),"YYYY-MM-DD")#.',
						'Arctos Legal',
						NULL,
						sysdate
					)
				</cfquery>
				<!---- link ---->
				<cfquery name="insC" datasource="uam_god">
					insert into taxon_term (
						TAXON_TERM_ID,
						TAXON_NAME_ID,
						CLASSIFICATION_ID,
						TERM_TYPE,
						TERM,
						SOURCE,
						POSITION_IN_CLASSIFICATION,
						LASTDATE
					) values (
						sq_TAXON_TERM_ID.nextval,
						#tid#,
						'#thisClassificationID#',
						'source_authority',
						'<a href="https://speciesplus.net/##/taxon_concepts?taxonomy=cites_eu&taxon_concept_query=#thisName#&geo_entities_ids=&geo_entity_scope=cites&page=1">Species+</a>',
						'Arctos Legal',
						NULL,
						sysdate
					)
				</cfquery>
				<!---- author ---->
				<cfif len(thisNameAuth) gt 0>
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							sq_TAXON_TERM_ID.nextval,
							#tid#,
							'#thisClassificationID#',
							'author_text',
							'#thisNameAuth#',
							'Arctos Legal',
							NULL,
							sysdate
						)
					</cfquery>
				</cfif>

				<!---- CITES stuff ---->
				<cfif structkeyexists(thisConcept,"cites_listings")>
					<cfloop from="1" to ="#arraylen(thisConcept.cites_listings)#" index="cli">
						<cfset thisCitesAppendix=thisConcept.cites_listings[cli].appendix>
						<cftry>
							<cfset thisCitesAnno=thisConcept.cites_listings[cli].annotation>
						<cfcatch>
							<cfset thisCitesAnno="">
						</cfcatch>
						</cftry>
						<!----
						<br>thisCitesAppendix=#thisCitesAppendix#
						---->
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								sq_TAXON_TERM_ID.nextval,
								#tid#,
								'#thisClassificationID#',
								'CITES Appendix',
								'#thisCitesAppendix#',
								'Arctos Legal',
								NULL,
								sysdate
							)
						</cfquery>
						<cfif len(thisCitesAnno)>
							<cfquery name="insC" datasource="uam_god">
								insert into taxon_term (
									TAXON_TERM_ID,
									TAXON_NAME_ID,
									CLASSIFICATION_ID,
									TERM_TYPE,
									TERM,
									SOURCE,
									POSITION_IN_CLASSIFICATION,
									LASTDATE
								) values (
									sq_TAXON_TERM_ID.nextval,
									#tid#,
									'#thisClassificationID#',
									'CITES Annotation',
									'(Appendix #thisCitesAppendix#): #thisCitesAnno#',
									'Arctos Legal',
									NULL,
									sysdate
								)
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
				<!--- see if we can make some relationships --->
				<cfif structkeyexists(thisConcept,"synonyms")>
					<cfloop from="1" to ="#arraylen(thisConcept.synonyms)#" index="syi">
						<cfset thisSynonym=thisConcept.synonyms[syi].full_name>
						<cfquery name="rtid" datasource="uam_god">
							select taxon_name_id from taxon_name where scientific_name='#thisSynonym#'
						</cfquery>
						<cfif len(rtid.taxon_name_id) gt 0>
							<!---
								got it; see if the relationship exists
								https://github.com/ArctosDB/arctos/issues/1136
								we are using "synonym of" for everything, so just ignore type for this for now
							---->
							<cfquery name="er" datasource="uam_god">
								select
									count(*) c
								from
									taxon_relations
								where
									taxon_name_id=#tid# and
									related_taxon_name_id=#rtid.taxon_name_id#
							</cfquery>
							<cfif er.c is 0>
								<cfif debug is true>
									<br>creating relationship
								</cfif>
								<!--- create the relationship ---->
								<cfquery name="mkreln" datasource="uam_god">
									insert into taxon_relations (
										TAXON_RELATIONS_ID,
										TAXON_NAME_ID,
										RELATED_TAXON_NAME_ID,
										TAXON_RELATIONSHIP,
										RELATION_AUTHORITY,
										STALE_FG
									) values (
										sq_TAXON_RELATIONS_ID.nextval,
										#tid#,
										#rtid.taxon_name_id#,
										'synonym of',
										'Species+',
										1
									)
								</cfquery>
							</cfif>
							<!---- now see if the reciprocal exists --->
							<cfquery name="err" datasource="uam_god">
								select
									count(*) c
								from
									taxon_relations
								where
									taxon_name_id=#rtid.taxon_name_id# and
									related_taxon_name_id=#tid#
							</cfquery>
							<cfif debug is true>
								<br>err:::
								<cfdump var=#err#>
							</cfif>
							<cfif err.c is 0>
								<cfif debug is true>
									<br>creating reciprocal relationship
								</cfif>
								<!--- create the relationship ---->
								<cfquery name="mkreln" datasource="uam_god">
									insert into taxon_relations (
										TAXON_RELATIONS_ID,
										TAXON_NAME_ID,
										RELATED_TAXON_NAME_ID,
										TAXON_RELATIONSHIP,
										RELATION_AUTHORITY,
										STALE_FG
									) values (
										sq_TAXON_RELATIONS_ID.nextval,
										#rtid.taxon_name_id#,
										#tid#,
										'synonym of',
										'Species+',
										1
									)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
				<!--- see if we can make some common names --->
				<cfif structkeyexists(thisConcept,"common_names")>
					<cfloop from="1" to ="#arraylen(thisConcept.common_names)#" index="cni">
						<cfset thisCommonName=thisConcept.common_names[cni].name>
						<cfquery name="ckcmn" datasource="uam_god">
							select count(*) c from common_name where taxon_name_id=#tid# and common_name='#thisCommonName#'
						</cfquery>
						<cfif ckcmn.c is 0>
							<cfquery name="icmn" datasource="uam_god">
								insert into common_name (
									COMMON_NAME_ID,
									TAXON_NAME_ID,
									COMMON_NAME
								) values (
									sq_COMMON_NAME_ID.nextval,
									#tid#,
									'#thisCommonName#'
								)
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
				<!----
			</cfloop>
			---->
			<cfcatch>
				<cfset runstatus="FAIL">
				<cfif debug is true>
					<cfdump var=#cfcatch#>
					<cfset runstatus="#cfcatch#">
				</cfif>
			</cfcatch>
		</cftry>
		</cfoutput>
		<cfreturn runstatus>
	</cffunction>




<!--------------------------------------------------------------------------------------->
	<cffunction name="updateArctosLegalClassData" access="remote">
		<cfargument name="tid" type="numeric" required="true">
		<cfargument name="name" type="string" required="true">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfif not isdefined("debug")>
			<cfset debug=false>
		</cfif>
		<cfquery name="auth" datasource='uam_god'  cachedwithin="#createtimespan(0,0,60,0)#">
			select SPECIESPLUS_TOKEN from cf_global_settings
		</cfquery>
		<cfoutput>
		<cftry>
			<cfset runstatus="SUCCESS">
			<!---- get all concepts for the namestring --->
			<cfhttp result="ga" url="https://api.speciesplus.net/api/v1/taxon_concepts?name=#name#" method="get">
				<cfhttpparam type = "header" name = "X-Authentication-Token" value = "#auth.SPECIESPLUS_TOKEN#">
			</cfhttp>
			<cfif ga.statusCode is "200 OK" and len(ga.filecontent) gt 0 and isjson(ga.filecontent)>
				<cfset rslt=DeserializeJSON(ga.filecontent)>
				<cfif debug is true>
					<cfdump var=#rslt#>
				</cfif>
				<cfif arraylen(rslt.taxon_concepts) is 0>
					<cfreturn 'NO_DATA_FOUND'>
				</cfif>
				<cfloop from="1" to ="#arraylen(rslt.taxon_concepts)#" index="i">
					<cfset thisConcept=rslt.taxon_concepts[i]>
					<cfif isdefined("debug") and debug is true>
						<cfdump var=#thisConcept#>
					</cfif>
					<cfset thisID=thisConcept.id>
					<cfset thisName=thisConcept.full_name>
					<cfset thisNameRank=thisConcept.rank>

					<cftry>
						<cfset thisNameAuth=thisConcept.author_year>
					<cfcatch>
						<cfset thisNameAuth="">
					</cfcatch>
					</cftry>
					<cfset thisClassificationID=CreateUUID()>
					<cfset pic=1>
					<!---- flush all old 'legal' data ---->
					<cfquery name="flushOld" datasource="uam_god">
						delete from taxon_term where taxon_name_id=#tid# and source='Arctos Legal'
					</cfquery>
					<cfif structkeyexists(thisConcept,"higher_taxa")>
						<!---- OMFG it's not in order!! ---->
						<cfloop collection="#thisConcept.higher_taxa#" item="key">
							<cftry>
								<cfset "#key#"="#thisConcept.higher_taxa[key]#">
						    <cfcatch><!---- whatever, they don't have values sometimes --->
								<cfif isdefined("debug") and debug is true>
									<cfdump var=#cfcatch#>
								</cfif>
							</cfcatch>
						    </cftry>
						</cfloop>
					</cfif>

					<cfif isdefined("kingdom") and len(kingdom) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'kingdom',
								'#kingdom#',
								'Arctos Legal',
								#pic#,
								current_date
							)
						</cfquery>
						<cfset pic=pic+1>
					</cfif>
					<cfif isdefined("phylum") and len(phylum) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'phylum',
								'#phylum#',
								'Arctos Legal',
								#pic#,
								current_date
							)
						</cfquery>
						<cfset pic=pic+1>
					</cfif>

					<cfif isdefined("class") and len(class) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'class',
								'#class#',
								'Arctos Legal',
								#pic#,
								current_date
							)
						</cfquery>
						<cfset pic=pic+1>
					</cfif>

					<cfif isdefined("order") and len(order) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'order',
								'#order#',
								'Arctos Legal',
								#pic#,
								current_date
							)
						</cfquery>
						<cfset pic=pic+1>
					</cfif>

					<cfif isdefined("family") and len(family) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'family',
								'#family#',
								'Arctos Legal',
								#pic#,
								current_date
							)
						</cfquery>
						<cfset pic=pic+1>
					</cfif>




					<!--- now the data from the name ---->
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							nextval('sq_taxon_term_id'),
							#tid#,
							'#thisClassificationID#',
							'#lcase(thisNameRank)#',
							'#thisName#',
							'Arctos Legal',
							#pic#,
							current_date
						)
					</cfquery>
					<!---- attribution ---->
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							nextval('sq_taxon_term_id'),
							#tid#,
							'#thisClassificationID#',
							'citation',
							'UNEP (2019). The Species+ Website. Nairobi, Kenya. Compiled by UNEP-WCMC, Cambridge, UK. Available at: www.speciesplus.net. Accessed #dateformat(now(),"YYYY-MM-DD")#.',
							'Arctos Legal',
							NULL,
							current_date
						)
					</cfquery>
					<!---- link ---->
					<cfquery name="insC" datasource="uam_god">
						insert into taxon_term (
							TAXON_TERM_ID,
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM_TYPE,
							TERM,
							SOURCE,
							POSITION_IN_CLASSIFICATION,
							LASTDATE
						) values (
							nextval('sq_taxon_term_id'),
							#tid#,
							'#thisClassificationID#',
							'source_authority',
							'<a href="https://speciesplus.net/##/taxon_concepts?taxonomy=cites_eu&taxon_concept_query=#name#&geo_entities_ids=&geo_entity_scope=cites&page=1">Species+</a>',
							'Arctos Legal',
							NULL,
							current_date
						)
					</cfquery>
					<!---- author ---->
					<cfif len(thisNameAuth) gt 0>
						<cfquery name="insC" datasource="uam_god">
							insert into taxon_term (
								TAXON_TERM_ID,
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM_TYPE,
								TERM,
								SOURCE,
								POSITION_IN_CLASSIFICATION,
								LASTDATE
							) values (
								nextval('sq_taxon_term_id'),
								#tid#,
								'#thisClassificationID#',
								'author_text',
								'#thisNameAuth#',
								'Arctos Legal',
								NULL,
								current_date
							)
						</cfquery>
					</cfif>

					<!---- CITES stuff ---->
					<cfif structkeyexists(thisConcept,"cites_listings")>
						<cfloop from="1" to ="#arraylen(thisConcept.cites_listings)#" index="cli">
							<cfset thisCitesAppendix=thisConcept.cites_listings[cli].appendix>
							<cftry>
								<cfset thisCitesAnno=thisConcept.cites_listings[cli].annotation>
							<cfcatch>
								<cfset thisCitesAnno="">
							</cfcatch>
							</cftry>
							<!----
							<br>thisCitesAppendix=#thisCitesAppendix#
							---->
							<cfquery name="insC" datasource="uam_god">
								insert into taxon_term (
									TAXON_TERM_ID,
									TAXON_NAME_ID,
									CLASSIFICATION_ID,
									TERM_TYPE,
									TERM,
									SOURCE,
									POSITION_IN_CLASSIFICATION,
									LASTDATE
								) values (
									nextval('sq_taxon_term_id'),
									#tid#,
									'#thisClassificationID#',
									'CITES Appendix',
									'#thisCitesAppendix#',
									'Arctos Legal',
									NULL,
									current_date
								)
							</cfquery>
							<cfif len(thisCitesAnno)>
								<cfquery name="insC" datasource="uam_god">
									insert into taxon_term (
										TAXON_TERM_ID,
										TAXON_NAME_ID,
										CLASSIFICATION_ID,
										TERM_TYPE,
										TERM,
										SOURCE,
										POSITION_IN_CLASSIFICATION,
										LASTDATE
									) values (
										nextval('sq_taxon_term_id'),
										#tid#,
										'#thisClassificationID#',
										'CITES Annotation',
										'(Appendix #thisCitesAppendix#): #thisCitesAnno#',
										'Arctos Legal',
										NULL,
										current_date
									)
								</cfquery>
							</cfif>
						</cfloop>
					</cfif>
					<!--- see if we can make some relationships --->
					<cfif structkeyexists(thisConcept,"synonyms")>
						<cfloop from="1" to ="#arraylen(thisConcept.synonyms)#" index="syi">
							<cfset thisSynonym=thisConcept.synonyms[syi].full_name>
							<cfquery name="rtid" datasource="uam_god">
								select taxon_name_id from taxon_name where scientific_name='#thisSynonym#'
							</cfquery>
							<cfif len(rtid.taxon_name_id) gt 0>
								<!---
									got it; see if the relationship exists
									https://github.com/ArctosDB/arctos/issues/1136
									we are using "synonym of" for everything, so just ignore type for this for now
								---->
								<cfquery name="er" datasource="uam_god">
									select
										count(*) c
									from
										taxon_relations
									where
										taxon_name_id=#tid# and
										related_taxon_name_id=#rtid.taxon_name_id#
								</cfquery>
								<cfif er.c is 0>
									<cfif debug is true>
										<br>creating relationship
									</cfif>
									<!--- create the relationship ---->
									<cfquery name="mkreln" datasource="uam_god">
										insert into taxon_relations (
											TAXON_RELATIONS_ID,
											TAXON_NAME_ID,
											RELATED_TAXON_NAME_ID,
											TAXON_RELATIONSHIP,
											RELATION_AUTHORITY,
											STALE_FG
										) values (
											nextval('sq_TAXON_RELATIONS_ID'),
											#tid#,
											#rtid.taxon_name_id#,
											'synonym of',
											'Species+',
											1
										)
									</cfquery>
								</cfif>
								<!---- now see if the reciprocal exists --->
								<cfquery name="err" datasource="uam_god">
									select
										count(*) c
									from
										taxon_relations
									where
										taxon_name_id=#rtid.taxon_name_id# and
										related_taxon_name_id=#tid#
								</cfquery>
								<cfif debug is true>
									<br>err:::
									<cfdump var=#err#>
								</cfif>
								<cfif err.c is 0>
									<cfif debug is true>
										<br>creating reciprocal relationship
									</cfif>
									<!--- create the relationship ---->
									<cfquery name="mkreln" datasource="uam_god">
										insert into taxon_relations (
											TAXON_RELATIONS_ID,
											TAXON_NAME_ID,
											RELATED_TAXON_NAME_ID,
											TAXON_RELATIONSHIP,
											RELATION_AUTHORITY,
											STALE_FG
										) values (
											nextval('sq_TAXON_RELATIONS_ID'),
											#rtid.taxon_name_id#,
											#tid#,
											'synonym of',
											'Species+',
											1
										)
									</cfquery>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<!--- see if we can make some common names --->
					<cfif structkeyexists(thisConcept,"common_names")>
						<cfloop from="1" to ="#arraylen(thisConcept.common_names)#" index="cni">
							<cfset thisCommonName=thisConcept.common_names[cni].name>
							<cfquery name="ckcmn" datasource="uam_god">
								select count(*) c from common_name where taxon_name_id=#tid# and common_name='#thisCommonName#'
							</cfquery>
							<cfif ckcmn.c is 0>
								<cfquery name="icmn" datasource="uam_god">
									insert into common_name (
										COMMON_NAME_ID,
										TAXON_NAME_ID,
										COMMON_NAME
									) values (
										nextval('sq_COMMON_NAME_ID'),
										#tid#,
										'#thisCommonName#'
									)
								</cfquery>
							</cfif>
						</cfloop>
					</cfif>
				</cfloop>

			<cfelse>
				<cfset runstatus="FAIL">
			</cfif>
			<cfcatch>
				<cfset runstatus="FAIL">
				<cfif debug is true>
					<cfdump var=#cfcatch#>
				</cfif>
			</cfcatch>

		</cftry>
		</cfoutput>
		<cfreturn runstatus>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	
<!--------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------->
	<cffunction name="getDisplayClassData" access="remote">
		<cfargument name="taxon_name_id" type="numeric" required="true">
		 <!---- public---->

		<cfquery name="raw" datasource="uam_god">
			select
				TERM,
				TERM_TYPE,
				SOURCE,
				CLASSIFICATION_ID,
				TAXON_NAME_ID
			from
				taxon_term
			where
				SOURCE in (select SOURCE from CTTAXONOMY_SOURCE) and
				term_type in ('taxon_status','display_name') and
				TAXON_NAME_ID=#val(taxon_name_id)#
		</cfquery>
		<cfquery name="dcid" dbtype="query">
			select CLASSIFICATION_ID, TAXON_NAME_ID, SOURCE from raw
			 group by CLASSIFICATION_ID,TAXON_NAME_ID,SOURCE
			 order by
				source,
				classification_id
		</cfquery>
		<cfoutput>
			<cfset d='<div class="taxNameMeta">'>
			<cfloop query="dcid">
				<cfset d=d & '<div class="taxNameOne">'>
				<cfset d=d & '<div>Source: #dcid.source#</div>'>
				<cfquery name="dv" dbtype="query">
					select TERM from raw where CLASSIFICATION_ID='#CLASSIFICATION_ID#' and term_type='display_name'
				</cfquery>
				<cfloop query="dv">
					<cfset d=d & '<div>Display Name: #dv.term#</div>'>
				</cfloop>
				<cfquery name="ts" dbtype="query">
					select TERM from raw where CLASSIFICATION_ID='#CLASSIFICATION_ID#' and term_type='taxon_status'
				</cfquery>
				<cfloop query="ts">
					<cfset d=d & '<div>Taxon Status: #ts.term#</div>'>
				</cfloop>
				<cfset d=d & '</div>'>
			</cfloop>
			<cfset d=d & '</div>'>
		</cfoutput>
		<cfreturn d>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getRelatedTaxa" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="TAXON_NAME_ID" type="numeric" required="true">
		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cfquery name="related" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					TAXON_RELATIONSHIP,
					RELATION_AUTHORITY,
					a.scientific_name related_name,
					b.scientific_name this_name
				from
					taxon_relations,
					taxon_name a,
					taxon_name b
				where
					taxon_relations.related_taxon_name_id=a.taxon_name_id and
					taxon_relations.taxon_name_id=b.taxon_name_id and
					taxon_relations.taxon_name_id=#taxon_name_id#
			</cfquery>
			<cfquery name="revrelated" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					TAXON_RELATIONSHIP,
					RELATION_AUTHORITY,
					b.scientific_name related_name ,
					a.scientific_name this_name
				from
					taxon_relations,
					taxon_name a,
					taxon_name b
				where
					taxon_relations.related_taxon_name_id=a.taxon_name_id and
					taxon_relations.taxon_name_id=b.taxon_name_id and
					taxon_relations.related_taxon_name_id=#taxon_name_id#
			</cfquery>
			<cfset d=queryNew('relationship')>
		    <cfloop query="related">
			  	<cfset tr='#this_name# &##8594; #TAXON_RELATIONSHIP# &##8594; <a target="_blank" href="/name/#related_name#">#related_name#</a>'>
		        <cfif len(RELATION_AUTHORITY) gt 0>
					<cfset tr=tr & " (Authority: #RELATION_AUTHORITY#)">
				</cfif>
				<cfset queryAddRow(d,{relationship="#tr#"})>
		     </cfloop>
		 <cfloop query="revrelated">
				<cfset tr='<a target="_blank" href="/name/#related_name#">#related_name#</a>  &##8594; #TAXON_RELATIONSHIP# &##8594; #this_name#'>
		        <cfif len(RELATION_AUTHORITY) gt 0>
					<cfset tr=tr & " (Authority: #RELATION_AUTHORITY#)">
				</cfif>
				<cfset queryAddRow(d,{relationship="#tr#"})>
		     </cfloop>
			<cfreturn d>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getTaxonStatus" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="taxon_name_id" type="numeric" required="true">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
		<cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
			<cfthrow message="unauthorized">
		</cfif>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#"  cachedwithin="#createtimespan(0,0,60,0)#">
				select term, source from taxon_term where term_type='taxon_status' and taxon_name_id=#taxon_name_id# group by term, source order by term, source
			</cfquery>
			<cfset x="">
			<cfloop query="d">
				<cfset x=listappend(x,'#term# (#source#)',';')>
			</cfloop>
			<cfset result.status="success">
			<cfset result.taxon_name_id=taxon_name_id>
			<cfset result.taxon_status=x>
			<cfreturn result>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------->
	<cffunction name="validateName" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="taxon_name" type="string" required="true">
		<cfargument name="name_type" type="string" required="false" default="Linnean">
		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
	    <cfif name_type neq "Linnean">
	    	<cfset result.consensus="cannot validate name_type=#name_type#">
	    	<cfreturn result>
	    </cfif>
		<cfoutput>
			<cfset result.consensus="probably_not_valid">
			<cfhttp url="https://www.wikidata.org/w/api.php?action=wbsearchentities&search=#taxon_name#&language=en&format=json" method="get" timeout="5">
			<cfif isdefined("debug") and debug is true>
				<p>https://www.wikidata.org/w/api.php?action=wbsearchentities&search=#taxon_name#&language=en&format=json</p>
				<cfdump var=#cfhttp#>
			</cfif>
			<cfif cfhttp.filecontent contains '"search":[]'>
				<cfset result.wiki='not_found'>
			<cfelse>
				<cfset result.wiki='found'>
				<cfset result.consensus="might_be_valid">
			</cfif>

			<cfhttp url="http://gni.globalnames.org/name_strings.json?search_term=exact:#taxon_name#" method="get"  timeout="5">
			</cfhttp>

			<cfif isdefined("debug") and debug is true>
				<p>http://gni.globalnames.org/name_strings.json?search_term=exact:#taxon_name#</p>
				<cfdump var=#cfhttp#>
			</cfif>
			<cfif cfhttp.filecontent contains '"name_strings_total":0'>
				<cfset result.gni='not_found'>
			<cfelse>
				<cfset result.gni='found'>
				<cfset result.consensus="might_be_valid">
			</cfif>

			<cfhttp url="http://www.marinespecies.org/rest/AphiaIDByName/#taxon_name#?marine_only=false" method="get"  timeout="5">
				<cfhttpparam type="header" name="accept" value="application/json">
			</cfhttp>

			<cfif isdefined("debug") and debug is true>
				<p>http://www.marinespecies.org/rest/AphiaIDByName/#taxon_name#?marine_only=false</p>
				<cfdump var=#cfhttp#>
			</cfif>


			<cfif len(cfhttp.filecontent) gt 0 and cfhttp.filecontent does not contain "Not found">
				<cfset result.worms='found'>
				<cfset result.consensus="might_be_valid">
			<cfelse>
				<cfset result.worms='not_found'>
			</cfif>


			<cfhttp url="http://eol.org/api/search/1.0.json?page=1&q=/#taxon_name#&exact=true" method="get"  timeout="5">
				<cfhttpparam type="header" name="accept" value="application/json">
			</cfhttp>

			<cfif isdefined("debug") and debug is true>
				<p>http://eol.org/api/search/1.0.json?page=1&q=#taxon_name#&exact=true</p>
				<cfdump var=#cfhttp#>
			</cfif>

			<cfif cfhttp.filecontent contains '"totalResults":0'>
				<cfset result.eol='not_found'>
			<cfelse>
				<cfset result.eol='found'>
				<cfset result.consensus="might_be_valid">
			</cfif>

			<cfhttp url="http://api.gbif.org/v1/species?strict=true&name=#taxon_name#&nameType=scientific" method="get"  timeout="5">
				<cfhttpparam type="header" name="accept" value="application/json">
			</cfhttp>

			<cfif isdefined("debug") and debug is true>
				<p>http://api.gbif.org/v1/species?strict=true&name=#taxon_name#&nameType=scientific</p>
				<cfdump var=#cfhttp#>
			</cfif>

			<cfif cfhttp.filecontent contains '"results":[]'>
				<cfset result.gbif='not_found'>
			<cfelse>
				<cfset result.gbif='found'>
				<cfset result.consensus="might_be_valid">
			</cfif>


			<cfhttp url="http://zoobank.org/NomenclaturalActs.json/#replace(taxon_name,' ','_')#" method="get"  timeout="5">
				<cfhttpparam type="header" name="accept" value="application/json">
			</cfhttp>


			<cfif cfhttp.filecontent contains '"status_code":200'>
				<cfset result.zoobank='found'>
				<cfset result.consensus="might_be_valid">
			<cfelse>
				<cfset result.zoobank='not_found'>
			</cfif>


			<cfif isdefined("debug") and debug is true>
				<p>http://zoobank.org/NomenclaturalActs.json/#replace(taxon_name,' ','_')#c</p>
				<cfdump var=#cfhttp#>
			</cfif>




			<cfreturn result>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="deleteSeed" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="tid" type="string" required="true">
		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into htax_markdeletetree (
					seed_tid,
					seed_term,
					username,
					delete_id,
					status
				) (
					select
						#tid#,
						term,
						'#session.username#',
						SYS_GUID(),
						'mark_to_delete'
					from
						hierarchical_taxonomy
					where
						tid=#tid#
				)
			</cfquery>
			<cfreturn 'success'>
			<cfcatch>
				<cfreturn 'ERROR: ' & cfcatch.message>
			</cfcatch>
			</cftry>
			<!----

			---->
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="exportSeed" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="tid" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into htax_export (
					dataset_id,
					seed_term,
					username,
					status,
					export_id
				) (
					select
						dataset_id,
						term,
						'#session.username#',
						'mark_to_export',
						SYS_GUID()
					from
						hierarchical_taxonomy
					where
						tid=#tid#
				)
			</cfquery>
			<cfreturn 'success'>
			<cfcatch>
				<cfreturn 'ERROR: ' & cfcatch.message>
			</cfcatch>
			</cftry>
			<!----

			---->
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="consistencyCheck" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="term" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					taxon_term.term_type,
					count(*) timesUsed
				from
					taxon_name,
					taxon_term,
					CTTAXONOMY_SOURCE
				where
					taxon_name.taxon_name_id=taxon_term.taxon_name_id and
					taxon_term.source=CTTAXONOMY_SOURCE.source and
					taxon_term.position_in_classification is not null and
					-- exclude usage as name
					taxon_term.term_type != 'scientific_name' and
					taxon_term.term='#term#'
				group by taxon_term.term_type
				order by count(*)
			</cfquery>
			<cfreturn d>
		</cfoutput>
	</cffunction>
<!----------------------------------------------
	<cffunction name="moveTermNewParent" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="id" type="numeric" required="true">
		<cfargument name="term" type="string" required="true">
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from hierarchical_taxonomy where term='#term#'
			</cfquery>
			<cfif d.recordcount is 1 and len(d.tid) gt 0>
				<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update hierarchical_taxonomy set parent_tid=#d.tid# where tid=#id#
				</cfquery>
				<!--- return
					1) the parent; it's what we'll need to expand;
					2) the child so we can focus it
				---->
				<cfset myStruct = {}>
				<cfset myStruct.status='success'>
				<cfset myStruct.child=id>
				<cfset myStruct.parent=d.tid>

			<cfelse>
				<cfset myStruct = {}>
				<cfset myStruct.status='fail'>
				<cfset myStruct.child=id>
				<cfset myStruct.parent=-1>
			</cfif>
			<cfreturn myStruct>
		</cfoutput>
	</cffunction>
----------------------------------------->
<!--------------------------------------------------------------------------------------->
	<cffunction name="createTerm" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="id" type="numeric" required="true">
		<cfargument name="newChildTerm" type="string" required="true">
		<cfargument name="newChildTermRank" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cftry>
			<cfoutput>
				<cfif len(newChildTerm) is 0 or len(newChildTermRank) is 0>
					<cfthrow message="newChildTerm and newChildTermRank are required">
				</cfif>
			<cftransaction>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select * from hierarchical_taxonomy where tid=#id#
				</cfquery>
				<cfquery name="ntid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select nextval('somerandomsequence') ntid
				</cfquery>
				<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into hierarchical_taxonomy (
						TID,
						PARENT_TID,
						TERM,
						RANK,
						DATASET_ID
					) values (
						#ntid.ntid#,
						#id#,
						'#newChildTerm#',
						'#newChildTermRank#',
						#d.DATASET_ID#
					)
				</cfquery>
			</cftransaction>
			<cfset r={}>
			<cfset r.status='success'>
			<cfset r.parent_id=id>
			<cfset r.child_id=ntid.ntid>
			<cfreturn r>
		</cfoutput>
		<cfcatch>
			<cfset r={}>
			<cfset r.status='fail'>
			<cfset r.parent_id=id>
			<cfset r.child_id="">
			<cfset r.message=cfcatch.message & '; ' & cfcatch.detail>
			<cfreturn r>
		</cfcatch>
		</cftry>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="deleteTerm" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="id" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
			<cftransaction>

				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select * from hierarchical_taxonomy where tid=#id#
				</cfquery>

				<cfquery name="deorphan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from htax_noclassterm where tid=#id#
				</cfquery>
				<cfif len(d.PARENT_TID) is 0>
					<cfquery name="udc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchical_taxonomy set PARENT_TID=NULL where parent_tid=#id#
					</cfquery>
				<cfelse>
					<cfquery name="udc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchical_taxonomy set PARENT_TID=#d.PARENT_TID# where parent_tid=#id#
					</cfquery>
				</cfif>
				<cfquery name="bye" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from hierarchical_taxonomy where tid=#id#
				</cfquery>
			</cftransaction>
			<cfreturn 'success'>
			<cfcatch>
				<cfreturn 'FAIL: ' & cfcatch.message & '; ' & cfcatch.detail >
			</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="saveMetaEdit" access="remote">
		<!---- hierarchical taxonomy editor ---->
		 <cfargument name="q" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
	<cfoutput>
		<!----
			de-serialize q
			throw it in a query because easy
		---->
		<cfset qry=queryNew("qtrm,qval")>
		<cfloop list="#q#" delimiters="&?" index="i">
			<cfif listlen(i,"=") eq 2>
				<cfset t=listGetAt(i,1,"=")>
				<cfset v=listGetAt(i,2,"=")>
				<cfset queryAddRow(qry, {qtrm=t,qval=v})>
			</cfif>
		</cfloop>
		<cfif isdefined("debug") and debug is 1>
			<cfdump var=#qry#>
		</cfif>
		<!--- should always have this; fail if no --->
		<cfquery name="x" dbtype="query">
			select qval from qry where qtrm='tid'
		</cfquery>
		<cfset tid=x.qval>
		<cftry>
		<cftransaction>
			<cfloop query="qry">
				<cfif isdefined("debug") and debug is 1>
					<br>loopy @ #qtrm#
				</cfif>
				<cfif left(qtrm,15) is "nctermtype_new_">
					<!--- there should be a corresponding nctermvalue_new_1 ---->
					<cfset thisIndex=listlast(qtrm,"_")>
					<cfquery name="thisval" dbtype="query">
						select QVAL from qry where qtrm='nctermvalue_new_#thisIndex#'
					</cfquery>
					<cfif isdefined("debug") and debug is 1>
						<br>nctermtype_new_
						<br>qval: #qval#
						<br>thisval.qval: #thisval.qval#
					</cfif>
					<cfquery name="insone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into htax_noclassterm (
							NC_TID,
							TID,
							TERM_TYPE,
							TERM_VALUE
						) values (
							nextval('somerandomsequence'),
							#tid#,
							'#qval#',
							'#URLDecode(thisval.qval)#'
						)
					</cfquery>
				<cfelseif left(qtrm,11) is "nctermtype_">
					<cfif isdefined("debug") and debug is 1>
						<br>nctermtype_
						<br>qval: #qval#
						<br>thisval.qval: #thisval.qval#
					</cfif>
					<cfset thisIndex=listlast(qtrm,"_")>
					<cfquery name="thisval" dbtype="query">
						select QVAL from qry where qtrm='nctermvalue_#thisIndex#'
					</cfquery>
					<cfif QVAL is "DELETE">
						<cfquery name="done" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from htax_noclassterm where NC_TID=#thisIndex#
						</cfquery>
					<cfelse>
						<cfquery name="uone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update htax_noclassterm set TERM_TYPE='#qval#',TERM_VALUE='#URLDecode(thisval.qval)#' where NC_TID=#thisIndex#
						</cfquery>
					</cfif>
				<cfelseif qtrm is "newParentTermValue">
					<cfset nptv=qval>
				</cfif>
			</cfloop>
			<!--- if we got in newParentTermValue, move the child --->
			<cfif isdefined("nptv") and len(nptv) gt 0>
				<cfif isdefined("debug") and debug is 1>
					<br>got nptv
				</cfif>
				<cfquery name="thisID" dbtype="query">
					select QVAL from qry where QTRM='tid'
				</cfquery>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select * from hierarchical_taxonomy where term='#nptv#' and dataset_id in (select dataset_id from hierarchical_taxonomy where tid=#tid#)
				</cfquery>
				<!----
					<cfdump var=#d#>
					---->
				<cfif d.recordcount is 1 and len(d.tid) gt 0>
					<cfquery name="np" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchical_taxonomy set parent_tid=#d.tid# where tid=#thisID.QVAL#
					</cfquery>
					<!--- return
						1) the parent; it's what we'll need to expand;
						2) the child so we can focus it
					---->
					<cfif isdefined("debug") and debug is 1>
						<br>set nptv status success
					</cfif>
					<cfset myStruct = {}>
					<cfset myStruct.status='success'>
					<cfset myStruct.child=thisID.QVAL>
					<cfset myStruct.parent=d.tid>
				<cfelse>
					<cfif isdefined("debug") and debug is 1>
						<br>set nptv status fail
					</cfif>
					<!----
					<cfdump var=#d#>
					---->
					<cfset myStruct = {}>
					<cfset myStruct.status='fail'>
					<cfset myStruct.message='unable to find parent term'>
					<cfset myStruct.child=thisID.QVAL>
					<cfset myStruct.parent=-1>
				</cfif>
			<cfelse>

				<cfif isdefined("debug") and debug is 1>
					<br>set NON-nptv status success
				</cfif>
				<!---- not changing parent, just return success. We'll be in the catch if the normal update failed --->
				<cfset myStruct = {}>
				<cfset myStruct.status='success'>
			</cfif>

		</cftransaction>
		<cfif isdefined("debug") and debug is 1>
			<br>returning this:<cfdump var=#myStruct#>
		</cfif>

		<cfreturn myStruct>
		<cfcatch>
			<!----
			<cfdump var=#cfcatch#>
			---->
			<cfset myStruct = {}>
			<cfset myStruct.status='fail'>
			<cfset myStruct.message=cfcatch.message & cfcatch.detail>
		</cfcatch>
		</cftry>

		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getSeedTaxSum" access="remote">
		<!---- hierarchical taxonomy editor ---->
		 <cfargument name="source" type="string" required="false">
	   <cfargument name="kingdom" type="string" required="false">
	   <cfargument name="phylum" type="string" required="false">
	   <cfargument name="class" type="string" required="false">
	   <cfargument name="order" type="string" required="false">
	   <cfargument name="family" type="string" required="false">
	   <cfargument name="genus" type="string" required="false">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>



		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					count(distinct(scientific_name)) c
				from
					taxon_name,
					taxon_term
				where
					taxon_name.taxon_name_id=taxon_term.taxon_name_id and
					taxon_term.source='#source#'
					<cfif len(kingdom) gt 0>
						and term_type='kingdom' and term='#kingdom#'
					</cfif>
					<cfif len(phylum) gt 0>
						and term_type='phylum' and term='#phylum#'
					</cfif>
					<cfif len(class) gt 0>
						and term_type='class' and term='#class#'
					</cfif>
					<cfif len(order) gt 0>
						and term_type='order' and term='#order#'
					</cfif>
					<cfif len(family) gt 0>
						and term_type='family' and term='#family#'
					</cfif>
					<cfif len(genus) gt 0>
						and term_type='genus' and term='#genus#'
					</cfif>
			</cfquery>
			<cfreturn d>
		</cfoutput>

	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="saveParentUpdate" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="dataset_id" type="numeric" required="true"/>
		<cfargument name="tid" type="numeric" required="true">
		<cfargument name="parent_tid" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update hierarchical_taxonomy set parent_tid=#parent_tid# where
					dataset_id=#dataset_id# and tid=#tid#
				</cfquery>
				<cfreturn 'success'>
				<cfcatch>
					<cfreturn 'ERROR: ' & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getTaxTreeChild" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="dataset_id" type="numeric" required="true"/>
		<cfargument name="id" type="numeric" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cftry>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select term,tid,coalesce(parent_tid,0) parent_tid, rank from hierarchical_taxonomy where
					dataset_id=#dataset_id# and parent_tid = #id# order by term
				</cfquery>
				<cfreturn d>
				<cfcatch>
					<cfreturn 'ERROR: ' & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->

	<cffunction name="getTaxTreeSrch" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="dataset_id" type="numeric" required="true"/>
	   <cfargument name="q" type="string" required="true">

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<!---- https://goo.gl/TWqGAo is the quest for a better query. For now, ugly though it be..... ---->
		<cfoutput>
			<cftry>
				<!--- temp key ---->
				<cfset key=RandRange(1, 99999999)>
				<!--- build rows in Oracle ---->
				<cfstoredproc procedure="proc_htax_srch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					<cfprocparam cfsqltype="cf_sql_varchar" value="#dataset_id#"><!---- v_container_id ---->
					<cfprocparam cfsqltype="cf_sql_varchar" value="#q#"><!---- v_parent_container_id ---->
					<cfprocparam cfsqltype="cf_sql_varchar" value="#key#"><!---- v_container_type ---->
				</cfstoredproc>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						coalesce(parent_tid,0) parent_tid,
						tid,
						term,
						rank
					from htax_srchhlpr
					where key=#key#
					order by parent_tid
				</cfquery>
				<!--- cf's query-->JSON is dumb and dhtmlxtree is too so....---->
				<cfset x="[">
				<cfset i=1>
				<cfloop query="d">
					<cfset x=x & '["#tid#","#parent_tid#","#term# (#rank#)"]'>
					<cfif i lt d.recordcount>
						<cfset x=x & ",">
					</cfif>
					<cfset i=i+1>
				</cfloop>
				<cfset x=x & "]">

				<!--- now clean up, because we're cool like that ---->
				<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from htax_srchhlpr where key=#key#
				</cfquery>


				<cfreturn x>

	<cfcatch>
		<cfreturn 'ERROR: ' & cfcatch.message & ' ' & cfcatch.detail>
	</cfcatch>
		</cftry>

		</cfoutput>

	</cffunction>
<!--------------------------------------------------------------------------------------->
	<cffunction name="getInitTaxTree" access="remote">
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="dataset_id" type="numeric" required="true"/>

		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select coalesce(parent_tid,0) parent_tid, term,tid,rank from hierarchical_taxonomy where
				dataset_id=#dataset_id# and parent_tid is null order by term
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfset x=x & '["#tid#","#parent_tid#","#term# (#rank#)"]'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">
			<cfreturn x>
		</cfoutput>
	</cffunction>
<!--------------------------------------------------------------------------------------->

<!--------------------------------------------------------------------------------------->
	<cffunction name="checkConsistency" access="remote">
		deprecated<cfabort>
		<!------------
		<!---- hierarchical taxonomy editor ---->
		<cfargument name="tid" type="numeric" required="true">
		<cfargument name="cid" type="string" required="true">
		<cfoutput>
			<br>tid:#tid#
			<br>cid:#cid#


			<cfquery name="cttaxon_term" datasource="uam_god">
				select RELATIVE_POSITION,TAXON_TERM from  cttaxon_term where IS_CLASSIFICATION=1
			</cfquery>
			<cfquery name="taxon" datasource="uam_god">
				select scientific_name from taxon_name where taxon_name_id=#tid#
			</cfquery>
			<cfquery name="source" datasource="uam_god">
				select distinct source from taxon_term where  classification_id='#cid#' and taxon_name_id=#tid#
			</cfquery>
			<cfdump var=#source#>
			<cfquery name="d" datasource="uam_god">
				select TERM,TERM_TYPE,POSITION_IN_CLASSIFICATION from taxon_term where POSITION_IN_CLASSIFICATION is not null and taxon_name_id=#tid# and classification_id='#cid#' order by POSITION_IN_CLASSIFICATION desc
			</cfquery>
			<cfloop query="d">
				<br>#TERM_type# #term#
				<cfif TERM_type is "species" or TERM_type is "genus">
					<!----
					<cfquery name="rAbsPosn" dbtype="query">
						select RELATIVE_POSITION from cttaxon_term where TAXON_TERM='#TERM_type#'
					</cfquery>
					<!---- copy of the query that we cna diff --->
					<cfquery name="rJSON" dbtype="query">
						select  TERM,TERM_TYPE from d order by POSITION_IN_CLASSIFICATION
					</cfquery>
					<cfset rJsonStr=SerializeJSON(rJSON)>
					---->


					<!---- find any lower terms --->
					<cfquery name="ssp" datasource="uam_god">
						select scientific_name, taxon_name_id from taxon_name where scientific_name like '#term# %'
					</cfquery>
					<cfdump var=#ssp#>
					<cfloop query="ssp">
						<cfquery name="sspdata" datasource="uam_god">
							select TERM,TERM_TYPE,POSITION_IN_CLASSIFICATION from taxon_term where POSITION_IN_CLASSIFICATION is not null and
							taxon_name_id=#ssp.taxon_name_id# and source='#source.source#'
							 order by POSITION_IN_CLASSIFICATION desc
						</cfquery>
						<cfdump var=#sspdata#>
						<!---- get the relative position of the term we're working from ---->
						<cfquery name="thisRelPos" dbtype="query">
							select POSITION_IN_CLASSIFICATION from sspdata where term_type='#d.TERM_TYPE#'
						</cfquery>

						<cfdump var=#thisRelPos#>
						<!----
						<cfdump var=#thisRelPos#>

						<cfloop query="sspdata">
							<cfquery name="rAbsPosn" dbtype="query">
								select RELATIVE_POSITION from cttaxon_term where TAXON_TERM='#TERM_type#'
							</cfquery>

						</cfloop>
						---------->
					</cfloop>
				</cfif>
			</cfloop>


			<cfdump var=#d#>
		</cfoutput>
		---------->
	</cffunction>
</cfcomponent>