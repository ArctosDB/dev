<cfinclude template="/includes/_includeHeader.cfm">
<cfif len(session.username) lt 1>
	<div class="importantNotification">
		Sign in to save customizations.
	</div>
</cfif>
<script src="/includes/sorttable.js"></script>
<script>
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
	function checkAll(){
		$('input:checkbox').prop('checked', true);
	}
	function checkNone(){
		$('input:checkbox').prop('checked', false);
	}
	function cabc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("category") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
	}
	function cnbc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("category") == v) {      
				$(this).prop('checked', false).trigger('change');                                        
			} 
		}); 
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
		//console.log(sptyp);
		$.ajax({
	      url: "/component/functions.cfc",
	      type: "get",
	      dataType: "json",
	      data: {
	        method: "changeUserPreference",
	        returnformat: "json",
	        pref: 'catrec_rslt_cols',
	        val: chkd_l
	      },
	      success: function(r) {
	        //nada
	        //alert('happysave');
	      	//parent.$("#tbl").val('');
	      	//parent.location.reload();
	      	
	      	parent.reloadAtURL();
	      },
	      error: function (xhr, textStatus, errorThrown){
	          alert(errorThrown + ': ' + textStatus + ': ' + xhr);
	      }
	    });
	}
</script>
<div>
	Choose what to see as results. Order results columns by dragging. NOTE: "Cost" of columns determines how many results queries may return. 
</div>

<!----cachedwithin="#createtimespan(0,0,60,0)#"---->
 
<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" >
	select obj_name,display,category,description,default_order,query_cost from cf_cat_rec_rslt_cols
</cfquery>
<cfquery name="rqd_cls" dbtype="query">
	select obj_name from cf_cat_rec_rslt_cols where category='core' order by default_order
</cfquery>
<cfparam name="session.catrec_rslt_cols" default="#valuelist(rqd_cls.obj_name)#">
<cfif len(session.catrec_rslt_cols) is 0>
	<cfset session.catrec_rslt_cols=valuelist(rqd_cls.obj_name)>
</cfif>

<cfoutput>
	<cfquery name="not_already_selected" dbtype="query">
		select display,obj_name,description,category,default_order,query_cost
		from cf_cat_rec_rslt_cols 
		where obj_name not in (<cfqueryparam value="#session.catrec_rslt_cols#" cfsqltype="cf_sql_varchar" list="true"> )
		order by default_order
	</cfquery>
	<input type="button" class="lnkBtn" value="Check All" id="checkAll" onclick="checkAll()">
	<input type="button" class="delBtn" value="Check None" id="checkNone" onclick="checkNone()">
	<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
	<table border class="sortable" id="stbl">
		<tr>
			<th>Show</th>
			<th>Order</th>
			<th>Field</th>
			<th>Category</th>
			<th>Description</th>
			<th>Cost</th>
			<th>DefaultOrder</th>
		</tr>
		<tbody id="sortable">
			<cfloop list="#session.catrec_rslt_cols#" index="ix">
				<cfquery name="getThisOne" dbtype="query">
					select display,obj_name,description,category,query_cost,default_order from cf_cat_rec_rslt_cols where obj_name=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif getThisOne.recordcount is 1>
					<tr>
						<td class="dragger">drag</td>
						<td><input data-category='#getThisOne.category#' type="checkbox" name="#getThisOne.obj_name#" checked ></td>
						<td>#getThisOne.display#</td>
						<td>
							<div class="nowrap">
								#getThisOne.category#
								<input type="button" class="lnkBtn" value="All" onclick="cabc('#getThisOne.category#');">
								<input type="button" class="delBtn" value="None" onclick="cnbc('#getThisOne.category#');">
								<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
							</div>
						</td>
						<td>#getThisOne.description#</td>
						<td>#getThisOne.query_cost#</td>
						<td>#getThisOne.default_order#</td>
					</tr>
				</cfif>
			</cfloop>
			<cfloop query="not_already_selected">
				<tr>
					<td class="dragger">drag</td>
					<td><input data-category='#category#' type="checkbox" name="#obj_name#"></td>
					<td>#display#</td>
					<td>
						<div class="nowrap">
							#category#
							<input type="button" class="lnkBtn" value="All" onclick="cabc('#category#');">
							<input type="button" class="delBtn" value="None" onclick="cnbc('#category#');">
							<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
						</div>
					</td>
					<td>#description#</td>
					<td>#query_cost#</td>
					<td>#default_order#</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
	<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
</cfoutput>