<cfinclude template="/includes/_header.cfm">
<cfinclude template="/Bulkloader/sharedconfig.cfm">
<cfif action is "getPureCSV">
	<cfquery name="bulkloader_template" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from bulkloader where 1=2
	</cfquery>
	<cfset flds=bulkloader_template.columnlist>
	
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=bulkloader_template,Fields=flds)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/bulkloader_template.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=bulkloader_template.csv" addtoken="false">
</cfif>
<cfif action is "nothing">
	<script>
		$(document).ready(function() {
			// allow shift-click to select multiple rows
		    var $chkboxes = $('input:checkbox');
		    var lastChecked = null;

		    $chkboxes.click(function(e) {
		        if (!lastChecked) {
		            lastChecked = this;
		            return;
		        }
		        if (e.shiftKey) {
		            var start = $chkboxes.index(this);
		            var end = $chkboxes.index(lastChecked);
		            $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
		        }
		        lastChecked = this;
		    });
		});
		function checkStuff(s,c){
			console.log(s);

			if (c=='all'){
				if (s==true){
					 $('input:checkbox').prop('checked', true);
				} else {
					 $('input:checkbox').prop('checked', false);
				}
			} else {
				if (s==true){
					 $('input:checkbox[data-type="' + c + '"]').prop('checked', true);
				} else {
					 $('input:checkbox[data-type="' + c + '"]').prop('checked', false);
				}
			}
		}

		function go(yn){
			$("#gocsv").val(yn);
			$("#blbf").submit();
		}

	</script>
	<cfoutput>
		<cfset title="Bulkloader Builder">
		<h3>Bulkloader Builder</h3>
		<p>
			Important: The default (customizable) option IS NOT authoritative (but we'll try to keep it happy). For an authoritative and complete template, 
			<a href="bulkloaderBuilder.cfm?action=getPureCSV">click this</a>.
		</p>
		<p>
			Required fields are ununcheckable and orangeish.
		</p>
		<p>
			<a href="https://docs.google.com/spreadsheets/d/1VbNC3k17WAHMum_qD5UYoXxUUWwXXh5gZSM5vfGvRzU" class="external">Field Documentation</a>
		</p>

		<!-----------------------

			This is shared code!
			... mostly, but can't figure out how to really make it modular without adding a lot of complexity, 
				so just keep it synced up between

				* form/customizeDataEntry2.cfm
				* Bulkloader/bulkloaderBuilder.cfm
		<cfset identifier_count=bulk_otherid_count>

		-------------------->

		<cfparam name="identifier_count" default="#bulk_otherid_count#">
		<cfparam name="identification_count" default="#bulk_identification_count#">
		<cfparam name="identification_attribute_count" default="#bulk_identification_attr_count#">
		<cfparam name="identification_determiner_count" default="#bulk_identification_detr_count#">
		<cfparam name="collector_count" default="#bulk_collector_count#">
		<cfparam name="locality_attribute_count" default="#bulk_loc_attr_count#">
		<cfparam name="event_attribute_count" default="#bulk_evt_attr_count#">
		<cfparam name="part_count" default="#bulk_part_count#">
		<cfparam name="part_attribute_count" default="#bulk_part_attr_count#">
		<cfparam name="attribute_count" default="#bulk_attr_count#">
		<!-------- remove some shared code here --------->
		<cfparam name="chkd" default="">
		<cfparam name="gocsv" default="false">

		<form method="post" action="bulkloaderBuilder.cfm" id="blbf">
			<input type="hidden" name="gocsv" id="gocsv" value="#gocsv#">
			<p>
				Check boxes (set counts first to save some checking), then <input type="button" class="lnkBtn" value="get CSV" onclick="go('true');">
			</p>
			<h4>Counts</h4>
			<input type="button" onclick="resetAllCount()" value="Reset Counts" class="clrBtn">
			<input type="button" class="savBtn" value="refresh with selections" onclick="go('false');">
			<div id="counts_ctr">
				<div>
					<label for="identifier_count">identifier_count: How many identifiers (Other IDs)?</label>
					<select name="identifier_count" id="identifier_count">
						<cfloop from="0" to="#bulk_otherid_count#" index="i">
							<option <cfif identifier_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>			
					<label for="identification_count">identification_count: How many identifications to view?</label>
					<select name="identification_count" id="identification_count">
						<cfloop from="1" to="#bulk_identification_count#" index="i">
							<option <cfif identification_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="identification_attribute_count">identification_attribute_count: How many attributes on each identification?</label>
					<select name="identification_attribute_count" id="identification_attribute_count">
						<cfloop from="0" to="#bulk_identification_attr_count#" index="i">
							<option <cfif identification_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="identification_determiner_count">identification_determiner_count: How many determiners on each identification?</label>
					<select name="identification_determiner_count" id="identification_determiner_count">
						<cfloop from="0" to="#bulk_identification_detr_count#" index="i">
							<option <cfif identification_determiner_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="collector_count">collector_count: How many collector-agents?</label>
					<select name="collector_count" id="collector_count">
						<cfloop from="0" to="#bulk_collector_count#" index="i">
							<option <cfif collector_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="locality_attribute_count">locality_attribute_count: How many locality attributes?</label>
					<select name="locality_attribute_count" id="locality_attribute_count">
						<cfloop from="0" to="#bulk_loc_attr_count#" index="i">
							<option <cfif locality_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="event_attribute_count">event_attribute_count: How many event attributes?</label>
					<select name="event_attribute_count" id="event_attribute_count">
						<cfloop from="0" to="#bulk_evt_attr_count#" index="i">
							<option <cfif event_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>		
					<label for="part_count">part_count: How many parts?</label>
					<select name="part_count" id="part_count">
						<cfloop from="0" to="#bulk_part_count#" index="i">
							<option <cfif part_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>				
					<label for="part_attribute_count">part_attribute_count: How many attributes for each part?</label>
					<select name="part_attribute_count" id="part_attribute_count">
						<cfloop from="0" to="#bulk_part_attr_count#" index="i">
							<option <cfif part_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="attribute_count">attribute_count: How many record attributes?</label>
					<select name="attribute_count" id="attribute_count">
						<cfloop from="0" to="#bulk_attr_count#" index="i">
							<option <cfif attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
				</div>
			</div>
		
			<p>
				Recommendation: Set the above then 
				<input type="button" class="savBtn" value="refresh with selections" onclick="go('false');"> to make the individual field selection (below) more approachable.
			</p>



			<!---- basically run through the form, add stuff using the loopcounts above ---->
			<cfset flds = querynew("k,o,t")>
			<!--- in the builder, not in eg customize ---->
			<cfset queryaddrow(flds,{k='guid_prefix',o='nohide',t='record'})>
			<cfset queryaddrow(flds,{k='enteredby',o='nohide',t='record'})>
			<cfset queryaddrow(flds,{k='status',o='',t='record'})>


			<cfset queryaddrow(flds,{k='cat_num',o='nodefault',t='record'})>
			<cfset queryaddrow(flds,{k='accn',o='nohide',t='record'})>
			<cfset queryaddrow(flds,{k='record_type',o='',t='record'})>
			<cfset queryaddrow(flds,{k='record_remark',o='',t='record'})>
			<cfloop from="1" to="#identifier_count#" index="i">
				<cfset queryaddrow(flds,{k='identifier_#i#_type',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_issued_by',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_value',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_relationship',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_remark',o='',t='identifier'})>
			</cfloop>
			<cfloop from="1" to="#identification_count#" index="i">
				<cfif i is 1>
					<cfset spc='nohide'>
				<cfelse>
					<cfset spc=''>
				</cfif>
				<cfset queryaddrow(flds,{k='identification_#i#',o='#spc#',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_order',o='#spc#',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_date',o='',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_sensu_publication',o='',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_remark',o='',t='identification'})>
				<cfloop from="1" to="#identification_determiner_count#" index="a">
					<cfset queryaddrow(flds,{k='identification_#i#_agent_#a#',o='',t='identification: agent'})>
				</cfloop>
				<cfloop from="1" to="#identification_attribute_count#" index="a">
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_type_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_value_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_determiner_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_units_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_date_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_method_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_remark_#a#',o='',t='identification: attribute'})>
				</cfloop>
			</cfloop>
			<cfloop from="1" to="#collector_count#" index="i">
				<cfset queryaddrow(flds,{k='agent_#i#_role',o='',t='agent/collector'})>
				<cfset queryaddrow(flds,{k='agent_#i#_name',o='',t='agent/collector'})>
			</cfloop>
			<cfset queryaddrow(flds,{k='locality_name',o='',t='locality: identifier'})>
			<cfset queryaddrow(flds,{k='locality_id',o='',t='locality: identifier'})>
			<cfset queryaddrow(flds,{k='locality_higher_geog',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_specific',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_remark',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_min_elevation',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_max_elevation',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_elev_units',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_min_depth',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_max_depth',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_depth_units',o='',t='locality: vertical'})>

			<cfloop from="1" to="#locality_attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_type',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_value',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_units',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_determiner',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_date',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_method',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_remark',o='',t='locality: attribute'})>
			</cfloop>

			<cfset queryaddrow(flds,{k='coordinate_lat_long_units',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_datum',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_max_error_distance',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_max_error_units',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_georeference_protocol',o='',t='coordinates'})>

			<cfset queryaddrow(flds,{k='coordinate_dec_lat',o='',t='coordinates: DD'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long',o='',t='coordinates: DD'})>

			<cfset queryaddrow(flds,{k='coordinate_lat_deg',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_min',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_sec',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_dir',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_deg',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_min',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_sec',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_dir',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_deg',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_min',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_dir',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_deg',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_min',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_dir',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_ew',o='',t='coordinates: UTM'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_ns',o='',t='coordinates: UTM'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_zone',o='',t='coordinates: UTM'})>

			<cfset queryaddrow(flds,{k='event_name',o='',t='event: identifier'})>
			<cfset queryaddrow(flds,{k='event_id',o='',t='event: identifier'})>

			<cfset queryaddrow(flds,{k='event_verbatim_locality',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_verbatim_date',o='',o='',t='event'})>			
			<cfset queryaddrow(flds,{k='event_began_date',o='',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_ended_date',o='',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_remark',o='',o='',t='event'})>

			<cfloop from="1" to="#event_attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='event_attribute_#i#_type',o='',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_value',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_units',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_determiner',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_date',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_method',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_remark',o='',t='event: attribute'})>
			</cfloop>

			<cfset queryaddrow(flds,{k='record_event_type',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_determiner',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_determined_date',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verificationstatus',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verified_by',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verified_date',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_collecting_source',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_collecting_method',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_habitat',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_remark',o='',t='record-event'})>

			<cfloop from="1" to="#attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='attribute_#i#_type',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_value',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_units',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_determiner',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_date',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_method',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_remark',o='',t='attribute'})>
			</cfloop>

			<cfloop from="1" to="#part_count#" index="i">
				<cfset queryaddrow(flds,{k='part_#i#_name',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_count',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_disposition',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_condition',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_barcode',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_remark',o='',t='part'})>
				<cfloop from="1" to="#part_attribute_count#" index="a">
					<cfset queryaddrow(flds,{k='part_#i#_attribute_type_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_value_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_units_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_determiner_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_date_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_method_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_remark_#a#',o='',t='part: attribute'})>
				</cfloop>
			</cfloop>
			<cfif not isdefined("chkd") or len(chkd) is 0>
				<cfset chkd=valuelist(flds.k)>
			</cfif>
			<input type="hidden" name="flds" value="#valuelist(flds.k)#">
			<h4>Individual Field Behavior</h4>
			<input type="button" class="lnkBtn" value="get CSV" onclick="go('true');">
			<cfquery name="d_cat" dbtype="query">
				select t from flds group by t order by t
			</cfquery>
			<cfset trclass='tblbgstripe'>
			<cfset lastCat=''>
			<!----------- table is slightly modified in shared code ---->
			<table border>
				<tr>
					<th>Category</th>
					<th>Field</th>
					<th><input checked class="allnonecheck" type="checkbox" onclick="checkStuff(this.checked,'all');"></th>
				</tr>
				<cfloop query="flds">
					<cfif lastcat is not t>
						<cfif trclass is 'tblbgstripe'>
							<cfset trclass=''>
						<cfelse>
							<cfset trclass='tblbgstripe'>
						</cfif>
					</cfif>
					<cfset lastCat=t>
					<tr class="#trclass#">
						<td>
							#t#
							<input checked class="allnonecheck" data-type="#t#" type="checkbox" onclick="checkStuff(this.checked,'#t#');">
						</td>
						<td>
							#k#
						</td>
						<td>
							<input <cfif  o is 'nohide'> class="requiredCheck" </cfif> data-type="#t#" <cfif listfind(chkd,k) or o is 'nohide'> checked </cfif> type="checkbox" value="#k#" name="chkd"></td>
					</tr>
				</cfloop>
			</table>
			<input type="button" class="lnkBtn" value="get CSV" onclick="go('true');">
		</form>
		<!-----------------------
			
			This is shared code!
			... mostly, but can't figure out how to really make it modular without adding a lot of complexity, 
				so just keep it synced up between

				* form/customizeDataEntry2.cfm
				* Bulkloader/bulkloaderBuilder.cfm

		-------------------->
		<cfif gocsv is "true">
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/bulkloader_template.csv"
			    output = "#chkd#"
			    addNewLine = "no">
			<cflocation url="/download.cfm?file=bulkloader_template.csv" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">