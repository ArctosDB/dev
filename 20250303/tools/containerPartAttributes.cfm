<cfinclude template="/includes/_header.cfm">
<cfset title="container contents-->part attributes">
<cfif action is  "nothing">
	<script>
		function setPartAttOptions(patype) {
	       $.getJSON("/component/DataEntry.cfc",
		        {
		            method : "getPartAttCodeTbl",
		            returnformat : "json",
		            attribute      : patype,
		            element: 'x',
		            guid_prefix: $("#guid_prefix").val()
		        },
		        function (r) {
		            console.log(r);

		            var id='new';
		            if (r.status=='success'){
		                valElem='attribute_value_' + id;
		                unitElem='attribute_units_' + id;
		                if (r.control=='values'){
		                    d='<select name="' + valElem + '" id="' + valElem + '">';
		                    $.each( r.data, function( k, v ) {
		                        d += '<option value="' + v + '">' + v + '</option>';
		                    });
		                    d+="</select>";
		                    $('#v_' + id).html(d);
		                    d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
		                    $('#u_' + id).html(d);
		                } else if (r.control=='units'){
		                    d='<input type="text" name="' + valElem + '" id="' + valElem + '">';
		                    $('#v_' + id).html(d);
		                    d='<select name="' + unitElem + '" id="' + unitElem + '">';
		                    $.each( r.data, function( k, v ) {
		                        d += '<option value="' + v + '">' + v + '</option>';
		                    });
		                    d+="</select>";
		                    $('#u_' + id).html(d);
		                } else if (r.control=='none'){
		                    dv='<textarea name="' + valElem + '" id="' + valElem + '" class="smalltextarea"></textarea>';
		                    //<input type="text" name="' + valElem + '" id="' + valElem + '">';
		                    $('#v_' + id).html(dv);
		                    d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
		                    $('#u_' + id).html(d);
		                    //console.log('added blank units');
		                } else {
		                    alert('woopsies, file an issue');
		                }
		            } else {
		                alert(r.status);
		            }
		          
		        }
		    );
		}
	</script>
	<cfoutput>
		<cfif not isdefined("container_id") or len(container_id) is 0>
			no<cfabort>
		</cfif>
		<h3>Part Attributes from Container Contents</h3>
		This will create a part attribute bulkloader file for container contents. Fill in the form below, get CSV, feed it to the part attribute bulkloader.
		<p>IMPORTANT: Part attributes must be collection-selected or the load will fail.
		<p>
			<a href="/EditContainer.cfm?container_id=#container_id#">back to edit container</a>
		</p>
		<cfquery name="ctpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctpart_attribute_type order by attribute_type
		</cfquery>

		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select guid_prefix from collection order by guid_prefix
		</cfquery>




		<form name="f" method="post" action="containerPartAttributes.cfm">
			<input type="hidden" name="action" value="getdata">
			<input type="hidden" name="container_id" value="#container_id#">
			<table border>
				<tr>
					<th>Collection</th>
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
						<select id="guid_prefix" name="guid_prefix">
							<option value="">pick</option>
							<cfloop query="ctcollection">
								<option value="#guid_prefix#">#guid_prefix#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<select id="attribute_type_new" name="attribute_type_new" onchange="setPartAttOptions(this.value)">
							<option value="">pick</option>
							<cfloop query="ctpart_attribute_type">
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
				'https://arctos.database.museum/guid/' || flat.guid || '/PID' || coll_obj_cont_hist.collection_object_id::text as partID,
			   	flat.guid as guid,
			   specimen_part.part_name,
			   <cfqueryparam value="#attribute_type_new#" cfsqltype="cf_sql_varchar"> as attribute_type,
			   <cfqueryparam value="#attribute_value_new#" cfsqltype="cf_sql_varchar"> as attribute_value,
			   <cfqueryparam value="#attribute_units_new#" cfsqltype="cf_sql_varchar"> as attribute_units,
			   <cfqueryparam value="#determined_date_new#" cfsqltype="cf_sql_varchar"> as determined_date,
			   <cfqueryparam value="#determined_agent_new#" cfsqltype="cf_sql_varchar"> as determiner,
			   <cfqueryparam value="#attribute_remark_new#" cfsqltype="cf_sql_varchar"> as remark,
			   <cfqueryparam value="#determination_method_new#" cfsqltype="cf_sql_varchar"> as attribute_method
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