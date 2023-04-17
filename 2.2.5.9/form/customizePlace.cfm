<cfinclude template="/includes/_includeHeader.cfm">
<cfif len(session.username) lt 1>
	This form is only available to registered users.<cfabort>
</cfif>
<cfif not isdefined("sch") or len(sch) is 0>
	Nope<cfabort>
</cfif>
<cfif sch is not 'geog' and sch is not "locality" and sch is not 'collecting_event'>
	Nope<cfabort>
</cfif>
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
			handle: '.dragger'
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
	function saveSearchSettings(sptyp) {
		//var linkOrderData=$("#sortable").sortable('toArray').join(',');
		var chkd = [];
		$('input[type=checkbox]').each(function() {
   			if ($(this).is(":checked")) {
       			chkd.push($(this).attr('name'));
   			}
		});
		var chkd_l=chkd.join(',');
		console.log(chkd_l);
		$.ajax({
	      url: "/component/functions.cfc",
	      type: "get",
	      dataType: "json",
	      data: {
	        method: "changeUserPreference",
	        returnformat: "json",
	        pref: sptyp,
	        val: chkd_l
	      },
	      success: function(r) {
	      	parent.location.reload();
	      },
	      error: function (xhr, textStatus, errorThrown){
	          alert(errorThrown + ': ' + textStatus + ': ' + xhr);
	      }
	    });
	}
</script>
<style>
	.dragger {
		cursor:move;
		border:5px solid gray;
		text-align:center;
	}
</style>
<cfoutput>
	<h3>Customize Place Search Results</h3>
	<p>Check none to reset, or check all to order all possible values.</p>
	<cfif listfindnocase(session.roles,'coldfusion_user')>
		<br>IMPORTANT: This form is used in multiple ways, including picks. You can break Arctos (just for you!) by turning "required" fields off.
	</cfif>
	<cfquery name="cf_temp_loc_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select display,sql_alias,default_order,category,description from cf_temp_loc_srch_cols where results_term=1 order by default_order
	</cfquery>
	<cfif sch is "geog">
		<cfset srchDispl="geography">
		<cfset thisColCat="geography">
		<cfset sessionVarName="geog_rslt_cols">
		<cfparam name="session.geog_rslt_cols" default="">
	<cfelseif sch is "locality">
		<cfset srchDispl="locality">
		<cfset thisColCat="geography,locality">
		<cfset sessionVarName="loc_rslt_cols">
		<cfparam name="session.geog_rslt_cols" default="">
		<cfparam name="session.loc_rslt_cols" default="">
	<cfelseif sch is "collecting_event">
		<cfset srchDispl="Events">
		<cfset thisColCat="geography,locality,collecting_event">
		<cfset sessionVarName="evnt_rslt_cols">
		<cfparam name="session.geog_rslt_cols" default="">
		<cfparam name="session.loc_rslt_cols" default="">
		<cfparam name="session.evnt_rslt_cols" default="">
	<cfelse>
		nope<cfabort>
	</cfif>
	<p>Choose which columns will be visible the next time you search #srchDispl#.</p>
	<cfquery name="default_cols_qry" dbtype="query">
		select * from cf_temp_loc_srch_cols where 
		category in (<cfqueryparam value="#thisColCat#" list="true" cfsqltype="cf_sql_varchar">)
		order by default_order
	</cfquery>
	<cfset default_cols_list=valuelist(default_cols_qry.sql_alias)>
	<cfset svarloc=session[#sessionVarName#]>
	<cfif len(svarloc) is 0>
		<cfset session[#sessionVarName#]=default_cols_list>
	</cfif>
	<cfset colmatchck=true>
	<cfloop list="#svarloc#" index="ix">
		<cfif not listfind(default_cols_list,ix)>
			<cfset colmatchck=false>
		</cfif>
	</cfloop>
	<cfif colmatchck is false>
		<div>Invalid data found: resetting search preferences......success</div>
		<cfset session[#sessionVarName#]=default_cols_list>
		<cfset svarloc=default_cols_list>
	</cfif>
	<!--- should have valid columns at this point ---->
	<input type="button" class="savBtn" value="Save Settings" onclick="saveSearchSettings('#sessionVarName#');">
	<cfquery name="is_not_checked" dbtype="query">
		select sql_alias,display,default_order,category,description from cf_temp_loc_srch_cols where 
		category in (<cfqueryparam value="#thisColCat#" list="true" cfsqltype="cf_sql_varchar">) and 
		sql_alias not in ( <cfqueryparam value="#svarloc#" list="true"> ) order by default_order
	</cfquery>
	<table border>
		<thead>
			<tr>
				<th>Order</th>
				<th>Show<input type="checkbox" id="checkAllNone" onchange="checkAllNone();"></th>
				<th>Field</th>
				<th>Category</th>
				<th>Description</th>
			</tr>
		</thead>
		<tbody id="sortable">
			<cfloop list="#svarloc#" index="ix">
				<cfquery name="getThisOne" dbtype="query">
					select display,category,description from cf_temp_loc_srch_cols where sql_alias=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<tr id="#ix#">
					<td class="dragger">drag me</td>
					<td><input type="checkbox" name="#ix#" checked></td>
					<td>#getThisOne.display#</td>
					<td>#getThisOne.category#</td>
					<td>#getThisOne.description#</td>
				</tr>					
			</cfloop>
			<cfloop query="is_not_checked">
				<tr id="#sql_alias#">
					<td class="dragger">drag me</td>
					<td><input type="checkbox" name="#sql_alias#"></td>
					<td>#display#</td>
					<td>#category#</td>
					<td>#description#</td>
				</tr>					
			</cfloop>
		</tbody>
	</table>
	<input type="button" class="savBtn" value="Save Settings" onclick="saveSearchSettings('#sessionVarName#');">
</cfoutput>