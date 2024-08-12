<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "nothing">
<cfset title = "Edit Collectors">
<cfoutput>
	<cfquery name="getColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			flat.guid,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			flat.scientific_name,
			flat.higher_geog,
			flat.spec_locality,
			flat.verbatim_date,
			agent_name,
			collector_role,
			COLL_ORDER
		FROM
			#table_name#
			inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			left outer join collector on flat.collection_object_id = collector.collection_object_id
			left outer join preferred_agent_name on collector.agent_id=preferred_agent_name.agent_id
	</cfquery>
	<cfquery name="ci" dbtype="query">
		select
			guid,
			CustomID,
			scientific_name,
			higher_geog,
			spec_locality,
			verbatim_date
		from
			getColls
		group by
			guid,
			CustomID,
			scientific_name,
			higher_geog,
			spec_locality,
			verbatim_date
		order by
			guid
	</cfquery>
	<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collector_role from ctcollector_role order by collector_role
	</cfquery>
	<h2>
		Add/Remove collectors for all catalog records listed below
	</h2>
	Pick an agent, a role, and an order to insert or delete an agent for all records listed below.
	<br>Order is ignored for deletion.
	<br>
  	<form name="tweakColls" method="post" action="multiAgent.cfm">
		<input type="hidden" name="table_name" value="#table_name#">
		<input type="hidden" name="action" value="">
		<label for="name">Name</label>
		<input type="text" name="name" id="name" class="reqdClr"
			onchange="pickAgentModal('agent_id',this.id,this.value);"
		 	onKeyPress="return noenter(event);">
		<input type="hidden" name="agent_id" id="agent_id">
		<label for="collector_role">Role</label>
        <select name="collector_role" size="1"  class="reqdClr">
			<cfloop query="ctcollector_role">
				<option value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#</option>
			</cfloop>
		</select>
		<label for="coll_order">Order</label>
		<select name="coll_order" size="1" class="reqdClr">
			<option value="first">First</option>
			<option value="last">Last</option>
			<!----
			<option value="beforecollectors">Before Collector(s)</option>
			<option value="aftercollectors">After Collector(s)</option>
			<option value="beforepreparators">Before Preparator(s)</option>
			<option value="afterpreparators">After Preparator(s)</option>
			<option value="beforemakers">Before Maker(s)</option>
			<option value="aftermakers">After Maker(s)</option>
			---->
		</select>
		<br>
		<input type="button"
			value="Insert Agent"
			class="insBtn"
   			onclick="tweakColls.action.value='insertColl';submit();">
		<input type="button"
			value="Remove Agent"
			class="delBtn"
   			onclick="tweakColls.action.value='deleteColl';submit();">
	</form>



<br><b>Catalog Records:</b>

<table border="1">
<tr>
	<th>GUID</th>
	<th>#session.CustomOtherIdentifier#</th>
	<th>Accepted ID</th>
	<th>Collectors</th>
	<th>Preparators</th>
	<th>Creators</th>
	<th>Geog</th>
	<th>specloc</th>
	<th>verbatim date</th>
</tr>
<cfloop query="ci">
	<cfquery name="c" dbtype="query">
		select agent_name from getColls where collector_role='collector' and guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar"> order by COLL_ORDER
	</cfquery>
	<cfquery name="p" dbtype="query">
		select agent_name from getColls where collector_role='preparator' and guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar"> order by COLL_ORDER
	</cfquery>
	<cfquery name="m" dbtype="query">
		select agent_name from getColls where collector_role='creator' and guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar"> order by COLL_ORDER
	</cfquery>
    <tr>
	  <td>
	  	<a href="/guid/#guid#">#guid#</a>
	  </td>
	<td>
		#CustomID#&nbsp;
	</td>
	<td><i>#Scientific_Name#</i></td>
	<td>
		<cfloop query="c">
			<div>
				#agent_name#
			</div>
		</cfloop>
	</td>
	<td>
		<cfloop query="p">
			<div>
				#agent_name#
			</div>
		</cfloop>
	</td>
	<td>
		<cfloop query="m">
			<div>
				#agent_name#
			</div>
		</cfloop>
	</td>
	<td>#higher_geog#&nbsp;</td>
	<td>#spec_locality#&nbsp;</td>
	<td>#verbatim_date#&nbsp;</td>
</tr>
</cfloop>
</table>
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "insertColl">
	<cfoutput>
	<cfquery name="cids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select collection_object_id from #table_name#
	</cfquery>
		<cftransaction>
			<cfif coll_order is "first">
				<cfset coll_order_to_insert=-999999>
			<cfelseif coll_order is "last">
				<cfset coll_order_to_insert=999000>
			<cfelse>
				no order die<cfabort>
			</cfif>

			<cfloop query="cids">
				<!---- move existing out of the way ---->
				<cfquery name="bigJump" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						collector
					set
						coll_order=coll_order+9999
					where
						collection_object_id=<cfqueryparam value="#cids.collection_object_id#" CFSQLType="cf_sql_int">
				</cfquery>

				<!--- insert the new --->
				<cfquery name="insOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into collector (
						collection_object_id,
						agent_id,
						collector_role,
						coll_order
					) values (
						<cfqueryparam value="#cids.collection_object_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#collector_role#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#coll_order_to_insert#" CFSQLType="cf_sql_int">
					)
				</cfquery>
				<!---- now reorder with expected series numbers ---->
				<cfset nco=1>
				<cfquery name="thisColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						collector_id,
						coll_order
					from
						collector
					where
						collection_object_id=<cfqueryparam value="#cids.collection_object_id#" CFSQLType="cf_sql_int">
					order by
						coll_order,collector_id
				</cfquery>
				<cfloop query="thisColls">
					<cfquery name="upOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update
							collector
						set
							coll_order=<cfqueryparam value="#nco#" CFSQLType="cf_sql_int">
						where
							collector_id=<cfqueryparam value="#thisColls.collector_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfset nco=nco+1>
				</cfloop>
			</cfloop>
		</cftransaction>
		<cflocation url="multiAgent.cfm?table_name=#table_name#" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "deleteColl">
	<cfoutput>
		<cfquery name="cids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select collection_object_id from #table_name#
		</cfquery>
		<cftransaction>
			<cfloop query="cids">
				<!--- remove whatever's to be removed ---->
				<cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from
						collector
					where
						collection_object_id=<cfqueryparam value="#cids.collection_object_id#" CFSQLType="cf_sql_int"> and
						agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int"> and
						collector_role=<cfqueryparam value="#collector_role#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<!--- now reorder ---->
				<cfset nco=1>
				<cfquery name="thisColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						collector_id,
						coll_order
					from
						collector
					where
						collection_object_id=<cfqueryparam value="#cids.collection_object_id#" CFSQLType="cf_sql_int">
					order by
						coll_order,collector_id
				</cfquery>
				<cfloop query="thisColls">
					<cfquery name="upOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update
							collector
						set
							coll_order=<cfqueryparam value="#nco#" CFSQLType="cf_sql_int">
						where
							collector_id=<cfqueryparam value="#thisColls.collector_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfset nco=nco+1>
				</cfloop>
			</cfloop>
		</cftransaction>
		<cflocation url="multiAgent.cfm?table_name=#table_name#" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">