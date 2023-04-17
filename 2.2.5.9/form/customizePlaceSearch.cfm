<cfinclude template="/includes/_includeHeader.cfm">
<script>
	$(function() {
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
	function checkAllNone(){
		if ($("#checkAllNone").is(":checked")){
			$('input:checkbox').prop('checked', true);
		} else {
			$('input:checkbox').prop('checked', false);
		}
	}
	function saveSearchSettings() {
		//var linkOrderData=$("#sortable").sortable('toArray').join(',');
		var chkd = [];
		$('input[type=checkbox]').each(function() {
   			if ($(this).is(":checked")) {
       			chkd.push($(this).attr('name'));
   			}
		});
		var chkd_l=chkd.join(',');
		//console.log(chkd_l);
		var typ=$("#typ").val();
		//console.log(typ);
		if (typ=='evt'){
			var sptyp='evnt_srch_cols';
		} else if (typ=='loc'){
			var sptyp='loc_srch_cols';
		} else {

			var sptyp='geog_srch_cols';
		}
		//console.log(sptyp);
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
	        //nada
	        //alert('happysave');
	      	parent.location.reload();
	      },
	      error: function (xhr, textStatus, errorThrown){
	          alert(errorThrown + ': ' + textStatus + ': ' + xhr);
	      }
	    });
	}
</script>
 
<cfquery name="cf_temp_loc_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select display,sql_alias,default_order,category,description from cf_temp_loc_srch_cols where search_term=1 order by default_order
</cfquery>
<cfoutput>
	<cfparam name="typ" default="geog">
	<input type="hidden" name="typ" id="typ" value="#typ#">
	<cfif typ is "evt">
		<cfquery name="available_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality','collecting_event') order by default_order
		</cfquery>
		<cfparam name="session.evnt_srch_cols" default="#valuelist(available_cols.sql_alias)#">
		<cfset savedList=session.evnt_srch_cols>
	<cfelseif typ is "loc">
		<cfquery name="available_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality') order by default_order
		</cfquery>
		<cfparam name="session.loc_srch_cols" default="#valuelist(available_cols.sql_alias)#">
		<cfset savedList=session.loc_srch_cols>
	<cfelse>
		<cfquery name="available_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography') order by default_order
		</cfquery>
		<cfparam name="session.geog_srch_cols" default="#valuelist(available_cols.sql_alias)#">
		<cfset savedList=session.geog_srch_cols>
	</cfif>
	<input type="button" class="savBtn" value="Save Settings" onclick="saveSearchSettings();">
	<table border>
		<tr>
			<th>Show<input type="checkbox" id="checkAllNone" onchange="checkAllNone();"></th>
			<th>Field</th>
			<th>Category</th>
			<th>Description</th>
		</tr>
		<cfloop query="available_cols">
			<tr>
				<td><input type="checkbox" name="#sql_alias#" <cfif listfind(savedList,sql_alias)> checked </cfif> ></td>
				<td>#display#</td>
				<td>#category#</td>
				<td>#description#</td>
			</tr>
		</cfloop>
	</table>
	<input type="button" class="savBtn" value="Save Settings" onclick="saveSearchSettings();">
</cfoutput>