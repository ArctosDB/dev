<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
	<script>
		function checkuncheck(prefix,ckd,obj){
			if (prefix=='sc' && obj.indexOf('_')>0){
				var dlbl='subcategory';
			} else {
				var dlbl='category';
			}
			if (ckd=='true'){
				var ckd=true;
			} else{
				var ckd=false;
			}
			$('input[type=checkbox]').each(function() {
   				if ($(this).attr('name').substring(0,3)== prefix + '_'){
   					if ($(this).data(dlbl) == obj) { 
	       				$(this).prop('checked', ckd);
	       			}
       			}
			});
		}
		$(function() {
			$( "#sortable" ).sortable({
				handle: '.rowsorter'
			});
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
			$('#spn option').each(function () {
				var text = $(this).text();
				if (text.length > 100) {
					text = text.substring(0, 100) + '...';
					$(this).text(text);
				}
			});
		});
		function sveanduse(md){	
			if (md=='saveanduse'){
				$("#profile_name").val('');
			} else {
				var tpn=$("#profile_name").val();
				if (tpn.length < 1){
					alert('Profile Name is required for this operation.');
					return false;
				}
			}
			var srchtrms = [];
			var rslts = [];
			$('input[type=checkbox]').each(function() {
	   			if ($(this).is(":checked")) {
	   				if ($(this).attr('name').substring(0,3)=='sc_'){
	       				srchtrms.push($(this).attr('name').replace('sc_',''));
	       			}
	   				if ($(this).attr('name').substring(0,3)=='rc_'){
	       				rslts.push($(this).attr('name').replace('rc_',''));
	       			}
	   			}
			});
			var sts=srchtrms.join(',');
			var rts=rslts.join(',');
			$("#srchtrms").val(sts);
			$("#rslttrms").val(rts);
			$("#build_profile").submit();
		}
		
		function lsp(){
			var spn=$("#spn").val();
			if (spn.length<1){
				alert('First select a profile (above).')
				return false;
			}
			document.location='catRecordSearchProfile.cfm?pn=' + encodeURIComponent(spn);
		}
		function deleterchProfile(pn){
			if(confirm('Are you sure you want to delete this Profile? This cannot be undone.')){
				window.location='catRecordSearchProfile.cfm?action=delete&pn=' + encodeURIComponent(pn);
			}
		}
		<!----
		function adoptProfile (){
			var spn=$("#spn").val();
			if (spn.length<1){
				alert('Select a profile to load data.')
				return false;
			}
			window.location='catRecordSearchProfile.cfm?action=adopt&pn=' + encodeURIComponent(spn);
		}
		---->

		function toggleEllipsis(id) {
		  document.querySelector("#" + id).classList.toggle("text-truncate");
		}
	</script>
	<style>
		#twocolsholder{
			display: grid;
			grid-template-columns: 25em auto auto;

		}		
		.onecolthingee{
			margin-left: .2em;
			margin-right: .2em;
			padding-left: .2em;
			padding-right: .2em;
			background-color: var(--arctoslightblue);
		}
		.rowsorter {
			text-align: center;
			font-size: large;
		}
		.rowsorter:hover {
			cursor: move;
		}
		#srchdiv {
			max-height: 90vh;
			overflow: auto;
		}
		#metadiv {
			max-height: 90vh;
			overflow: auto;
		}
		#rcolsdv {
			max-height: 90vh;
			overflow: auto;
		}
		#spn{
			max-width: 15em;
		}
		#profilesummarydiv, #profiledescrdiv{
			font-size: smaller;
		}

		#profilesummarydiv:hover, #profiledescrdiv:hover{
  			cursor: pointer;
		}

		.text-truncate {
			max-width: 30em;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}
		.selectythingee{
			display: flex;
		    align-items: flex-end;
		}
		.btnholderflexy{}

		.descrTxt {
			font-size: smaller;
			font-weight: bolder;
		}
		.pfsftitle{
			font-size: medium;
			font-weight: bold;
		}

		.noshow{
			display: none;
		}
		
		.objNameDiv{
			white-space: nowrap;
		}
	</style>
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfquery name="default_profiles" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				profile_name,
	    		cf_username,
	    		description,
	    		search_fields,
	    		results_columns
	    	from cf_cat_rec_srch_profile 
	    	where  cf_username=<cfqueryparam cfsqltype="cf_sql_varchar" value="arctos">
	    	order by profile_name
	    </cfquery>
		<cfquery name="my_profiles" datasource="cf_codetables">
			select 
				profile_name,
	    		cf_username,
	    		description,
	    		search_fields,
	    		results_columns
	    	from cf_cat_rec_srch_profile 
	    	where  cf_username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
	    	order by profile_name
		</cfquery>

		<cfif isdefined("pn") and len(pn) gt 0>			
			<cfquery name="seed_with_profile"  datasource="cf_codetables">
				select 
					profile_name,
		    		cf_username,
		    		description,
		    		search_fields,
		    		results_columns
		    	from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
			</cfquery>
			<cfif seed_with_profile.recordcount is 1 and len(seed_with_profile.profile_name) gt 0>
				<cfset crsc=seed_with_profile.search_fields>
				<cfset crrc=seed_with_profile.results_columns>
			<cfelse>
				<cfset crsc=session.catrec_srch_cols>
				<cfset crrc=session.catrec_rslt_cols>
				<cfset pn="">
			</cfif>
		<cfelse>
			<cfset crsc=session.catrec_srch_cols>
			<cfset crrc=session.catrec_rslt_cols>
			<cfset pn="">
		</cfif>
		<form name="build_profile" id="build_profile" method="post" action="catRecordSearchProfile.cfm">
			<input type="hidden" name="action" value="buildsave">
			<input type="hidden" name="srchtrms" id="srchtrms">
			<input type="hidden" name="rslttrms" id="rslttrms">
			<cfquery name="cf_cat_rec_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select display,obj_name,default_order,category,subcategory,description from cf_cat_rec_srch_cols order by default_order
			</cfquery>			
			<div id="twocolsholder">
				<div id="metadiv" class="onecolthingee">
					<div class="pfsftitle">Search Options and Profiles</div>
					<div class="selectythingee">
						<div>
							<label for="spn">Select an existing Profile to "seed" selections</label>
							<select name="spn" id="spn" onchange="lsp();" class="highlightst">
								<option value="">select a profile to view/seed</option>
								<optgroup label="My Profiles">
									<cfloop query="my_profiles">
										<option <cfif pn is profile_name> selected="selected" </cfif> value="#profile_name#">#profile_name#</option>
									</cfloop>
								</optgroup>
								<optgroup label="Preset Profiles">
									<cfloop query="default_profiles">
										<option <cfif pn is profile_name> selected="selected" </cfif> value="#profile_name#">#profile_name#</option>
									</cfloop>
								</optgroup>
							</select>
						</div>
						<cfif isdefined("seed_with_profile") and seed_with_profile.cf_username is session.username>
							<div class="btnholderflexy">
								<input type="button" value="DELETE" onclick="deleterchProfile('#seed_with_profile.profile_name#');" class="delBtn">
							</div>
						</cfif>
					</div>
					<cfif isdefined("seed_with_profile") and seed_with_profile.recordcount gt 0>
						<div id="profilesummarydiv" onclick="toggleEllipsis(this.id)" class="text-truncate">
							Viewing <strong>#seed_with_profile.profile_name#</strong> created by <strong>#seed_with_profile.cf_username#</strong>
						</div>
						<cfif len(seed_with_profile.description) gt 0>
							<div id="profiledescrdiv" onclick="toggleEllipsis(this.id)" class="text-truncate">
								Description: #seed_with_profile.description#
							</div>
						</cfif>
					</cfif>
					<!----
					<hr>
					<div class="descrTxt">
						Option 1: Use selected profile without modification
					</div>

					<div class="btnholderflexy">
						<input type="button" value="Option 1: Adopt Selected Profile" class="insBtn" onclick="adoptProfile();" title="Use the selected Profile without modification">
					</div>
					---->
					<hr>
					<div class="descrTxt">
						Search using selected search and results options.
					</div>
					<input type="button" value="Use Selected" class="savBtn" onclick="sveanduse('saveanduse');" title="Choose search and results options to the right.">
					<cfif isdefined("session.username") and len(session.username) gt 0>
						<hr>
						<div class="descrTxt">
							 Save selected search and results options as a new Profile.
						</div>
						<label for="profile_name">Profile Name: Must be unique.</label>
						<input type="text" name="profile_name" id="profile_name" size="40" placeholder="profile_name" class="reqdClr">
						<!----
						<label for="creator">Creator</label>
						<input type="text" name="creator" size="40" placeholder="creator" value="#session.username#">
						---->
						<label for="description">Description (optional)</label>
						<input type="text" name="description" size="40" placeholder="description">
						<br><input type="button" value="Create and Use Profile" class="insBtn" onclick="sveanduse('mkprofile');" title="Profiles can be shared and reused.">
					</cfif>
				</div>
				<div id="srchdiv" class="onecolthingee">
					Select Search Options.
					<table border class="sortable" id="ssotbl">
						<tr>
							<th>Field</th>
							<th>⍻</th>
							<th>Category</th>
							<th>SubCategory</th>
						</tr>
						<cfloop query="cf_cat_rec_srch_cols">
							<tr data-category="#category#" data-subcategory="#category#_#subcategory#">
								<td>
									<div class="objNameDiv" title="#replace(description,'"','`','all')#">
										#display#
										<span id="info_st_#obj_name#_show" class="likeLink" onclick="toggleInfo('info_st_#obj_name#');">
											<i class="fa-solid fa-eye" title="Define"></i>
										</span>
										<span id="info_st_#obj_name#_hide" class="likeLink noshow" onclick="toggleInfo('info_st_#obj_name#');">
											<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
										</span>
									</div>
									<div class="noshow toggleDisplayBits" id="info_st_#obj_name#">#encodeForHTML(description)#</div>
								</td>
								<td>
									<input 
										data-category='#category#' 
										data-subcategory="#category#_#subcategory#" 
										type="checkbox" 
										name="sc_#obj_name#" <cfif listfind(crsc,obj_name)> checked </cfif> >
								</td>
								<td>
									<div class="nowrap">
										#category#
										<span class="likeLink" onclick="checkuncheck('sc','true','#category#');">
											<i class="fa-solid fa-check" title="Select all #category#"></i>
										</span>
										<span class="likeLink" onclick="checkuncheck('sc','false','#category#');">
											<i class="fa-solid fa-remove" title="UnSelect all #category#"></i>
										</span>
										
									</div>
								</td>
								<td>
									<div class="nowrap">
										#subcategory#
										<span class="likeLink" onclick="checkuncheck('sc','true','#category#_#subcategory#');">
											<i class="fa-solid fa-check" title="Select all #category#: #subcategory#"></i>
										</span>
										<span class="likeLink" onclick="checkuncheck('sc','false','#category#_#subcategory#');">
											<i class="fa-solid fa-remove" title="UnSelect all #category#: #subcategory#"></i>
										</span>
									</div>
								</td>
								<td></td>
							</tr>
						</cfloop>
					</table>
				</div>
				<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
					select obj_name,display,category,description,default_order,query_cost from cf_cat_rec_rslt_cols
				</cfquery>
				<cfquery name="profileselected" dbtype="query">
					select * from cf_cat_rec_rslt_cols where obj_name in (<cfqueryparam value="#crrc#" cfsqltype="cf_sql_varchar" list="true">)
				</cfquery>
				<cfquery name="profileunselected" dbtype="query">
					select * from cf_cat_rec_rslt_cols where obj_name not in (<cfqueryparam value="#crrc#" cfsqltype="cf_sql_varchar" list="true">) order by default_order
				</cfquery>
				<div id="rcolsdv" class="onecolthingee">
					Select Results Options. Drag to order.
					<table border class="sortable" id="srotbl">
						<tr>
							<th>Order</th>
							<th>⍻</th>
							<th>Field</th>
							<th>Category</th>
							<th>Cost
						</tr>
						<tbody id="sortable">
							<cfloop list="#crrc#" index="objname">
								<cfquery name="ton" dbtype="query">
									select * from profileselected where obj_name=<cfqueryparam value="#objname#" cfsqltype="cf_sql_varchar">
								</cfquery>
								<cfif ton.recordcount is 1>
									<tr>
										<td class="rowsorter">
											<i class="fas fa-grip-vertical" title="Drag to order"></i>
										</td>
										<td>
											<input data-category='#ton.category#' type="checkbox" name="rc_#ton.obj_name#" checked >
										</td>
										<td>
											<div class="objNameDiv" title="#replace(ton.description,'"','`','all')#">
												#ton.display#
												<span id="info_rt_#ton.obj_name#_show" class="likeLink" onclick="toggleInfo('info_rt_#ton.obj_name#');">
													<i class="fa-solid fa-eye" title="Define"></i>
												</span>
												<span id="info_rt_#ton.obj_name#_hide" class="likeLink noshow" onclick="toggleInfo('info_rt_#ton.obj_name#');">
													<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
												</span>
											</div>
											<div class="noshow toggleDisplayBits" id="info_rt_#ton.obj_name#">#encodeForHTML(ton.description)#</div>
										</td>
										<td>
											<div class="nowrap">
												#ton.category#
												<span class="likeLink" onclick="checkuncheck('rc','true','#ton.category#');">
													<i class="fa-solid fa-check" title="Select all #ton.category#"></i>
												</span>
												<span class="likeLink" onclick="checkuncheck('rc','false','#ton.category#');">
													<i class="fa-solid fa-remove" title="UnSelect all #ton.category#"></i>
												</span>
											</div>
										</td>
										<td>#ton.query_cost#</td>
									</tr>
								</cfif>
							</cfloop>
							<cfloop query="profileunselected">
								<tr>
									<td class="rowsorter">
										<i class="fas fa-grip-vertical"></i>
									</td>
									<td>
										<input data-category='#category#' type="checkbox" name="rc_#obj_name#" >
									</td>
									<td>
										<div class="objNameDiv" title="#replace(description,'"','`','all')#">
											#display#
											<span id="info_rt_#obj_name#_show" class="likeLink" onclick="toggleInfo('info_rt_#obj_name#');">
												<i class="fa-solid fa-eye" title="Define"></i>
											</span>
											<span id="info_rt_#obj_name#_hide" class="likeLink noshow" onclick="toggleInfo('info_rt_#obj_name#');">
												<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
											</span>
										</div>
										<div class="noshow toggleDisplayBits" id="info_rt_#obj_name#">#encodeForHTML(description)#</div>
									</td>
									<td>
										<div class="nowrap">
											#category#
											<span class="likeLink" onclick="checkuncheck('rc','true','#category#');">
												<i class="fa-solid fa-check" title="Select all #category#"></i>
											</span>
											<span class="likeLink" onclick="checkuncheck('rc','false','#category#');">
												<i class="fa-solid fa-remove" title="UnSelect all #category#"></i>
											</span>
										</div>
									</td>
									<td>#query_cost#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</form>
	</cfoutput>
</cfif>
<cfif action is "buildsave">
	<cfoutput>
		<!---- sanitize ---->
		<cfquery name="cf_cat_rec_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select obj_name,subcategory from cf_cat_rec_srch_cols 
		</cfquery>
		<cfset up_srchtrms="">
		<cfloop list="#srchtrms#" index="i">
			<cfquery name="isThere" dbtype="query">
				select obj_name from cf_cat_rec_srch_cols where obj_name =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#i#">
			</cfquery>
			<cfif isThere.recordcount is 1>
				<cfset up_srchtrms=listappend(up_srchtrms,isThere.obj_name)>
			</cfif>
		</cfloop>
		<cfif len(up_srchtrms) is 0>
			<cfquery name="isThere" dbtype="query">
				select obj_name from cf_cat_rec_srch_cols where subcategory='basic'
			</cfquery>
			<cfset up_srchtrms=valuelist(isThere.obj_name)>
		</cfif>
		<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
			select obj_name,display,category,description,default_order,query_cost from cf_cat_rec_rslt_cols
		</cfquery>
		<cfset up_rslttrms="">
		<cfloop list="#rslttrms#" index="i">
			<cfquery name="isThere" dbtype="query">
				select obj_name from cf_cat_rec_rslt_cols where obj_name =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#i#">
			</cfquery>
			<cfif isThere.recordcount is 1>
				<cfset up_rslttrms=listappend(up_rslttrms,isThere.obj_name)>
			</cfif>
		</cfloop>
		<cfif len(up_rslttrms) is 0>
			<cfquery name="isThere" dbtype="query">
				select obj_name from cf_cat_rec_srch_cols where category='core'
			</cfquery>
			<cfset up_rslttrms=valuelist(isThere.obj_name)>
		</cfif>
		<cfif isdefined("profile_name") and len(profile_name) gt 0>
			<!---- gogosososanitizer ---->
			<cfset spn=profile_name>
			<cfset spn=replace(spn, '"','','all')>
			<cfset spn=replace(spn, "'",'','all')>
			<cfset spn=replace(spn, "<",'','all')>
			<cfset spn=replace(spn, ">",'','all')>
			<cfset spn=replace(spn, "&",'','all')>
			<cfset spn=replace(spn, "=",'','all')>
			<cfset spn=replace(spn, "/",'','all')>
			<cfset spn=replace(spn, "\",'','all')>
			<cfset spn=trim(spn)>
			<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
				select 
					count(*) c 
				from 
					cf_cat_rec_srch_profile 
				where 
					regexp_replace(regexp_replace(lower(profile_name),'[[:punct:]\ ]','_','g'),'__','_','g')
					ilike 
					regexp_replace(regexp_replace(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#spn#">),'[[:punct:]\ ]','_','g'),'__','_','g')
			</cfquery>
			<cfif cf_cat_rec_rslt_cols.c gt 0 or left(profile_name,7) is 'preset_'>
				profile_name is not available; use your back button.<cfabort>
			</cfif>
			<cfquery name="mkcf_cat_rec_rslt_cols" datasource="uam_god">
				insert into cf_cat_rec_srch_profile (
				    profile_name,
				    cf_username,
				    description,
				    search_fields,
				    results_columns
				) values (
				    <cfqueryparam cfsqltype="cf_sql_varchar" value="#spn#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#description#" null="#Not Len(Trim(description))#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#up_srchtrms#" null="#Not Len(Trim(up_srchtrms))#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#rslttrms#" null="#Not Len(Trim(rslttrms))#">
				)
			</cfquery>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					catrec_srch_cols=<cfqueryparam value="#up_srchtrms#" CFSQLType="cf_sql_varchar">,
					catrec_rslt_cols=<cfqueryparam value="#up_rslttrms#" CFSQLType="cf_sql_varchar">
				WHERE
					username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset session.catrec_srch_cols=up_srchtrms>
			<cfset session.catrec_rslt_cols=up_rslttrms>
			<script>
				parent.$("##sp").val('#spn#');
				parent.reloadAtURL();
			</script>
		<cfelse>
			<!----- just save and rock on ---->
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					catrec_srch_cols=<cfqueryparam value="#up_srchtrms#" CFSQLType="cf_sql_varchar">,
					catrec_rslt_cols=<cfqueryparam value="#up_rslttrms#" CFSQLType="cf_sql_varchar">
				WHERE
					username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset session.catrec_srch_cols=up_srchtrms>
			<cfset session.catrec_rslt_cols=rslttrms>
			<script>
				parent.$("##sp").val('');
				parent.reloadAtURL();
			</script>
		</cfif>

	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfoutput>
		<cfquery name="cf_cat_rec_srch_profile" datasource="cf_codetables">
			select 
				profile_name,
	    		cf_username
	    	from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
		</cfquery>
		<cfif cf_cat_rec_srch_profile.cf_username is session.username>
			<cfquery name="die" datasource="uam_god">
				delete from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
			</cfquery>
		</cfif>
		<cflocation url="catRecordSearchProfile.cfm?" addtoken="false">
	</cfoutput>
</cfif>
<!----------
<cfif action is "adopt">
	<cfoutput>
		<cfquery name="cf_cat_rec_srch_profile" datasource="cf_codetables">
			select 
				profile_name,
	    		creator,
	    		description,
	    		search_fields,
	    		results_columns
	    	from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
		</cfquery>
		<cfquery name="up" datasource="cf_dbuser">
			UPDATE cf_users SET
				catrec_rslt_cols=<cfqueryparam value="#cf_cat_rec_srch_profile.results_columns#" CFSQLType="cf_sql_varchar">,
				catrec_srch_cols=<cfqueryparam value="#cf_cat_rec_srch_profile.search_fields#" CFSQLType="cf_sql_varchar">
			WHERE
				username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfset session.catrec_srch_cols=cf_cat_rec_srch_profile.search_fields>
		<cfset session.catrec_rslt_cols=cf_cat_rec_srch_profile.results_columns>
		<script>
			parent.$("##sp").val('#pn#');
			parent.reloadAtURL();
			//parent.location='/search.cfm?sp=#encodeForHTML(pn)#';
		</script>
	</cfoutput>
</cfif>
------------>