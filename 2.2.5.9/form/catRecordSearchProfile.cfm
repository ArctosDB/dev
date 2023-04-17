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
		});
		function sveanduse(){	
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
				alert('Select a profile to load data.')
				return false;
			}
			document.location='catRecordSearchProfile.cfm?pn=' + encodeURIComponent(spn);
		}
		function deleterchProfile(pn){
			if(confirm('Are you sure you want to delete this Profile? This cannot be undone.')){
				window.location='catRecordSearchProfile.cfm?action=delete&pn=' + encodeURIComponent(pn);
			}
		}
		function adoptProfile (){
			var spn=$("#spn").val();
			if (spn.length<1){
				alert('Select a profile to load data.')
				return false;
			}
			window.location='catRecordSearchProfile.cfm?action=adopt&pn=' + encodeURIComponent(spn);
		}
	</script>
	<style>
		#twocolsholder{
			display: grid;
			grid-template-columns: 1fr 1fr 1fr;
		}
		.onecolthingee{
			margin: 1em;
			padding: 1em;
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
		#rcolsdv {
			max-height: 90vh;
			overflow: auto;
		}
	</style>
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfif isdefined("pn") and len(pn) gt 0>
			<cfquery name="cf_cat_rec_srch_profile" datasource="cf_codetables">
				select 
					profile_name,
		    		creator,
		    		description,
		    		search_fields,
		    		results_columns
		    	from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
			</cfquery>
			<cfset crsc=cf_cat_rec_srch_profile.search_fields>
			<cfset crrc=cf_cat_rec_srch_profile.results_columns>
		<cfelse>
			<cfset crsc=session.catrec_srch_cols>
			<cfset crrc=session.catrec_rslt_cols>
			<cfset pn="">
		</cfif>
		<cfquery name="cf_cat_rec_srch_profile_exist" datasource="cf_codetables">
			select 
				profile_name,
	    		creator,
	    		description,
	    		search_fields,
	    		results_columns,
	    		case when creator=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#"> then 1 else 99 end as creatorsort
	    	from cf_cat_rec_srch_profile 
	    	order by creatorsort,creator,profile_name
		</cfquery>

		<form name="build_profile" id="build_profile" method="post" action="catRecordSearchProfile.cfm">
			<input type="hidden" name="action" value="buildsave">
			<input type="hidden" name="srchtrms" id="srchtrms">
			<input type="hidden" name="rslttrms" id="rslttrms">
		
			<cfquery name="cf_cat_rec_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select display,obj_name,default_order,category,subcategory,description from cf_cat_rec_srch_cols order by default_order
			</cfquery>
			
			<div id="twocolsholder">
				<div id="metadiv" class="onecolthingee">
					<h3>Search Options and Profiles</h3>
						Choose and organize search and results fields to the right. Mouseover Fields for more information.
					<hr>
					<label for="profile_name">"Seed" profile: Start with an existing Profile</label>
					<select name="spn" id="spn" onchange="lsp();">
						<option value="">select a profile to view/seed</option>
						<cfloop query="cf_cat_rec_srch_profile_exist">
							<option <cfif pn is profile_name> selected="selected" </cfif> value="#profile_name#">[#creator#]: #profile_name#</option>
						</cfloop>
					</select>
					<!----
					<input type="button" class="lnkBtn" value="Load Selected Profile" onclick="lsp();">
					---->
					<cfif isdefined("cf_cat_rec_srch_profile") and cf_cat_rec_srch_profile.recordcount gt 0>
						<p>
							Viewing <strong>#cf_cat_rec_srch_profile.profile_name#</strong> created by <strong>#cf_cat_rec_srch_profile.creator#</strong>
							<br>Description: #cf_cat_rec_srch_profile.description#
							<cfif cf_cat_rec_srch_profile.creator is session.username>
								<br><input type="button" value="DELETE" onclick="deleterchProfile('#cf_cat_rec_srch_profile.profile_name#');" class="delBtn">
							</cfif>
						</p>
					</cfif>
					<h4>Option One: Use an existing Profile</h4>
					<input type="button" value="Adopt" class="insBtn" onclick="adoptProfile();"> the above Profile without modification.

					<hr>
					<h4>Option Two: Customize Only</h4>
					You may start by choosing a Profile (above) which can be modified, or simply choose what to see in search and results (to the right), then 
					<input type="button" value="Save and Use" class="savBtn" onclick="sveanduse();">. This option is saved in your settings but cannot be shared.

					<hr>
					<h4>Option Three: Create a Profile</h4>
					You may start by choosing a Profile (above) which can be modified, or simply choose what to see in search and results (to the right), then provide a new (and unique) Profile Name and click Create and Use to create and use a reusable and sharable Profile.
					<label for="profile_name">Profile Name: Must be unique.</label>
					<input type="text" name="profile_name" size="40" placeholder="profile_name" class="reqdClr">
					<label for="creator">Creator</label>
					<input type="text" name="creator" size="40" placeholder="creator" value="#session.username#">
					<label for="description">Description (optional)</label>
					<input type="text" name="description" size="40" placeholder="description">
					<br><input type="button" value="Create and Use" class="insBtn" onclick="sveanduse();">
				</div>
				<div id="srchdiv" class="onecolthingee">
					Select Search Options. 	
					<table border class="sortable" id="stbl">
						<tr>
							<th>Field</th>
							<th>Show</th>
							<th>Category</th>
							<th>SubCategory</th>
						</tr>
						<cfloop query="cf_cat_rec_srch_cols">
							<tr data-category="#category#" data-subcategory="#category#_#subcategory#">
								<td>
									<div title="#description#">#display#</div></td>
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
											<i class="fa-solid fa-check"></i>
										</span>
										<span class="likeLink" onclick="checkuncheck('sc','false','#category#');">
											<i class="fa-solid fa-remove"></i>
										</span>
									</div>
								</td>
								<td>
									<div class="nowrap">
										#subcategory#
										<span class="likeLink" onclick="checkuncheck('sc','true','#category#_#subcategory#');">
											<i class="fa-solid fa-check"></i>
										</span>
										<span class="likeLink" onclick="checkuncheck('sc','false','#category#_#subcategory#');">
											<i class="fa-solid fa-remove"></i>
										</span>
									</div>
								</td>
								<td></td>
							</tr>
						</cfloop>
					</table>
				</div>
				<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
					select obj_name,display,category,description,default_order,query_cost from cf_cat_rec_rslt_cols order by default_order
				</cfquery>
				<cfquery name="profileselected" dbtype="query">
					select * from cf_cat_rec_rslt_cols where obj_name in (<cfqueryparam value="#crrc#" cfsqltype="cf_sql_varchar" list="true">)
				</cfquery>
				<cfquery name="profileunselected" dbtype="query">
					select * from cf_cat_rec_rslt_cols where obj_name not in (<cfqueryparam value="#crrc#" cfsqltype="cf_sql_varchar" list="true">) order by default_order
				</cfquery>

				<div id="rcolsdv" class="onecolthingee">
					Select Results Options. Drag to order.
					<table border class="sortable" id="stbl">
						<tr>
							<th>Order</th>
							<th>Show</th>
							<th>Field</th>
							<th>Category</th>
						</tr>
						<tbody id="sortable">
							<cfloop list="#crrc#" index="objname">
								<cfquery name="ton" dbtype="query">
									select * from profileselected where obj_name=<cfqueryparam value="#objname#" cfsqltype="cf_sql_varchar">
								</cfquery>
								<cfif ton.recordcount is 1>
									<tr>
										<td class="rowsorter">
											<i class="fas fa-grip-vertical"></i>
										</td>
										<td>
											<input data-category='#ton.category#' type="checkbox" name="rc_#ton.obj_name#" checked >
										</td>
										<td>
											<div title="#replace(ton.description,'"',"'","all")#">
												#ton.display#
											</div>
										</td>
										<td>
											<div class="nowrap">
												#ton.category#
												<span class="likeLink" onclick="checkuncheck('rc','true','#ton.category#');">
													<i class="fa-solid fa-check"></i>
												</span>
												<span class="likeLink" onclick="checkuncheck('rc','false','#ton.category#');">
													<i class="fa-solid fa-remove"></i>
												</span>
											</div>
										</td>
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
										<div title="#replace(description,'"',"'","all")#">
											#display#
										</div>
									</td>
									<td>
										<div class="nowrap">
											#category#
											<span class="likeLink" onclick="checkuncheck('rc','true','#category#');">
												<i class="fa-solid fa-check"></i>
											</span>
											<span class="likeLink" onclick="checkuncheck('rc','false','#category#');">
												<i class="fa-solid fa-remove"></i>
											</span>
										</div>
									</td>
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
		<cfif len(profile_name) is 0>
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
		<cfelse>
			<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
				select count(*) c from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#profile_name#">
			</cfquery>
			<cfif cf_cat_rec_rslt_cols.c gt 0>
				profile_name is not available; use your back button.<cfabort>
			</cfif>			
			<cfquery name="mkcf_cat_rec_rslt_cols" datasource="uam_god">
				insert into cf_cat_rec_srch_profile (
				    profile_name,
				    creator,
				    description,
				    search_fields,
				    results_columns
				) values (
				    <cfqueryparam cfsqltype="cf_sql_varchar" value="#profile_name#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#creator#" null="#Not Len(Trim(creator))#">,
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
				parent.$("##sp").val('#pn#');
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
	    		creator
	    	from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
		</cfquery>
		<cfif cf_cat_rec_srch_profile.creator is session.username>
			<cfquery name="die" datasource="uam_god">
				delete from cf_cat_rec_srch_profile where profile_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#pn#">
			</cfquery>
		</cfif>
		<cflocation url="catRecordSearchProfile.cfm" addtoken="false">
	</cfoutput>
</cfif>
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