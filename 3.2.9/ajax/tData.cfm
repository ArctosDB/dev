<cfif action is "suggestGeogShape">
	<cfif not isdefined("q") or len(q) is 0>
		<cfabort>
	</cfif>
	<cfquery name="ctgeog_shape"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select higher_geog  from geog_auth_rec where 
		higher_geog ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#"> and
		spatial_footprint is not null order by higher_geog
	</cfquery>
	<cfoutput query="ctgeog_shape">#higher_geog##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestPrtAttVal">
	<cfif not isdefined("att_type") or len(att_type) is 0>
		<cfabort>
	</cfif>
	<cfquery name="getc" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select value_code_table from ctspec_part_att_att where attribute_type=<cfqueryparam value = "#att_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(att_type))#">
	</cfquery>
	<cfif len(getc.value_code_table) is 0>
		<cfabort>
	</cfif>
	<cfquery name="cname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name='#getc.value_code_table#' and column_name not in ('description','collection_cde')
	</cfquery>
	<cfif cname.recordcount is not 1>
		<cfabort>
	</cfif>

	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			#cname.column_name# d
		FROM
			#getc.value_code_table#
		WHERE
			upper(#cname.column_name#) ilike <cfqueryparam value = "%#q#%" CFSQLType="CF_SQL_VARCHAR">
		group by #cname.column_name#
		order by #cname.column_name#
	</cfquery>
	<cfoutput query="ins">#d##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestIdAttVal">
	<cfif not isdefined("att_type") or len(att_type) is 0>
		<cfabort>
	</cfif>
	<cfquery name="getc" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select lower(value_code_table) as value_code_table from ctidentification_attribute_code_tables where attribute_type=<cfqueryparam value = "#att_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(att_type))#">
	</cfquery>

	<cfif len(getc.value_code_table) is 0>
		<cfabort>
	</cfif>
	<cfquery name="cname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name='#getc.value_code_table#' and column_name not in ('description','collection_cde')
	</cfquery>
	<cfif cname.recordcount is not 1>
		<cfabort>
	</cfif>
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			#cname.column_name# d
		FROM
			#getc.value_code_table#
		WHERE
			#cname.column_name# ilike <cfqueryparam value = "%#q#%" CFSQLType="CF_SQL_VARCHAR">
		group by #cname.column_name#
		order by #cname.column_name#
	</cfquery>
	<cfoutput query="ins">#d##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestRecAttVal">
	<cfif not isdefined("att_type") or len(att_type) is 0>
		<cfabort>
	</cfif>
	<cfquery name="getc" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select lower(value_code_table) as value_code_table from ctattribute_type where attribute_type=<cfqueryparam value = "#att_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(att_type))#">
	</cfquery>
	<cfif len(getc.value_code_table) is 0>
		<cfabort>
	</cfif>
	<cfquery name="cname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name=<cfqueryparam value="#getc.value_code_table#" cfsqltype="cf_sql_varchar">
		and column_name not in ('description','collection_cde','collections','recommend_for_collection_type','search_terms','issue_url','documentation_url')
	</cfquery>
	<cfif cname.recordcount is not 1>
		<cfabort>
	</cfif>
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			#cname.column_name# d
		FROM
			#getc.value_code_table#
		WHERE
			#cname.column_name# ilike <cfqueryparam value = "%#q#%" CFSQLType="CF_SQL_VARCHAR">
		group by #cname.column_name#
		order by #cname.column_name#
	</cfquery>
	<cfoutput query="ins">#d##chr(10)#
	</cfoutput>
</cfif>

<cfif action is "suggestEvtAttVal">
	<cfif not isdefined("att_type") or len(att_type) is 0>
		<cfabort>
	</cfif>
	<cfquery name="getc" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select value_code_table from ctcoll_event_att_att where event_attribute_type=<cfqueryparam value = "#att_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(att_type))#">
	</cfquery>
	<cfif len(getc.value_code_table) is 0>
		<cfabort>
	</cfif>
	<cfquery name="cname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name='#getc.value_code_table#' and column_name not in ('description')
	</cfquery>
	<cfif cname.recordcount is not 1>
		<cfabort>
	</cfif>

	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			#cname.column_name# d
		FROM
			#getc.value_code_table#
		WHERE
			upper(#cname.column_name#) ilike <cfqueryparam value = "%#q#%" CFSQLType="CF_SQL_VARCHAR">
		group by #cname.column_name#
		order by #cname.column_name#
	</cfquery>
	<cfoutput query="ins">#d##chr(10)#
	</cfoutput>
</cfif>

<cfif action is "suggestLocAttVal">
	<cfif not isdefined("att_type") or len(att_type) is 0>
		<cfabort>
	</cfif>
	<cfquery name="gtc" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select value_code_table from ctlocality_attribute_type where attribute_type=<cfqueryparam value = "#att_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(att_type))#">
	</cfquery>
	<cfif len(gtc.value_code_table) is 0>
		<cfabort>
	</cfif>
	<!---- get this with
		select column_name from information_schema.columns where table_name in (select value_code_table from ctlocality_attribute_type union select unit_code_table from ctlocality_attribute_type ) group by column_name order by column_name;
	---->
	<cfquery name="cname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name=<cfqueryparam value="#gtc.value_code_table#" cfsqltype="cf_sql_varchar"> and column_name not in ('description','documentation_url','issue_url','search_terms','water_body_type')
	</cfquery>
	<cfif cname.recordcount is not 1>
		<cfabort>
	</cfif>

	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			#cname.column_name# d
		FROM
			#gtc.value_code_table#
		WHERE
			#cname.column_name# ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		group by #cname.column_name#
		order by #cname.column_name#
	</cfquery>
	<cfoutput query="ins">#d##chr(10)#
	</cfoutput>
</cfif>
<cfif #action# is "suggestGeoCtMeta">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct meta_value
		from
			code_table_metadata
		where
			meta_value ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by meta_value
	</cfquery>
	<cfoutput query="ins">#meta_value##chr(10)#
	</cfoutput>
</cfif>
<cfif #action# is "suggestFeature">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(Feature)
		from
			ctfeature
		where
			feature ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by Feature
	</cfquery>
	<cfoutput query="ins">#Feature##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestStateProv">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(state_prov)
		from
			geog_auth_rec
		where
			state_prov is not null and
			state_prov ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by state_prov
	</cfquery>
	<cfoutput query="ins">#state_prov##chr(10)#
	</cfoutput>
</cfif>

<cfif action is "suggestQuad">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			quad
		from
			ctquad
		where
			quad ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by quad
	</cfquery>
	<cfoutput query="ins">#quad##chr(10)#
	</cfoutput>
</cfif>

<cfif action is "suggestCounty">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(county)
		from
			geog_auth_rec
		where
			county is not null and
			county ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by county
	</cfquery>
	<cfoutput query="ins">#county##chr(10)#
	</cfoutput>
</cfif>

<cfif action is "suggestIsland">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(island)
		from
			geog_auth_rec
		where
			island is not null and
			island ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by island
	</cfquery>
	<cfoutput query="ins">#island##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestTaxSrc">
	<!------------ https://github.com/ArctosDB/arctos/issues/6231 ----------->
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			source 
		from
			cttaxonomy_source
		where
			source ilike <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		 order by source
	</cfquery>
	<cfoutput query="ins">#source##chr(10)#
	</cfoutput>
</cfif>
<cfif action is "suggestAgent">
	<!------------ https://github.com/ArctosDB/arctos/issues/5978 ----------->
	<cfquery name="sugg_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
		preferred_agent_name 
		from
		agent
		inner join agent_attribute on agent.agent_id=agent_attribute.agent_id and deprecation_type is null
		inner join ctagent_attribute_type on agent_attribute.attribute_type=ctagent_attribute_type.attribute_type and purpose='name'
		where
		agent_attribute.attribute_value ilike  <cfqueryparam value="%#q#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q))#">
		group by preferred_agent_name
		order by preferred_agent_name
	</cfquery>
	<cfoutput query="sugg_agent">#preferred_agent_name##chr(10)#
	</cfoutput>
</cfif>