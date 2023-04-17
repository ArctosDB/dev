<cfinclude template="/includes/_header.cfm">
<cfset title="container contents-->part attributes">
<cfif action is  "nothing">
	<cfoutput>
		<cfif not isdefined("container_id") or len(container_id) is 0>
			no<cfabort>
		</cfif>
		<h3>Part Attributes from Container Contents</h3>
		This will create a part attribute bulkloader file for container contents. Fill in the form below, get CSV, feed it to the part attribute bulkloader.
		<p>
			<a href="/EditContainer.cfm?container_id=#container_id#">back to edit container</a>
		</p>
		<cfquery name="ctspecpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctspecpart_attribute_type order by attribute_type
		</cfquery>

		<form name="f" method="post" action="containerPartAttributes.cfm">
			<input type="hidden" name="action" value="getdata">
			<input type="hidden" name="container_id" value="#container_id#">
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value</th>
					<th>Units</th>
					<th>Date</th>
					<th>DeterminedBy</th>
					<th>Remark</th>
					<th>Method</th>
				</tr>
				<tr id="r_new" >
					<td>
						<select id="attribute_type_new" name="attribute_type_new" onchange="setPartAttOptions('new',this.value)">
							<option value="">pick</option>
							<cfloop query="ctspecpart_attribute_type">
								<option value="#attribute_type#">#attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td id="v_new">
						<input type="hidden" name="attribute_value_new">
					</td>
					<td id="u_new">
						<input type="hidden" name="attribute_units_new">
					</td>
					<td id="d_new">
						<input type="datetime" name="determined_date_new" id="determined_date_new">
					</td>
					<td id="a_new">
						<input type="hidden" name="determined_id_new" id="determined_id_new">
						<input type="text" name="determined_agent_new" id="determined_agent_new"
							onchange="pickAgentModal('determined_id_new',this.id,this.value);">
					</td>
					<td id="r_new">
						<input type="text" name="attribute_remark_new" id="attribute_remark_new">
					</td>
					<td id="m_new">
						<input type="text" name="determination_method_new" id="determination_method_new">
					</td>
				</tr>
			</table>
			<input type="submit" class="savBtn" value="get CSV">
		</form>
	</cfoutput>
</cfif>
<cfif action is "getdata">
	<cfoutput>
		<cfparam name="attribute_type_new" default="">
		<cfparam name="attribute_value_new" default="">
		<cfparam name="attribute_units_new" default="">
		<cfparam name="determined_date_new" default="">
		<cfparam name="determined_agent_new" default="">
		<cfparam name="attribute_remark_new" default="">
		<cfparam name="determination_method_new" default="">


		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			with recursive subordinates as (
			    select
			        container.container_id,
			        container.container_type,
			        container.last_date,
			        container.institution_acronym,
			        0 lvl
			    from
			        container
			    where
			        container.container_id=<cfqueryparam CFSQLType="cf_sql_int" value="#container_id#">
			    union
			    select
			        e.container_id,
			        e.container_type,
			        e.last_date,
			        e.institution_acronym,
			        s.lvl + 1 lvl
			    from
			        container e
			        inner join subordinates s ON s.container_id = e.parent_container_id
			    -- this prevents infinite recursion
			    where lvl<20
			) select 
			   coll_obj_cont_hist.collection_object_id as part_id,
			   flat.guid as guid,
			   specimen_part.part_name,
			   '#attribute_type_new#' as attribute_type,
			   '#attribute_value_new#' as attribute_value,
			   '#attribute_units_new#' as attribute_units,
			   '#determined_date_new#' as determined_date,
			   '#determined_agent_new#' as determiner,
			   '#attribute_remark_new#' as remark,
			   '#determination_method_new#' as attribute_method
			  from 
			    subordinates 
			    inner join coll_obj_cont_hist on subordinates.container_id=coll_obj_cont_hist.container_id
			    inner join specimen_part on coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id
			    inner join flat on specimen_part.derived_from_cat_item=flat.collection_object_id
			where 
			    container_type='collection object'
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=raw.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/container_part_attrs.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=container_part_attrs.csv" addtoken="false">
	</cfoutput>
</cfif>