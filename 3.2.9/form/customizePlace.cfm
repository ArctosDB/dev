<cfinclude template="/includes/_includeHeader.cfm">
<cfif len(session.username) lt 1>
	This form is only available to registered users.<cfabort>
</cfif>
<cfif action is "nothing">
	<script>
		function checkAllNone(){
			if ($("#checkAllNone").is(":checked")){
				$('input:checkbox').prop('checked', true);
			} else {
				$('input:checkbox').prop('checked', false);
			}
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
			$("#customizeplace").submit();
		}
	</script>
	<style>
		#outercontainer{
			display: grid;
			grid-template-columns: 1fr 1fr;
			width: fit-content; 
		}
		#schtrms{
			border: 1px solid black;
			max-height: 80vh;
			overflow: auto;
			padding:0 1em 1em 0;
			margin:0 1em 1em 0;
			background-color: var(--arctoslightblue);
		}
		#rsltstrms{
			border: 1px solid black;
			max-height: 80vh;
			overflow: auto;
			padding:0 1em 1em 0;
			margin:0 1em 1em 0;
			background-color: var(--arctoslightblue);
		}
		.rowsorter {
			text-align: center;
			font-size: large;
		}
		.rowsorter:hover {
			cursor: move;
		}
	</style>
	<cfoutput>
		<cfquery name="cf_temp_loc_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select display,sql_alias,default_order,category,description,search_term,results_term from cf_temp_loc_srch_cols 
		</cfquery>
		<cfif sch is "geog">
			<cfset srchDispl="geography">
			<cfset thisColCat="geography">
			<cfset sessionSrchVarName="geog_srch_cols">
			<cfset sessionRsltVarName="geog_rslt_cols">
			<cfparam name="session.geog_srch_cols" default="">
			<cfparam name="session.geog_rslt_cols" default="">
		<cfelseif sch is "locality">
			<cfset srchDispl="locality">
			<cfset thisColCat="geography,locality">
			<cfset sessionSrchVarName="loc_srch_cols">
			<cfset sessionRsltVarName="loc_rslt_cols">
			<cfparam name="session.loc_srch_cols" default="">
			<cfparam name="session.loc_rslt_cols" default="">
		<cfelseif sch is "collecting_event">
			<cfset srchDispl="Events">
			<cfset thisColCat="geography,locality,collecting_event">
			<cfset sessionRsltVarName="evnt_rslt_cols">
			<cfset sessionSrchVarName="evnt_srch_cols">
			<cfparam name="session.evnt_srch_cols" default="">
			<cfparam name="session.evnt_rslt_cols" default="">
		<cfelse>
			nope<cfabort>
		</cfif>
		<cfquery name="srch_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where 
			search_term=1 and
			category in (<cfqueryparam value="#thisColCat#" list="true" cfsqltype="cf_sql_varchar">)
			order by default_order
		</cfquery>
		<cfquery name="rslt_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where 
			results_term=1 and
			category in (<cfqueryparam value="#thisColCat#" list="true" cfsqltype="cf_sql_varchar">)
			order by default_order
		</cfquery>
		<cfif len(session[#sessionSrchVarName#]) is 0>
			<cfset session[#sessionSrchVarName#]=valuelist(srch_cols.sql_alias)>
		</cfif>
		<cfif len(session[#sessionRsltVarName#]) is 0>
			<cfset session[#sessionRsltVarName#]=valuelist(srch_cols.rslt_cols)>
		</cfif>
		<cfset selected_srch_cols=session[#sessionSrchVarName#]>
		<cfset selected_rslts_cols=session[#sessionRsltVarName#]>
		<cfset colmatchck=true>
		<cfloop list="#selected_srch_cols#" index="ix">
			<cfif not listfind(valuelist(srch_cols.sql_alias),ix)>
				<cfset colmatchck=false>
			</cfif>
		</cfloop>
		<cfif colmatchck is false>
			<div>Invalid data found: resetting search preferences......</div>
			<cfset session[#sessionSrchVarName#]=valuelist(srch_cols.sql_alias)>
			<div>... success.</div>
		</cfif>
		<cfset colmatchck=true>
		<cfloop list="#selected_rslts_cols#" index="ix">
			<cfif not listfind(valuelist(rslt_cols.sql_alias),ix)>
				<cfset colmatchck=false>
			</cfif>
		</cfloop>
		<cfif colmatchck is false>
			<div>Invalid data found: resetting results preferences......</div>
			<cfset session[#sessionRsltVarName#]=valuelist(rslt_cols.sql_alias)>
			<div>... success.</div>
		</cfif>
		<form name="customizeplace" id="customizeplace" method="post" action="customizePlace.cfm">
			<input type="hidden" name="action" value="save">
			<input type="hidden" name="srchtrms" id="srchtrms">
			<input type="hidden" name="rslttrms" id="rslttrms">
			<input type="hidden" name="sessionSrchVarName" id="sessionSrchVarName" value="#sessionSrchVarName#">
			<input type="hidden" name="sessionRsltVarName" id="sessionRsltVarName" value="#sessionRsltVarName#">
			<input type="button" value="Save Preferences" class="savBtn" onclick="sveanduse();">
			<div id="outercontainer">
				<div id="schtrms">
					<div class="sectionlabel">
						Search Terms
					</div>
					<div class="sectiontable">
						<table border>
							<thead>
								<tr>
									<th>Field</th>
									<th>⍻</th>

								</tr>
							</thead>
							<tbody id="srchfldtb">
								<cfloop query="srch_cols">
									<tr>
										<td>
											<div class="objNameDiv">
												#display#
												<span id="info_st_#sql_alias#_show" class="likeLink" onclick="toggleInfo('info_st_#sql_alias#');">
													<i class="fa-solid fa-eye" title="Define"></i>
												</span>
												<span id="info_st_#sql_alias#_hide" class="likeLink noshow" onclick="toggleInfo('info_st_#sql_alias#');">
													<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
												</span>
											</div>
											<div class="noshow toggleDisplayBits" id="info_st_#sql_alias#">#encodeForHTML(description)#</div>
										</td>
										<td>
											<input type="checkbox" <cfif listfindnocase(selected_srch_cols,sql_alias)> checked </cfif> name="sc_#sql_alias#">
										</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				</div>
				<div id="rsltstrms">
					<div class="sectionlabel">
						Result Terms
					</div>
					<div class="sectiontable">
						<table border class="sortable" id="srotbl">
							<thead>
								<tr>
									<th>Sort</th>
									<th>Field</th>
									<th>⍻</th>

								</tr>
							</thead>
							<tbody id="sortable">
								<!---- first our selected list ---->
								<cfloop list="#selected_rslts_cols#" index="item">
									<cfquery name="trq" dbtype="query">
										select display,description,sql_alias from rslt_cols where sql_alias=<cfqueryparam value="#item#" cfsqltype="cf_sql_varchar">
									</cfquery>
									<cfif trq.recordcount is 1 and len(trq.sql_alias) gt 0>
										<tr>
											<td class="rowsorter">
													<i class="fas fa-grip-vertical" title="Drag to order"></i>
												</td>
											<td>
												<div class="objNameDiv">
													#trq.display#
													<span id="info_rt_#trq.sql_alias#_show" class="likeLink" onclick="toggleInfo('info_rt_#trq.sql_alias#');">
														<i class="fa-solid fa-eye" title="Define"></i>
													</span>
													<span id="info_rt_#trq.sql_alias#_hide" class="likeLink noshow" onclick="toggleInfo('info_rt_#trq.sql_alias#');">
														<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
													</span>
												</div>
												<div class="noshow toggleDisplayBits" id="info_rt_#trq.sql_alias#">#encodeForHTML(trq.description)#</div>
											</td>
											<td>
												<input type="checkbox" checked name="rc_#trq.sql_alias#">
											</td>
										</tr>
									</cfif>
								</cfloop>
								<!---- now whatever's left ---->
								<cfquery name="theRest" dbtype="query">
									select display,description,sql_alias from rslt_cols where sql_alias not in ( 
										<cfqueryparam value="#selected_rslts_cols#" cfsqltype="cf_sql_varchar" list="true"> 
									)
								</cfquery>
								<cfloop query="theRest">
									<tr>
										<td class="rowsorter">
													<i class="fas fa-grip-vertical" title="Drag to order"></i>
												</td>
										<td>
											<div class="objNameDiv">
												#display#
												<span id="info_rt_#sql_alias#_show" class="likeLink" onclick="toggleInfo('info_rt_#sql_alias#');">
													<i class="fa-solid fa-eye" title="Define"></i>
												</span>
												<span id="info_rt_#sql_alias#_hide" class="likeLink noshow" onclick="toggleInfo('info_rt_#sql_alias#');">
													<i class="fa-solid fa-eye-slash" title="Hide Definition"></i>
												</span>
											</div>
											<div class="noshow toggleDisplayBits" id="info_rt_#sql_alias#">#encodeForHTML(description)#</div>
										</td>
										<td>
											<input type="checkbox" name="rc_#sql_alias#">
										</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				</div>
			</div>
		</form>
	</cfoutput>
</cfif>
<cfif action is "save">
	<cfoutput>
		<cfquery name="ups" datasource="cf_dbuser">
			UPDATE cf_users SET
			#sessionSrchVarName#=<cfqueryparam value="#srchtrms#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(srchtrms))#"> WHERE
			username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfquery name="upr" datasource="cf_dbuser">
			UPDATE cf_users SET
			#sessionRsltVarName#=<cfqueryparam value="#rslttrms#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(rslttrms))#"> WHERE
			username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfset session[#sessionSrchVarName#]=srchtrms>
		<cfset session[#sessionRsltVarName#]=rslttrms>
	</cfoutput>
	<script>
		parent.location.reload();
	</script>
</cfif>