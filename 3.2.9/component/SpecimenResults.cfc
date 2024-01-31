<cfcomponent>
<cffunction name="getAttributeSearchValues" access="remote" returnformat="json" queryFormat="column" output="false">
	<cfargument name="attribute" type="string" required="yes">
	<cfset rtn=StructNew()>
	<cfset rtn.control_type='none'>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#attribute#">
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#lcase(isCtControlled.value_code_table)#"> and
			column_name not in ( 'description','collection_cde' )
		</cfquery>
		<cfquery name="vct" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# as dcl from #lcase(isCtControlled.value_code_table)# group by #getCols.column_name# order by #getCols.column_name#
		</cfquery>
		<cfset rtn.control_type='value'>
		<cfset rtn.data=ValueArray(vct, "dcl")>
	<cfelseif len(isCtControlled.UNITS_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#lcase(isCtControlled.UNITS_CODE_TABLE)#"> and
			column_name not in ( 'description' )
		</cfquery>
		<cfquery name="uct" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# as dcl from #lcase(isCtControlled.UNITS_CODE_TABLE)# group by #getCols.column_name# order by #getCols.column_name#
		</cfquery>
		<cfset rtn.control_type='units'>
		<cfset rtn.data=ValueArray(uct, "dcl")>
	</cfif>
	<cfreturn rtn>
</cffunction>
<cffunction name="getSpecimenEventLinkedData" access="remote" returnformat="plain" queryFormat="column" output="false">
	<cfparam name="collection_object_id" type="numeric">
	<cfparam name="related_key_type" type="string" >
	<cfparam name="related_key_value" type="numeric" >
	<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_event_links.specimen_event_id
		from
			specimen_event_links,
			specimen_event
		where
			 specimen_event_links.specimen_event_id=specimen_event.specimen_event_id and
			 specimen_event.collection_object_id=#collection_object_id# and
			 <cfif related_key_type is "specimen_part">
				specimen_event_links.part_id=#related_key_value#
			<cfelse>
				<!--- not handled --->
				1=2
			</cfif>
	</cfquery>
	<cfreturn r>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="deLinkSpecEvent" access="remote"  queryFormat="column" output="false">
	<cfparam name="related_key_type" type="string" >
	<cfparam name="related_key_value" type="numeric" >
	 <!---- this has to be called remotely, but only allow logged-in Operators access
	 returnformat="plain"
	 --->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" result="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from	specimen_event_links where
			 <cfif related_key_type is "specimen_part">
				specimen_event_links.part_id=#related_key_value#
			<cfelse>
				<!--- not handled --->
				1=2
			</cfif>
	</cfquery>
	<cfreturn r>
</cffunction>
	<!--------------------------------------------------------------------------------------------------------->
	<cffunction name="downloadSpecimenSummary" access="remote" output="false">
		<cfparam name="sch_table_name" type="string" required="true">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from #sch_table_name# where 1=2
		</cfquery>
		<cfset thisci=1>
		<cfset numcols=listlen(cols.columnlist)>
		<cfquery name="dla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				<cfloop list="#cols.columnlist#" index="x">
					<cfif x is "linktospecimens">
						'#Application.serverRootURL#/SpecimenResults.cfm?collection_object_id=' || SUBSTRING(linktospecimens from $$data-cids="([^"]+)$$) AS #x#
					<cfelse>
						#x# as #x#
					</cfif>
					<cfif thisci lt numcols>,</cfif>
					<cfset thisci=thisci+1>
				</cfloop>
			 from #sch_table_name#
		</cfquery>
		<cfset csv = util.QueryToCSV2(Query=dla,Fields=dla.columnlist)>
		<cfset fn="ArctosSpecimenSummary" & NumberFormat(RandRange(0,999000),"000000") & ".csv">
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#fn#"
	    	output = "#csv#"
	    	addNewLine = "no">
	    <cfset r.status="success">
	    <cfset r.filename=fn>
    	<cfreturn r>
	</cffunction>
</cfcomponent>