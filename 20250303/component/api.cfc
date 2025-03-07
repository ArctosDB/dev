<!---
	api calls go here
	everything here should work from anywhere
	with the right credentials
	this is not an ideal solution, but built-in rest-thing is kludgy etc
	so here we are
--->



<cfcomponent>



<cffunction name="getPlaceColumns" output="true" access="public">
	<cfargument name="srch_type" default="">
	<cfargument name="col_list" default="">
	<!---------------->
	<cfquery name="cf_temp_loc_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select sql_alias,sql_element,category from cf_temp_loc_srch_cols where results_term=1 
	</cfquery>
	<cfif srch_type is "geog">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category='geography' 
		</cfquery>
		<cfset flds = "geog_auth_rec.geog_auth_rec_id">
	<cfelseif srch_type is "locality">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality') 
		</cfquery>
		<cfset flds = "locality.locality_id">
	<cfelseif srch_type is "collecting_event">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality','collecting_event') 
		</cfquery>
		<cfset flds = "collecting_event.collecting_event_id">
	<cfelse>
		nope<cfabort>
	</cfif>
	<cfset default_cols_list=valuelist(valid_cols.sql_alias)>
	<cfif len(col_list) is 0>
		<cfset col_list=default_cols_list>
	</cfif>
	<cfset colck=true>
	<cfloop list="#col_list#" index="ix">
		<cfif not listfind(default_cols_list,ix)>
			<cfset colck=false>
		</cfif>
	</cfloop>
	<cfif colck is false>
		<cfset col_list=default_cols_list>
	</cfif>
	<cfquery name="data_for_cols" dbtype="query">
		select sql_alias,sql_element from cf_temp_loc_srch_cols where sql_alias in (<cfqueryparam value="#col_list#" list="true"> )
	</cfquery>
	<cfloop query="data_for_cols">
		<cfset flds=listappend(flds,"#sql_element# AS #sql_alias#")>
	</cfloop>
	<cfreturn flds>
</cffunction>



<!----------------------------------------------------------------------------------------->
<cffunction name="getPlace" access="remote" returnformat="json" output="false">
	<!----
		take in whatever, return collecting events

		this is the template for getLocality and getGeography; they are this, with deletions, so make sure changes get propagated through the stack
	---->
	<!------------------- BEGIN standard-issue welcome mat -------->
	<cfparam name="api_key" type="string" default="no_api_key">
	<!----
	<cfif CGI.HTTPS neq "on">
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='auth fail'>
		<cfset r["error"]='A secure connection is required.'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="426" statustext="Upgrade Required">
		<cfreturn r>
		<cfabort>
	</cfif>
	---->
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<!------------------- END standard-issue welcome mat -------->
	<cfargument name="sch_node" type="string" required="false" default="collecting_event">
	<cfset theAppendix="">
	<cfset qp=[]>
	<cfparam name="orderby" default="higher_geog">
	<cfparam name="orderDir" default="asc">
	<cfparam name="start" default="1">
	<cfparam name="length" default="1">
	<cfparam name="rqstAction" default="json">
	<cfparam name="geog_rslt_cols" default="">
	<cfparam name="loc_rslt_cols" default="">

	<cftry>
		<cfset srtColumn=StructFind(form,"order[0][column]")>
		<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
		<cfcatch>
			<cfset orderby="higher_geog">
		</cfcatch>
	</cftry>
	<cftry>
		<cfset orderDir=StructFind(form,"order[0][dir]")>
		<cfcatch>
			<cfset orderDir="asc">
		</cfcatch>
	</cftry>
	<cfset tbls="">
	<cftry>
		<cfoutput>
			<cfif sch_node is "geog_auth_rec">
				<cfset flds=getPlaceColumns(srch_type="geog",col_list=geog_rslt_cols)>
				<cfset tbls="geog_auth_rec">
			<cfelseif sch_node is "locality">
				<cfset flds=getPlaceColumns(srch_type="locality",col_list=loc_rslt_cols)>
				<cfset tbls="geog_auth_rec inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
			<cfelseif sch_node is "collecting_event">
				<cfset flds=getPlaceColumns(srch_type="collecting_event",col_list=evnt_rslt_cols)>
				<cfset tbls=" geog_auth_rec inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id
					 inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
			<cfelse>
				<cfset r.status='fail'>
				<cfset r.message="bad node">
				<cfheader statuscode="500">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfif isdefined("table_name") and len(table_name) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfif tbls does not contain " specimen_event ">
					<cfset tbls=tbls & " inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id ">
				</cfif>
				<cfif tbls does not contain " cataloged_item ">
					<cfset tbls=tbls & " inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id ">
				</cfif>
				<cfset tbls=tbls & " inner join #table_name# on cataloged_item.collection_object_id=#table_name#.collection_object_id ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="#table_name#.collection_object_id">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("collection_id") and len(collection_id) gt 0>
				<cfif not isdefined("collnOper") or len(collnOper) is 0>
					<cfset collnOper="usedOnlyBy">
				</cfif>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<!--- Plan B: --->
				<cfif collnOper is "usedOnlyBy">

					<!---- used by ---->

					<cfset tbls=tbls & " inner join (select string_agg(collection_id::text,$$|$$) as cidlist,locality_id from (
					    select collection.collection_id,locality.locality_id from
					    collection
					    inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
					    inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
					    inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
					    inner join locality on collecting_event.locality_id=locality.locality_id
					    group by collection.collection_id,locality.locality_id
					    ) x group by locality_id
					    ) colln_join on locality.locality_id=colln_join.locality_id ">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="=">
					<cfset thisrow.t="colln_join.cidlist">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>




					<!----------------




					<cfset theAppendix=theAppendix & " and locality.locality_id in (
						select collecting_event.locality_id from
						collecting_event,
						specimen_event,
						cataloged_item
						where
						collecting_event.collecting_event_id=specimen_event.collecting_event_id and
						specimen_event.collection_object_id=cataloged_item.collection_object_id and
						cataloged_item.collection_id=#val(collection_id)# ) ">
					<!--- and no others --->

					<cfset theAppendix=theAppendix & " and locality.locality_id not in (
						select collecting_event.locality_id from
						collecting_event,
						specimen_event,
						cataloged_item,
						collection
						where
						collecting_event.collecting_event_id=specimen_event.collecting_event_id and
						specimen_event.collection_object_id=cataloged_item.collection_object_id and
						cataloged_item.collection_id=collection.collection_id and
						collection.collection_id != #val(collection_id)# ) ">
						------------>


				<cfelseif collnOper is "usedBy">

					<!------------
					<cfset theAppendix=theAppendix & " and locality.locality_id in (
						select collecting_event.locality_id from
						collecting_event,
						specimen_event,
						cataloged_item
						where
						collecting_event.collecting_event_id=specimen_event.collecting_event_id and
						specimen_event.collection_object_id=cataloged_item.collection_object_id and
						cataloged_item.collection_id=#val(collection_id)# ) ">
						------------->

					<cfset tbls=tbls & " inner join (
						select collection.collection_id,locality.locality_id from collection
						inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
						inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
						inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
						inner join locality on collecting_event.locality_id=locality.locality_id
						) colln_join on locality.locality_id=colln_join.locality_id ">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="=">
					<cfset thisrow.t="colln_join.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

				<cfelseif collnOper is "notUsedBy">

					<!----------
					<cfset theAppendix=theAppendix & " and locality.locality_id not in (
						select collecting_event.locality_id from
						collecting_event,
						specimen_event,
						cataloged_item
						where
						collecting_event.collecting_event_id=specimen_event.collecting_event_id and
						specimen_event.collection_object_id=cataloged_item.collection_object_id and
						cataloged_item.collection_id != #val(collection_id)# ) ">
						-------->

						<cfset tbls=tbls & " inner join (
						select collection.collection_id,locality.locality_id from collection
						inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
						inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
						inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
						inner join locality on collecting_event.locality_id=locality.locality_id
						) colln_join on locality.locality_id=colln_join.locality_id ">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="!=">
					<cfset thisrow.t="colln_join.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

				</cfif>


				<!-----------------------

				this returns multiple rows and distinct is expensive everywhere so.....Plan B

				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfif tbls does not contain " specimen_event ">
					<cfset tbls=tbls & " inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id ">
				</cfif>

				<cfif tbls does not contain " cataloged_item ">
					<cfset tbls=tbls & " inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id ">
				</cfif>

				<cfif collnOper is "usedOnlyBy">
					<cfset tbls=tbls & " inner join collection as exclusive_colln on cataloged_item.collection_id=exclusive_colln.collection_id ">
					<cfset tbls=tbls & " left outer join collection as exclude_colln on cataloged_item.collection_id=exclude_colln.collection_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="true">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="IN">
					<cfset thisrow.t="exclusive_colln.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

					<cfset thisrow={}>
					<cfset thisrow.l="true">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="NOT IN">
					<cfset thisrow.t="exclude_colln.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

				<cfelseif collnOper is "usedBy">
					<cfset thisrow={}>
					<cfset thisrow.l="true">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="IN">
					<cfset thisrow.t="cataloged_item.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

				<cfelseif collnOper is "notUsedBy">
					<cfset thisrow={}>
					<cfset thisrow.l="true">
					<cfset thisrow.d="cf_sql_int">
					<cfset thisrow.o="NOT IN">
					<cfset thisrow.t="cataloged_item.collection_id">
					<cfset thisrow.v=collection_id>
					<cfset arrayappend(qp,thisrow)>

				</cfif>
				----------------------->
			</cfif>

			<cfif isdefined("locality_id") and len(locality_id) gt 0>

				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>

				<cfset thisrow={}>
				<cfset thisrow.l="true">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.o="IN">
				<cfset thisrow.t="locality.locality_id">
				<cfset thisrow.v=locality_id>
				<cfset arrayappend(qp,thisrow)>
			</cfif>


			<cfset numEvtAttrs=5>
			<cfloop from="1" to="#numEvtAttrs#" index="i">
				<cfif isdefined("event_attribute_type_#i#")>
					<cfset thisAttr=evaluate("event_attribute_type_" & i)>
					<cfif len(thisAttr) gt 0>
						<cfset thisAttrVal="">
						<cfset thisAttrUnit="">
						<cfset thisAttrDetr="">
						<cfset thisAttrMeth="">
						<cfset thisAttrRemk="">

						<cfif isdefined("event_attribute_value_#i#")>
							<cfset thisAttrVal=evaluate("event_attribute_value_" & i)>
						</cfif>
						<cfif isdefined("event_attribute_unit_#i#")>
							<cfset thisAttrUnit=evaluate("event_attribute_unit_" & i)>
						</cfif>
						<cfif isdefined("event_attribute_determiner_#i#")>
							<cfset thisAttrDetr=evaluate("event_attribute_determiner_" & i)>
						</cfif>
						<cfif isdefined("event_attribute_method_#i#")>
							<cfset thisAttrMeth=evaluate("event_attribute_method_" & i)>
						</cfif>
						<cfif isdefined("event_attribute_remark_#i#")>
							<cfset thisAttrRemk=evaluate("event_attribute_remark_" & i)>
						</cfif>

						<cfif tbls does not contain " locality ">
							<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
						</cfif>
						<cfif tbls does not contain " collecting_event ">
							<cfset tbls=tbls & " inner join collecting_event on locality.locality_id = collecting_event.locality_id ">
						</cfif>

						<cfset tbls = " #tbls# INNER JOIN collecting_event_attributes collecting_event_attributes_#i# ON (collecting_event.collecting_event_id = collecting_event_attributes_#i#.collecting_event_id)">
						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_type">
						<cfset thisrow.o="=">
						<cfset thisrow.v=thisAttr>
						<cfset arrayappend(qp,thisrow)>
						<cfif len(thisAttrVal) gt 0>
							<cfif left(thisAttrVal,1) is '='>
								<cfset thisrow={}>
								<cfset thisrow.l="false">
								<cfset thisrow.d="cf_sql_varchar">
								<cfset thisrow.t=" upper(collecting_event_attributes_#i#.event_attribute_value)">
								<cfset thisrow.o="=">
								<cfset thisrow.v='#ucase(right(thisAttrVal,len(thisAttrVal)-1))#'>
								<cfset arrayappend(qp,thisrow)>
							<cfelse>
								<cfset thisrow={}>
								<cfset thisrow.l="false">
								<cfset thisrow.d="cf_sql_varchar">
								<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_value">
								<cfset thisrow.o="ilike">
								<cfset thisrow.v='%#thisAttrVal#%'>
								<cfset arrayappend(qp,thisrow)>
							</cfif>
						</cfif>
						<cfif len(thisAttrUnit) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_units">
							<cfset thisrow.o="=">
							<cfset thisrow.v=thisAttrUnit>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisAttrDetr) gt 0>
							<cfset tbls = " #tbls# INNER JOIN 
								agent_attribute evt_att_detr_#i# on collecting_event_attributes_#i#.determined_by_agent_id=evt_att_detr_#i#.agent_id and 
								evt_att_detr_#i#.deprecation_type is null 
								inner join ctagent_attribute_type ctattrtyp#i# on evt_att_detr_#i#.attribute_type=ctattrtyp#i#.attribute_type and
								ctattrtyp#i#.purpose='name' ">
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="evt_att_detr_#i#.attribute_value">
							<cfset thisrow.o="ilike">
							<cfset thisrow.v='%#thisAttrDetr#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisAttrMeth) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="collecting_event_attributes_#i#.event_determination_method">
							<cfset thisrow.o="ilike">
							<cfset thisrow.v='%#thisAttrMeth#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisAttrRemk) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_remark">
							<cfset thisrow.o="ilike">
							<cfset thisrow.v='%#thisAttrRemk#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>



			<cfset numLocalityAttributeSearchTerms=5>
			<cfloop from="1" to="#numLocalityAttributeSearchTerms#" index="i">
				<cfif isdefined("locality_attribute_type_#i#")>
					<cfset thisLocAttr=evaluate("locality_attribute_type_" & i)>
					<cfif len(thisLocAttr) gt 0>
						<cfset thisLocAttrVal="">
						<cfset thisLocAttrUnit="">
						<cfset thisLocAttrDetr="">
						<cfset thisLocAttrMeth="">
						<cfset thisLocAttrRemk="">

						<cfif isdefined("locality_attribute_value_#i#")>
							<cfset thisLocAttrVal=evaluate("locality_attribute_value_" & i)>
						</cfif>
						<cfif isdefined("locality_attribute_unit_#i#")>
							<cfset thisLocAttrUnit=evaluate("locality_attribute_unit_" & i)>
						</cfif>
						<cfif isdefined("locality_attribute_determiner_#i#")>
							<cfset thisLocAttrDetr=evaluate("locality_attribute_determiner_" & i)>
						</cfif>
						<cfif isdefined("locality_attribute_method_#i#")>
							<cfset thisLocAttrMeth=evaluate("locality_attribute_method_" & i)>
						</cfif>
						<cfif isdefined("locality_attribute_remark_#i#")>
							<cfset thisLocAttrRemk=evaluate("locality_attribute_remark_" & i)>
						</cfif>
						<cfif tbls does not contain " locality ">
							<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
						</cfif>

						<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_#i# ON (locality.locality_id = locality_attributes_#i#.locality_id)">
						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="locality_attributes_#i#.attribute_type">
						<cfset thisrow.o="=">
						<cfset thisrow.v=thisLocAttr>
						<cfset arrayappend(qp,thisrow)>
						<cfif len(thisLocAttrVal) gt 0>
							<cfif left(thisLocAttrVal,1) is '='>
								<cfset thisrow={}>
								<cfset thisrow.l="false">
								<cfset thisrow.d="cf_sql_varchar">
								<cfset thisrow.t=" upper(locality_attributes_#i#.attribute_value)">
								<cfset thisrow.o="=">
								<cfset thisrow.v='#ucase(right(thisLocAttrVal,len(thisLocAttrVal)-1))#'>
								<cfset arrayappend(qp,thisrow)>
							<cfelse>
								<cfset thisrow={}>
								<cfset thisrow.l="false">
								<cfset thisrow.d="cf_sql_varchar">
								<cfset thisrow.t=" upper(locality_attributes_#i#.attribute_value)">
								<cfset thisrow.o="like">
								<cfset thisrow.v='%#ucase(thisLocAttrVal)#%'>
								<cfset arrayappend(qp,thisrow)>
							</cfif>
						</cfif>
						<cfif len(thisLocAttrUnit) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="locality_attributes_#i#.attribute_units">
							<cfset thisrow.o="=">
							<cfset thisrow.v=thisLocAttrUnit>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisLocAttrDetr) gt 0>
							<cfset tbls = " #tbls# INNER JOIN 
								agent_attribute loc_att_detr_#i# on locality_attributes_#i#.determined_by_agent_id=loc_att_detr_#i#.agent_id and 
								loc_att_detr_#i#.deprecation_type is null 
								inner join ctagent_attribute_type ctlattrtyp#i# on loc_att_detr_#i#.attribute_type=ctlattrtyp#i#.attribute_type and
								ctlattrtyp#i#.purpose='name' ">

							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="loc_att_detr_#i#.attribute_value">
							<cfset thisrow.o="ilike">
							<cfset thisrow.v='%#thisLocAttrDetr#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisLocAttrMeth) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(locality_attributes_#i#.determination_method)">
							<cfset thisrow.o="like">
							<cfset thisrow.v='%#ucase(thisLocAttrMeth)#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
						<cfif len(thisLocAttrRemk) gt 0>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(locality_attributes_#i#.attribute_remark)">
							<cfset thisrow.o="like">
							<cfset thisrow.v='%#ucase(thisLocAttrRemk)#%'>
							<cfset arrayappend(qp,thisrow)>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>

			<cfif isdefined("attribute_meta_term") and len(attribute_meta_term) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>	
				<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_ms ON (locality.locality_id = locality_attributes_ms.locality_id)">
				<cfset tbls = " #tbls# INNER JOIN code_table_metadata on locality_attributes_ms.attribute_value=code_table_metadata.data_value and 
					code_table_metadata.meta_type in ($$included in$$,$$includes$$) ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="code_table_metadata.meta_value">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='%#attribute_meta_term#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("datum") and len(datum) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="locality.datum">
				<cfset thisrow.o="=">
				<cfset thisrow.v=datum>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("max_err_m") and len(max_err_m) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " left outer join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif not listfind("=,<,>",left(max_err_m,1)) or not isnumeric(mid(max_err_m,2,999))>
					<cfset r.status='fail'>
					<cfset r.message="max_err_m format is (=,<, or >) followed by an integer.">
					<cfheader statuscode="500">
					<cfreturn r>
					<cfabort>
				</cfif>
				<cfset opr=left(max_err_m,1)>
				<cfset ivl=right(max_err_m,len(max_err_m)-1)>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="to_meters(locality.max_error_distance,locality.max_error_units)">
				<cfset thisrow.o="#opr#">
				<cfset thisrow.v=ivl>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("dec_lat") and len(dec_lat) gt 0 and dec_lat is not "0" and isdefined("dec_long") and len(dec_long) gt 0 and dec_long is not "0">
				<cfif not isdefined("search_precision")>
					<cfset search_precision=2>
				</cfif>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif search_precision is "0">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="round(locality.dec_lat)">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#round(dec_lat)#">
					<cfset arrayappend(qp,thisrow)>

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="round(locality.dec_long)">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#round(dec_long)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelseif search_precision is "exact">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="locality.dec_lat">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#dec_lat#">
					<cfset arrayappend(qp,thisrow)>

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="locality.dec_long">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#dec_long#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset nf="00.">
					<cfloop from="1" to="#search_precision#" index="i">
						<cfset nf=nf & "0">
					</cfloop>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="round(locality.dec_lat,#search_precision#)">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#numberformat(dec_lat,nf)#">
					<cfset arrayappend(qp,thisrow)>

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="round(locality.dec_long,#search_precision#)">
					<cfset thisrow.o="=">
					<cfset thisrow.v="#numberformat(dec_long,nf)#">
					<cfset arrayappend(qp,thisrow)>
					<!----
					<cfset qual = "#qual# AND round(locality.dec_lat) =  and
							round(locality.dec_long,#search_precision#)= ">
					---->
				</cfif>

			</cfif>
			<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="geog_auth_rec.geog_auth_rec_id">
				<cfset thisrow.o="=">
				<cfset thisrow.v=geog_auth_rec_id>
				<cfset arrayappend(qp,thisrow)>

			</cfif>
			<cfif isdefined("collecting_event_id") and len(collecting_event_id) gt 0>

				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>

				<cfset thisrow={}>
				<cfset thisrow.l="true">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="collecting_event.collecting_event_id">
				<cfset thisrow.o="IN">
				<cfset thisrow.v=collecting_event_id>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif not isdefined("begDateOper")>
				<cfset begDateOper="=">
			</cfif>
			<cfif not isdefined("maxElevOper")>
				<cfset maxElevOper="=">
			</cfif>
			<cfif not isdefined("minElevOper")>
				<cfset minElevOper="=">
			</cfif>

			<cfif not isdefined("MinDepOper")>
				<cfset MinDepOper="=">
			</cfif>
			<cfif not isdefined("MaxDepOper")>
				<cfset MaxDepOper="=">
			</cfif>

			<cfif isdefined("began_date") and len(began_date) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>

				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="collecting_event.began_date">
				<cfset thisrow.o=begDateOper>
				<cfset thisrow.v=began_date>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("ended_date") and len(ended_date) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="collecting_event.ended_date">
				<cfset thisrow.o=endDateOper>
				<cfset thisrow.v=ended_date>
				<cfset arrayappend(qp,thisrow)>

			</cfif>

			<cfif isdefined("verbatim_date") and len(verbatim_date) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.verbatim_date)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(verbatim_date)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("verbatim_locality") and len(verbatim_locality) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.verbatim_locality)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(verbatim_locality)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>


		<cfif isdefined("collecting_event_name") and len(collecting_event_name) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfif left(collecting_event_name,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t=" upper(collecting_event.collecting_event_name)">
					<cfset thisrow.o="=">
					<cfset thisrow.v='#ucase(right(collecting_event_name,len(collecting_event_name)-1))#'>
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(collecting_event.collecting_event_name)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='%#ucase(collecting_event_name)#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("coll_event_remarks") and len(coll_event_remarks) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.coll_event_remarks)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(coll_event_remarks)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("collecting_source") and len(collecting_source) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.collecting_source)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(collecting_source)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("collecting_method") and len(collecting_method) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.collecting_method)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(collecting_method)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("habitat") and len(habitat) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(collecting_event.habitat)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(habitat)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>


			<cfif isdefined("locality_name") and len(locality_name) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif left(locality_name,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t=" upper(locality.locality_name)">
					<cfset thisrow.o="=">
					<cfset thisrow.v='#ucase(right(locality_name,len(locality_name)-1))#'>
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(locality.locality_name)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='%#ucase(locality_name)#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>


			<cfif isdefined("spec_locality") and len(spec_locality) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>

				<cfif left(spec_locality,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t=" upper(locality.spec_locality)">
					<cfset thisrow.o="=">
					<cfset thisrow.v='#ucase(right(spec_locality,len(spec_locality)-1))#'>
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(locality.spec_locality)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='%#ucase(spec_locality)#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>

			<cfif isdefined("maximum_elevation") and len(maximum_elevation) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="locality.maximum_elevation">
				<cfset thisrow.o="#maxElevOper#">
				<cfset thisrow.v=maximum_elevation>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("minimum_elevation") and len(minimum_elevation) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="locality.minimum_elevation">
				<cfset thisrow.o="#minElevOper#">
				<cfset thisrow.v=minimum_elevation>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("orig_elev_units") and len(orig_elev_units) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="locality.orig_elev_units">
				<cfset thisrow.o="=">
				<cfset thisrow.v=orig_elev_units>
				<cfset arrayappend(qp,thisrow)>
			</cfif>


			<cfif isdefined("maximum_depth") and len(maximum_depth) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="locality.max_depth">
				<cfset thisrow.o="#MaxDepOper#">
				<cfset thisrow.v=maximum_depth>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("minimum_depth") and len(minimum_depth) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="locality.min_depth">
				<cfset thisrow.o="#MinDepOper#">
				<cfset thisrow.v=minimum_depth>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("depth_units") and len(depth_units) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="locality.depth_units">
				<cfset thisrow.o="=">
				<cfset thisrow.v=depth_units>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif isdefined("locality_remarks") and len(locality_remarks) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(locality.locality_remarks)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(locality_remarks)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("has_ocean_sea") and len(has_ocean_sea) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="int">
				<cfset thisrow.t="length(concat(geog_auth_rec.ocean,geog_auth_rec.sea))">
				<cfif has_ocean_sea is 1>
					<cfset thisrow.o=">">
				<cfelse>
					<cfset thisrow.o="=">
				</cfif>
				<cfset thisrow.v="0">				
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("continent") and len(continent) gt 0>
				<cfif compare(continent,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.continent">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(continent,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.continent">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(continent,len(continent)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.continent">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#continent#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("ocean") and len(ocean) gt 0>
				<cfif compare(ocean,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.ocean">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(ocean,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.ocean">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(ocean,len(ocean)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.ocean">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#ocean#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("country") and len(country) gt 0>
				<cfif compare(country,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.country">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(country,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.country">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(country,len(country)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.country">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#country#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("state_prov") and len(state_prov) gt 0>
				<cfif compare(state_prov,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.state_prov">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(state_prov,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.state_prov">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(state_prov,len(state_prov)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.state_prov">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#state_prov#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("county") and len(county) gt 0>
				<cfif compare(county,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.county">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(county,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.county">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(county,len(county)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.county">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#county#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("quad") and len(quad) gt 0>
				<cfif compare(quad,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.quad">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(quad,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.quad">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(quad,len(quad)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.quad">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#quad#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("feature") and len(feature) gt 0>
				<cfif compare(feature,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.feature">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelse><!--- default is exact --->
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.feature">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#feature#">
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("island_group") and len(island_group) gt 0>
				<cfif compare(island_group,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.island_group">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelse><!--- default is exact --->
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.island_group">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#island_group#">
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("island") and len(island) gt 0>
				<cfif compare(island,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.island">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(island,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.island">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(island,len(island)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.island">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#island#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("geog_remark") and len(geog_remark) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="geog_auth_rec.geog_remark">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='%#geog_remark#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("sea") and len(sea) gt 0>
				<cfif compare(sea,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.sea">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(sea,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.sea">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(sea,len(sea)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.sea">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#sea#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("waterbody") and len(waterbody) gt 0>
				<cfif compare(waterbody,"NULL") is 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="isnull">
					<cfset thisrow.t="geog_auth_rec.waterbody">
					<cfset thisrow.o="">
					<cfset thisrow.v=''>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif left(waterbody,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.waterbody">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v="#right(waterbody,len(waterbody)-1)#">
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.waterbody">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#waterbody#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("higher_geog") and len(higher_geog) gt 0>
				<cfif not isdefined("higher_geog_operator") or (
					higher_geog_operator is not "contains" and
					higher_geog_operator is not "is" and
					higher_geog_operator is not "starts_with" and
					higher_geog_operator is not "ends_with")>
					<cfset higher_geog_operator='contains'>
				</cfif>
				<cfif higher_geog_operator is "contains">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(geog_auth_rec.higher_geog)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='%#ucase(higher_geog)#%'>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif higher_geog_operator is "is">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="geog_auth_rec.higher_geog">
					<cfset thisrow.o="=">
					<cfset thisrow.v=higher_geog>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif higher_geog_operator is "starts_with">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(geog_auth_rec.higher_geog)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='#ucase(higher_geog)#%'>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif higher_geog_operator is "ends_with">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="upper(geog_auth_rec.higher_geog)">
					<cfset thisrow.o="like">
					<cfset thisrow.v='%#ucase(higher_geog)#'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif isdefined("any_geog") and len(any_geog) gt 0>
				<cfset tbls=tbls & " inner join (
					select geog_auth_rec.geog_auth_rec_id,geog_auth_rec.higher_geog as trm from geog_auth_rec
					union
					select geog_search_term.geog_auth_rec_id, geog_search_term.search_term as trm from geog_search_term
				) as gst on geog_auth_rec.geog_auth_rec_id=gst.geog_auth_rec_id ">

				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(gst.trm)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(any_geog)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("verificationstatus") and len(verificationstatus) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfif tbls does not contain " collecting_event ">
					<cfset tbls=tbls & " inner join collecting_event on locality.locality_id=collecting_event.locality_id ">
				</cfif>
				<cfif tbls does not contain " specimen_event ">
					<cfset tbls=tbls & " inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(specimen_event.verificationstatus)">
				<cfset thisrow.o="=">
				<cfset thisrow.v='#verificationstatus#'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif isdefined("georeference_protocol") and len(georeference_protocol) gt 0>
				<cfif tbls does not contain " locality ">
					<cfset tbls=tbls & " inner join locality on geog_auth_rec.geog_auth_rec_id = locality.geog_auth_rec_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(locality.georeference_protocol)">
				<cfset thisrow.o="=">
				<cfset thisrow.v='#georeference_protocol#'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<!--- error if no search terms ---->
			<cfif IsEmpty(qp) is true >
				<cfset r["recordsTotal"]=0>
				<cfset r["recordsFiltered"]=0>
				<cfset r.data=[]>
				<cfreturn r>
			</cfif>
			<cfif sch_node is "locality" or sch_node is "collecting_event">
				<cfset tbls=tbls & " left outer join (select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$) pala on locality.locality_id=pala.locality_id ">
				<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
				<cfset thisrow={}>
				<cfset thisrow.l="true">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="coalesce(pala.attribute_value,$$public$$)">
				<cfset thisrow.o="in">
				<cfset thisrow.v=guaranteed_public_roles>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfset qal=arraylen(qp)>
			<cfif rqstAction is "download">
				<!---
					skip the count-query
					run the pull-query, without limits
					make CSV, return the filepath
				---->
				<cfquery name="localityResults" timeout="55" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select distinct
					<!----distinct ----->
					#preserveSingleQuotes(flds)# from #tbls# where 1=1
					<cfif qal gt 0> and </cfif>
					<cfloop from="1" to="#qal#" index="i">
						#preserveSingleQuotes(qp[i].t)#
						#qp[i].o#
						<cfif qp[i].d is "isnull">
							is null
						<cfelseif qp[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
							<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
					#preserveSingleQuotes(theAppendix)#
					order by #orderby# #orderDir#
				</cfquery>
				<cfset  util = CreateObject("component","component.utilities")>
				<cfset csv = util.QueryToCSV2(Query=localityResults,Fields=localityResults.columnlist)>
				<cfset fileName="downloadCollectingEvent_#RandRange(1,10000)##RandRange(1,10000)##RandRange(1,10000)##RandRange(1,10000)#.csv">
				<cffile action = "write"
					mode="664"
				    file = "#Application.webDirectory#/download/#fileName#"
			    	output = "#csv#"
			    	addNewLine = "no">
			    <cfset r.status="OK">
			    <cfset r.filePath="#Application.serverRootURL#/download/#fileName#">
				<cfset r.fileName=fileName>
				<cfreturn r>
				<cfabort>
			</cfif>

			<cfif rqstAction is "getDistinctLocalityID">
				<cfquery name="localityResults" timeout="55" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select string_agg(distinct(locality.locality_id::varchar),',') as locids from #tbls# where 1=1
					<cfif qal gt 0> and </cfif>
					<cfloop from="1" to="#qal#" index="i">
						#preserveSingleQuotes(qp[i].t)#
						#qp[i].o#
						<cfif qp[i].d is "isnull">
							is null
						<cfelseif qp[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
							<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
					#preserveSingleQuotes(theAppendix)#
				</cfquery>
				<cfset r.status="OK">
			    <cfset r.locids=localityResults.locids>
				<cfreturn r>
			</cfif>

			<cfif rqstAction is "getDistinctEventID">
				<cfquery name="localityResults" timeout="30" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select string_agg(distinct(collecting_event.collecting_event_id::varchar),',') as ceids from #tbls# where 1=1
					<cfif qal gt 0> and </cfif>
					<cfloop from="1" to="#qal#" index="i">
						#preserveSingleQuotes(qp[i].t)#
						#qp[i].o#
						<cfif qp[i].d is "isnull">
							is null
						<cfelseif qp[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
							<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
					#preserveSingleQuotes(theAppendix)#
				</cfquery>
				<cfset r.status="OK">
			    <cfset r.ceids=localityResults.ceids>
				<cfreturn r>
			</cfif>
			<!--- https://github.com/ArctosDB/arctos/issues/3822 - pulling DISTINCT for the data, need to group the count as well --->

			<cfif sch_node is "geog_auth_rec">
				<cfset cntFld = "geog_auth_rec.geog_auth_rec_id">
			<cfelseif sch_node is "locality">
				<cfset cntFld = "locality.locality_id">
			<cfelseif sch_node is "collecting_event">
				<cfset cntFld = "collecting_event.collecting_event_id">
			</cfif>

			<cfquery name="localityResultsCNT" timeout="55" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
				count(distinct(#cntFld#)) AS c from #tbls# where 1=1
				<cfif qal gt 0> and </cfif>
				<cfloop from="1" to="#qal#" index="i">
					#preserveSingleQuotes(qp[i].t)#
					#qp[i].o#
					<cfif qp[i].d is "isnull">
						is null
					<cfelseif qp[i].d is "notnull">
						is not null
					<cfelse>
						<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
						<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
						<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
					</cfif>
					<cfif i lt qal> and </cfif>
				</cfloop>
				#preserveSingleQuotes(theAppendix)#
			</cfquery>

			<cfquery name="localityResults" result="localityResultsQryObj" timeout="30" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
				distinct
				<!----distinct ----->
				#preserveSingleQuotes(flds)# from #tbls# where 1=1
				<cfif qal gt 0> and </cfif>
				<cfloop from="1" to="#qal#" index="i">
					#preserveSingleQuotes(qp[i].t)#
					#qp[i].o#
					<cfif qp[i].d is "isnull">
						is null
					<cfelseif qp[i].d is "notnull">
						is not null
					<cfelse>
						<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
						<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
						<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
					</cfif>
					<cfif i lt qal> and </cfif>
				</cfloop>
				#preserveSingleQuotes(theAppendix)#
				order by #orderby# #orderDir#
				limit #length#
				offset #start#
			</cfquery>

			<!----
			<!--- barf out the SQL --->
			<cfset qsql=localityResultsQryObj.sql>
			<cfset qsql=replace(qsql,chr(9),"","all")>
			<cfset qsql=replace(qsql,chr(10),"","all")>
			<cfset qsql=replace(qsql,chr(13),"","all")>
			<cfset r.qsql=qsql>

			<cfset qsql=localityResultsQryObj.sql>
			<cfset r["theSQL"]=localityResultsQryObj.sql>
			<cfset r["queryParams"]=qp>

				<cfset qsql=localityResultsQryObj.sql>
			<cfset qsql=replace(qsql,chr(9),"","all")>
			<cfset qsql=replace(qsql,chr(10),"","all")>
			<cfset qsql=replace(qsql,chr(13),"","all")>
			<cfset r.qsql=qsql>
			<cfset r["localityResultsQryObj"]=localityResultsQryObj>


			---->

			<cfset r.data=localityResults>
			<cfset r["recordsTotal"]=localityResultsCNT.c>
			<cfset r["recordsFiltered"]=localityResultsCNT.c>
			<cfreturn r>
		</cfoutput>
	<cfcatch>
		<cfset r.status='fail'>
		<cfset msg="ERROR">
		<cfif isdefined("cfcatch.message")>
			<cfset msg=msg & '; ' & cfcatch.message>
		</cfif>
		<cfif isdefined("cfcatch.detail")>
			<cfset msg=msg & '; ' & cfcatch.detail>
		</cfif>
		<cfif isdefined("cfcatch.sql")>
			<cfset tmp=cfcatch.sql>
			<cfset tmp=replace(tmp,"\n","","all")>
			<cfset tmp=replace(tmp,"\t","","all")>
			<cfset tmp=replace(tmp,chr(10),"","all")>
			<cfset tmp=replace(tmp,chr(13),"","all")>
			<cfset msg=msg & '; ' & tmp>
		</cfif>
		<cfset r.message=msg>
		<cfheader statuscode="500">
		<cfreturn r>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->

<!----------------------------------------------------------------------------------------->
</cfcomponent>
