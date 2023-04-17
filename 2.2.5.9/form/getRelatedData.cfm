<cfinclude template="/includes/_includeHeader.cfm">
	<script>
		function saveCheck (id, val) {
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "saveDeSettings",
					id : id,
					val : val,
					returnformat : "json",
					queryformat : 'column'
				},
				function (result){}
			);
		}
		function useThis(id) {
			var j=$("#json_" + id).val();
			const obj = JSON.parse(j);
			var ev=$("#relpick_event").is(':checked');
			var lo=$("#relpick_locality").is(':checked');
			var co=$("#relpick_collector").is(':checked');
			var atr=$("#relpick_attributes").is(':checked');
			var idr=$("#relpick_identification").is(':checked');
			if (idr==true){
				var cls=obj.IDENTIFICATION;
				parent.jQuery("#taxon_name").val(cls.SCIENTIFIC_NAME);
				parent.jQuery("#id_made_by_agent").val(cls.IDENTIFIER);
				parent.jQuery("#nature_of_id").val(cls.NATURE_OF_ID);
				parent.jQuery("#identification_confidence").val(cls.IDENTIFICATION_CONFIDENCE);
				parent.jQuery("#made_date").val(cls.MADE_DATE);
				parent.jQuery("#identification_remarks").val(cls.IDENTIFICATION_REMARKS);
			}
			if (ev==true){
				parent.jQuery("#collecting_event_id").val(obj.COLLECTING_EVENT_ID);
			}
			if (lo==true){
				parent.jQuery("#locality_id").val(obj.LOCALITY_ID);
			}
			if (co==true){
				var cls=obj.COLLECTORS;
				// first purge any existing
				for (var i = 1; i <=5 ; i++) {
    				parent.jQuery("#collector_agent_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#collector_role_" + i).val('').removeClass('reqdClr');
    			}
				for (var i = 0; i < cls.length; i++) {
				    var rn=i+1;
    				parent.jQuery("#collector_agent_" + rn).val(cls[i].PREFERRED_AGENT_NAME);
    				parent.jQuery("#collector_role_" + rn).val(cls[i].COLLECTOR_ROLE);
				}
			}
			if (atr==true){
				var cls=obj.ATTRIBTUES;
				// first purge any existing
				for (var i = 1; i <=10 ; i++) {
    				parent.jQuery("#attribute_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_value_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_units_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_date_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_determiner_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_det_meth_" + i).val('').removeClass('reqdClr');
    				parent.jQuery("#attribute_remarks_" + i).val('').removeClass('reqdClr');
    			}
				for (var i = 0; i < cls.length; i++) {
				    var rn=i+1;
    				parent.jQuery("#attribute_" + rn).val(cls[i].ATTRIBUTE_TYPE);
    				parent.getAttributeStuff(cls[i].ATTRIBUTE_TYPE,'attribute_' + rn);
    				parent.jQuery("#attribute_value_" + rn).val(cls[i].ATTRIBUTE_VALUE);
    				parent.jQuery("#attribute_units_" + rn).val(cls[i].ATTRIBUTE_UNITS);
    				parent.jQuery("#attribute_date_" + rn).val(cls[i].DETERMINED_DATE);
    				parent.jQuery("#attribute_determiner_" + rn).val(cls[i].ATTRIBUTE_DETERMINER);
    				parent.jQuery("#attribute_det_meth_" + rn).val(cls[i].DETERMINATION_METHOD);
    				parent.jQuery("#attribute_remarks_" + rn).val(cls[i].ATTRIBUTE_REMARK);
				}
			}
			parent.closegetRelatedData();
		}
	</script>
	<cfoutput>
		<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order,other_id_type
	    </cfquery>
	    <label for="s">
	    	Find Record
	    </label>
		<form name="s" method="get" action="getRelatedData.cfm">
			<label for="idtype">
				ID Type
			</label>
			<select name="idtype" id="idtype">
				<option value=""></option>
				<cfloop query="ctOtherIdType">
					<option <cfif idtype is ctOtherIdType.other_id_type> selected="selected" </cfif>
						value="#other_id_type#">#other_id_type#</option>
				</cfloop>
			</select>
			<label for="idtype">
				ID
			</label>
			<input type="text" name="idval" value="#idval#" id="idval" class="reqdClr">


			<label for="issuedby">
				issuedby
			</label>
			<cfparam name="issuedby" default="">
			<input type="text" name="issuedby" value="#issuedby#" id="issuedby">
			<input type="hidden" name="clickedfrom" value="#clickedfrom#" id="clickedfrom">
			<br>
			<input type="submit" class="lnkBtn" value="go">
		</form>
	<cfquery name="desettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			relpick_event,
			relpick_locality,
			relpick_collector,
			relpick_attributes,
			relpick_identification
 		from cf_dataentry_settings where username=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#session.username#">

	</cfquery>
	<cfquery name="d" datasource="uam_god">
		select
			flat.collection_object_id,
			flat.collecting_event_id,
			flat.locality_id,
			flat.guid,
			flat.higher_geog,
			flat.spec_locality,
			flat.verbatim_locality,
			flat.verbatim_date,
			collector.collector_role,
			collector.coll_order,
			clr_agent.preferred_agent_name,
			getPreferredAgentName(determined_by_agent_id) as attribute_determiner,
			attribute_type,
			attribute_value,
			attribute_units,
			attribute_remark,
			determination_method,
			determined_date,
			identification.scientific_name,
			identification.nature_of_id,
			identification.identification_remarks,
			identification.made_date,
			identification.identification_confidence,
			getPreferredAgentName(identification_agent.agent_id) identifier,
			identification_agent.identifier_order
		from
			flat
			left outer join collector on flat.collection_object_id=collector.collection_object_id
			left outer join agent clr_agent on collector.agent_id=clr_agent.agent_id
			left outer join attributes on flat.collection_object_id=attributes.collection_object_id
			inner join identification on flat.collection_object_id=identification.collection_object_id and accepted_id_fg=1
			left outer join identification_agent on identification.identification_id=identification_agent.identification_id
		where flat.collection_object_id in (
			select collection_object_id from coll_obj_other_id_num
				where 
				display_value ilike <cfqueryparam CFSQLType="CF_SQL_varchar" value="#trim(idval)#">
				<cfif len(idtype) gt 0>
					and other_id_type=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#idtype#"> 
				</cfif>
				<cfif len(issuedby) gt 0>
					and issued_by_agent_id in (select agent_id from agent_name where agent_name ilike <cfqueryparam CFSQLType="CF_SQL_varchar" value="%#issuedby#%">)
				</cfif>
			union
				select collection_object_id from flat where upper(guid)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(idtype)#:#ucase(trim(idval))#">
		) 
	</cfquery>
	<cfquery name="uniq" dbtype="query">
		select
			collection_object_id,
			collecting_event_id,
			locality_id,
			guid,
			higher_geog,
			spec_locality,
			verbatim_locality,
			verbatim_date
		from d group by 
			collection_object_id,
			collecting_event_id,
			locality_id,
			guid,
			higher_geog,
			spec_locality,
			verbatim_locality,
			verbatim_date
		</cfquery>
		<label for="t">
			Save to Data Entry....
		</label>
		<table border>
			<tr>
				<th>Data</th>
				<th>select</th>
				<th>caution</th>
			</tr>
			<tr>
				<td>Event (collecting_event_id)</td>
				<td>
					<input id="relpick_event"
						<cfif desettings.relpick_event is 1>checked="checked"</cfif>
						type="checkbox" value="#desettings.relpick_event#"
						onchange="saveCheck(this.id,this.checked)">
				</td>
				<td>
					Protected only while data are in bulkloader; otherwise may be merged/deleted. Only the ID will be pushed; text-data may conflict but will be ignored when the record loads.
				</td>
			</tr>
			<tr>
				<td>Locality (locality_id)</td>
				<td>
					<input id="relpick_locality"
						<cfif desettings.relpick_locality is 1>checked="checked"</cfif>
						type="checkbox" value="#desettings.relpick_locality#"
						onchange="saveCheck(this.id,this.checked)">
				</td>
				<td>
					Protected only while data are in bulkloader; otherwise may be merged/deleted. Only the ID will be pushed; text-data may conflict but will be ignored when the record loads.
				</td>
			</tr>
			<tr>
				<td>Collectors</td>
				<td>
					<input id="relpick_collector"
						<cfif desettings.relpick_collector is 1>checked="checked"</cfif>
						type="checkbox" value="#desettings.relpick_collector#"
						onchange="saveCheck(this.id,this.checked)">
				</td>
				<td>Only the first 5 collectors will be used; additional source data will be ignored.
			</tr>
			<tr>
				<td>Attributes</td>
				<td>
					<input id="relpick_attributes"
						<cfif desettings.relpick_attributes is 1>checked="checked"</cfif>
						type="checkbox" value="#desettings.relpick_attributes#"
						onchange="saveCheck(this.id,this.checked)">
				</td>
				<td>Only the first 10 attributes will be used; additional source data will be ignored.
			</tr>
			<tr>
				<td>Identification</td>
				<td>
					<input id="relpick_identification"
						<cfif desettings.relpick_identification is 1>checked="checked"</cfif>
						type="checkbox" value="#desettings.relpick_identification#"
						onchange="saveCheck(this.id,this.checked)">
				</td>
				<td>Accepted identification; only the first identifying agent will be used.</td>
			</tr>
		</table>
		<label for="t2">
			Check boxes for what you want to save above, then pick a record from the table below.
		</label>
	<table border>
		<tr>
			<th></th>
			<th>GUID</th>
			<th>ID</th>
			<th>Geog</th>
			<th>SpecLocality</th>
			<th>VerbatimLocality</th>
			<th>VerbatimDate</th>
			<th>Collectors</th>
			<th>Attributes</th>
		</tr>
		<cfset i=1>


		<cfloop query="uniq">
			
			<cfset mystr=[=]>
			<cfset mystr.collection_object_id=uniq.collection_object_id>
			<cfset mystr.collecting_event_id=uniq.collecting_event_id>
			<cfset mystr.locality_id=uniq.locality_id>
			<cfset mystr.guid=uniq.guid>
			<cfset mystr.higher_geog=uniq.higher_geog>
			<cfset mystr.spec_locality=uniq.spec_locality>
			<cfset mystr.verbatim_locality=uniq.verbatim_locality>
			<cfset mystr.verbatim_date=uniq.verbatim_date>
			

			<tr>
				<td><input type="button" class="savBtn" onclick="useThis(#collection_object_id#)" value="use"></td>
				<td>#guid#</td>
				<cfquery name="ids" dbtype="query">
					select 	
						scientific_name,
						nature_of_id,
						identification_remarks,
						made_date,
						identification_confidence
					from d where 
						collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#"> and
						scientific_name is not null
						group by 
						scientific_name,
						nature_of_id,
						identification_remarks,
						made_date,
						identification_confidence
				</cfquery>

				<td>
					<cfset myids=[=]>
					<cfset myidag=[=]>
					<cfloop query="ids">
							<cfset 	myids.scientific_name=scientific_name>
							<cfset 	myids.nature_of_id=nature_of_id>
							<cfset 	myids.identification_confidence=identification_confidence>
							<cfset 	myids.made_date=made_date>
							<cfset 	myids.identification_remarks=identification_remarks>
						

						<div>
							#scientific_name# #nature_of_id# #identification_confidence# #made_date# #identification_remarks#
							<cfquery name="idrs" dbtype="query">
								select
									identifier,
									identifier_order					
								from d where collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#">
								and identifier is not null
								group by
									identifier,
									identifier_order	
								order by identifier_order
							</cfquery>
							(<cfset lp=1>
								<cfloop query="idrs">
									#identifier#[#identifier_order#]
									<cfif lp is 1>
										<cfset 	myids.identifier=identifier>
									</cfif>
									<cfset lp=lp+1>
								</cfloop>
							)
						


							<cfset mystr.identification=myids>

						</div>
					</cfloop>
				</td>




				<td>#higher_geog#</td>
				<td>#spec_locality#</td>
				<td>#verbatim_locality#</td>
				<td>#verbatim_date#</td>
				<cfquery name="colls" dbtype="query">
					select 	
						collector_role,
						coll_order,
						preferred_agent_name
					from d where collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#">
					and collector_role is not null
					group by
					collector_role,
						coll_order,
						preferred_agent_name
					order by coll_order,collector_role
				</cfquery>


				<td>
					<cfset c=arraynew(1)>

					<cfloop query="colls">
						<cfset ca=[=]>
						<cfset ca.preferred_agent_name=preferred_agent_name>
						<cfset ca.collector_role=collector_role>
						<cfset ArrayAppend( c,ca)>
						<br>#preferred_agent_name#: #collector_role# (#coll_order#)

					</cfloop>
					<cfset mystr.collectors=c>

				</td>
				<cfquery name="attrs" dbtype="query">
					select 	
						attribute_determiner,
						attribute_type,
						attribute_value,
						attribute_units,
						attribute_remark,
						determination_method,
						determined_date
					from d where collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#">
				</cfquery>


				<td>
					<cfset ja=arraynew(1)>
					<cfloop query="attrs">
						<cfset ta=[=]>
						<cfset ta.attribute_type=attribute_type>
						<cfset ta.attribute_value=attribute_value>
						<cfset ta.attribute_units=attribute_units>
						<cfset ta.determined_date=determined_date>
						<cfset ta.determination_method=determination_method>
						<cfset ta.attribute_remark=attribute_remark>
						<cfset ta.attribute_determiner=attribute_determiner>

						<cfset ArrayAppend( ja,ta)>


						<div>
							#attribute_type# #attribute_value# #attribute_units# #determined_date# #determination_method# #attribute_remark#
						</div>
					</cfloop>


							<cfset mystr.attribtues=ja>
				</td>

			</tr>
			<cfset i=i+1>
								<cfset json=serializejson(mystr)>
<input type="hidden" id="json_#collection_object_id#" value="#EncodeForHTML(json)#">



		</cfloop>
	</table>





					<!-------










					<cfdump var="#mystr#">

					<cfset json=serializejson(mystr)>


					<cfdump var="#json#">
			<cfset mystr.xxx=uniq.xxxx>
			<cfset mystr.xxx=uniq.xxxx>
			<cfset mystr.xxx=uniq.xxxx>

		<cfset mystr=[=]>
		<cfset mystr.collecting_event_id=root.collecting_event_id>

		<cfset mystr.idents=ids>

			collection_object_id,
			collecting_event_id,
			locality_id,
			guid,
			higher_geog,
			spec_locality,
			verbatim_locality,
			verbatim_date


				<cfset job=serializejson(root,"struct")>

					<cfdump var="#job#">


					<cfset tmpstr=deSerializejson(job)>
					<cfdump var="#tmpstr#">

				<cfset jids=serializejson(ids,"struct")>
					<cfdump var="#jids#">

					<cfset tmpstrjids=deSerializejson(jids)>
					<cfdump var="#tmpstrjids#">

					<cfset tmpstr.identifications=tmpstrjids>
					<cfdump var="#tmpstr#">


ids

					<cfset tmpstr=deSerialize(job)>
					<cfdump var="#tmpstr#">

					<cfset tmptxt=serializejson(ids,"struct")>

					<cfdump var="#tmptxt#">

					<cfset tmpstr=eSerializeJSON(tmptxt)>


					<cfdump var="#tmpstr#">

				<cfset thisJob.fasaids=deSerializeJSON(job)>
-------->
					<!----

				<cfset thisJob=deSerializeJSON(job)>

				<cfset thisJob.ids=deSerializeJSON(job)>
			--->

	</cfoutput>