<cfcomponent>
<!----------------------------------------------------------------------------------------->
<cffunction name="deleteTag" access="remote">
	<cfargument name="tag_id" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from tag where tag_id=<cfqueryparam value="#tag_id#" cfsqltype="cf_sql_int">
		</cfquery>
			<cfreturn "success">
		<cfcatch>
			<cfreturn "#cfcatch.message# #cfcatch.detail# #cfcatch.sql#">
		</cfcatch>
	</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getTagReln" access="remote" output="true">
    <cfargument name="tag_id" required="true" type="numeric">
	<cfoutput>
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				tag_id,
				media_id,
				reftop,
				refleft,
				refh,
				refw,
				imgh,
				imgw,
				remark,
				collection_object_id,
				collecting_event_id,
				locality_id,
				agent_id
			from tag where tag_id=<cfqueryparam value="#tag_id#" cfsqltype="cf_sql_int">
			order by
				collection_object_id,
				collecting_event_id,
				locality_id,
				agent_id,
				remark
		</cfquery>
		<cfif r.collection_object_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select guid from #session.flatTableName# where collection_object_id=<cfqueryparam value="#r.collection_object_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset rt="cataloged_item">
			<cfset rs="#d.guid#">
			<cfset ri="#r.collection_object_id#">
			<cfset rl="/guid/#d.guid#">
		<cfelseif r.collecting_event_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select verbatim_date, verbatim_locality from collecting_event where collecting_event_id=<cfqueryparam value="#r.collecting_event_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset rt="collecting_event">
			<cfset rs="#d.verbatim_locality# (#d.verbatim_date#)">
			<cfset ri="#r.collecting_event_id#">
			<cfset rl="/place.cfm?action=detail&collecting_event_id=#r.collecting_event_id#">
		<cfelseif r.agent_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select preferred_agent_name from agent where agent_id=<cfqueryparam value="#r.agent_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset rt="agent">
			<cfset rs="#d.preferred_agent_name#">
			<cfset ri="#r.agent_id#">
			<cfset rl="/agent/#r.agent_id#">
		<cfelseif r.locality_id gt 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select spec_locality from locality where locality_id=<cfqueryparam value="#r.locality_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset rt="locality">
			<cfset rs="#d.spec_locality#">
			<cfset ri="#r.locality_id#">
			<cfset rl="/place.cfm?action=detail&locality_id=#r.locality_id#">
		<cfelse>
			<cfset rt="comment">
			<cfset rs="">
			<cfset ri="">
			<cfset rl="">
		</cfif>
		<cfset rft = ArrayNew(1)>
		<cfset rfi = ArrayNew(1)>
		<cfset rfs = ArrayNew(1)>
		<cfset rfl = ArrayNew(1)>
		<cfset rft[1]=rt>
		<cfset rfi[1]=ri>
		<cfset rfs[1]=rs>
		<cfset rfl[1]=rl>
		<cfset temp = QueryAddColumn(r, "REFTYPE", "VarChar",rft)>
		<cfset temp = QueryAddColumn(r, "REFID", "Integer",rfi)>
		<cfset temp = QueryAddColumn(r, "REFSTRING", "VarChar",rfs)>
		<cfset temp = QueryAddColumn(r, "REFLINK", "VarChar",rfl)>
		<cfreturn r>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getTags" access="remote">
	<cfargument name="media_id" required="yes">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			tag_id
		from tag where media_id=<cfqueryparam value="#media_id#" cfsqltype="cf_sql_int">
	</cfquery>
	<cfset i=1>
	<cfloop query="data">
		<cfset "t#i#"=getTagReln(data.tag_id)>
		<cfset i=i+1>
	</cfloop>
	<cfif i gt 1>
		<cfset x=i-1>
		<cfquery name="q" dbtype="query">
			select * from t1
			<cfloop from="2" to="#x#" index="o">
				union select * from t#o#
			</cfloop>
		</cfquery>

		<cfreturn q>
	<cfelse>
		<cfreturn />
	</cfif>
</cffunction>
<!--------------------------------------->
<cffunction name="saveEdit" access="remote">
	<cfargument name="tag_id" required="yes">
	<cfargument name="reftype" required="yes">
	<cfargument name="remark" required="yes">
	<cfargument name="refid" required="yes">
	<cfargument name="reftop" required="yes">
	<cfargument name="refleft" required="yes">
	<cfargument name="refh" required="yes">
	<cfargument name="refw" required="yes">
	<cfargument name="imgh" required="yes">
	<cfargument name="imgw" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cftry>
		<cftransaction>
			<cfquery name="reset" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update tag set
					collection_object_id=NULL,
					collecting_event_id=NULL,
					locality_id=NULL,
					agent_id=NULL,
					remark=NULL
				where
					tag_id=<cfqueryparam value="#tag_id#" cfsqltype="cf_sql_int">
			</cfquery>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update tag set
					reftop=<cfqueryparam value="#reftop#" cfsqltype="cf_sql_int">,
					refleft=<cfqueryparam value="#refleft#" cfsqltype="cf_sql_int">,
					refh=<cfqueryparam value="#refh#" cfsqltype="cf_sql_int">,
					refw=<cfqueryparam value="#refw#" cfsqltype="cf_sql_int">,
					imgh=<cfqueryparam value="#imgh#" cfsqltype="cf_sql_int">,
					imgw=<cfqueryparam value="#imgw#" cfsqltype="cf_sql_int">
					<cfif reftype is "cataloged_item">
						,collection_object_id=<cfqueryparam value="#refid#" cfsqltype="cf_sql_int">
					<cfelseif reftype is "collecting_event">
						,collecting_event_id=<cfqueryparam value="#refid#" cfsqltype="cf_sql_int">
					<cfelseif reftype is "locality">
						,locality_id=<cfqueryparam value="#refid#" cfsqltype="cf_sql_int">
					<cfelseif reftype is "agent">
						,agent_id=<cfqueryparam value="#refid#" cfsqltype="cf_sql_int">
					</cfif>
					<cfif len(remark) gt 0>
						,remark=<cfqueryparam value="#remark#" CFSQLType="cf_sql_varchar">
					</cfif>
				where
					tag_id=<cfqueryparam value="#tag_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset rx=getTagReln(tag_id)>
			<cfreturn rx>
		</cftransaction>
	<cfcatch>
		<cfreturn "fail: #cfcatch.message# #cfcatch.detail# #cfcatch.sql#">
	</cfcatch>
	</cftry>
	</cfoutput>
</cffunction>
<!--------------------------------------->
<cffunction name="newRef" access="remote">
	<cfargument name="media_id" required="yes">
	<cfargument name="reftype" required="yes">
	<cfargument name="remark" required="yes">
	<cfargument name="refid" required="yes">
	<cfargument name="reftop" required="yes">
	<cfargument name="refleft" required="yes">
	<cfargument name="refh" required="yes">
	<cfargument name="refw" required="yes">
	<cfargument name="imgh" required="yes">
	<cfargument name="imgw" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cftry>
		<cftransaction>
			<cfquery name="pkey" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_tag_id') n
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into tag (
					tag_id,
					media_id,
					reftop,
					refleft,
					refh,
					refw,
					imgh,
					imgw
					<cfif reftype is "cataloged_item">
						,collection_object_id
					<cfelseif reftype is "collecting_event">
						,collecting_event_id
					<cfelseif reftype is "locality">
						,locality_id
					<cfelseif reftype is "agent">
						,agent_id
					</cfif>
					<cfif len(remark) gt 0>
						,remark
					</cfif>
				) values (
					<cfqueryparam value="#pkey.n#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#media_id#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#reftop#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#refleft#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#refh#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#refw#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#imgh#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#imgw#" cfsqltype="cf_sql_int">
					<cfif reftype is "cataloged_item" or reftype is "collecting_event" or reftype is "locality" or reftype is "agent">
						,<cfqueryparam value="#refid#" cfsqltype="cf_sql_int">
					</cfif>
					<cfif len(remark) gt 0>
						,<cfqueryparam value="#remark#" cfsqltype="cf_sql_varchar">
					</cfif>
				)
			</cfquery>
			<cfset rx=getTagReln(pkey.n)>
			<cfreturn rx>
		</cftransaction>
	<cfcatch>
		<cfreturn "fail: #cfcatch.message# #cfcatch.detail# #cfcatch.sql#">
	</cfcatch>
	</cftry>
	</cfoutput>
</cffunction>
<!--------------------------------------->

</cfcomponent>