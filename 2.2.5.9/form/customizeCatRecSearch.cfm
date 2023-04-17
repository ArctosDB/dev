<cfinclude template="/includes/_includeHeader.cfm">
<cfif len(session.username) lt 1>
	<div class="importantNotification">
		Sign in to save customizations.
	</div>
</cfif>
<script src="/includes/sorttable.js"></script>
<div>
	Choose searchable fields by checking boxes below then clicking Save. Table columns are sortable by clicking on the column name.  Use the Scrollable dropdown menus to quickly find specific fields in a Category or SubCategory (these will be highlighted in green). Check None then Save Settings to reset. Save your customizations by signing in.
</div>
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
	    let searchParams = new URLSearchParams(window.location.search);
	    let cat = searchParams.get('cat');
	    if (cat.length > 0){
	    	goToSection(cat);	 
	    } 
	    let opn = searchParams.get('opn');
	    if (opn.length > 0 && cat.length > 0){
	    	if (opn=='forceall'){
	    		// check everything in a category
	    		cabc(cat);
	    		// save and bye
	    		saveSearchSettings();
	    	} else if (opn=='forcebasic'){
	    		// uncheck everything in the category
	    		cnbc(cat);
	    		// now check category_basic
	    		cabsc(cat + '_basic');
	    		// now bounce
	    		saveSearchSettings();
	    	}
	    }
	});
	function goToSection(cat){
		$(".highlight_category").removeClass("highlight_category");
		$("[data-category='" + cat + "']").addClass('highlight_category');
		$('html, body').animate({
		    scrollTop: $('.highlight_category:visible:first').offset().top
		}, 1000);
		$("#scrollto").val('');
	}
	function goToSSection(cat){
		$(".highlight_category").removeClass("highlight_category");
		$("[data-subcategory='" + cat + "']").addClass('highlight_category');
		$('html, body').animate({
		    scrollTop: $('.highlight_category:visible:first').offset().top
		}, 1000);
		$("#scrollto").val('');
	}
	function checkAll(){
		$('input:checkbox').prop('checked', true);
	}
	function checkNone(){
		$('input:checkbox').prop('checked', false);
	}
	function saveSearchSettings() {
		var chkd = [];
		$('input[type=checkbox]').each(function() {
   			if ($(this).is(":checked")) {
       			chkd.push($(this).attr('name'));
   			}
		});
		var chkd_l=chkd.join(',');
		$.ajax({
	      url: "/component/functions.cfc",
	      type: "get",
	      dataType: "json",
	      data: {
	        method: "changeUserPreference",
	        returnformat: "json",
	        pref: 'catrec_srch_cols',
	        val: chkd_l
	      },
	      success: function(r) {
	        //nada
	        //alert('happysave');
	      	//parent.$("#tbl").val('');
	      	//parent.location.href=parent.location.href.split("?")[0];

	      	//parent.location.reload();
	      	parent.reloadAtURL();
	      },
	      error: function (xhr, textStatus, errorThrown){
	          alert(errorThrown + ': ' + textStatus + ': ' + xhr);
	      }
	    });
	}
	function cabc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("category") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
	}
	function cabsc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("subcategory") == v) {      
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
	function cnbsc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("subcategory") == v) {      
				$(this).prop('checked', false).trigger('change');                                        
			} 
		}); 
	}

</script>

<cfquery name="cf_cat_rec_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select display,obj_name,default_order,category,subcategory,description from cf_cat_rec_srch_cols order by default_order
</cfquery>
<cfquery name="dcat" dbtype="query">
	select category from cf_cat_rec_srch_cols where category is not null group by category order by category
</cfquery>
<cfquery name="dscat" dbtype="query">
	select 
		category||'_'||subcategory scat,
		category||': '||subcategory dscat
		 from cf_cat_rec_srch_cols where category is not null and subcategory is not null 
		 group by category,subcategory order by category,subcategory
</cfquery>
<cfparam name="session.catrec_srch_cols" default="#valuelist(cf_cat_rec_srch_cols.obj_name)#">
<cfif len(session.catrec_srch_cols) is 0>
	<cfset session.catrec_srch_cols=valuelist(cf_cat_rec_srch_cols.obj_name)>
</cfif>
<cfoutput>
	<select name="scrollto" id="scrollto" onChange="goToSection(this.value)">
		<option value="">[ Scroll To Category ]</option>
		<cfloop query="dcat">
			<option value="#category#">#category#</option>
		</cfloop>
	</select>
	<select name="scrolltoSC" id="scrolltoSC" onChange="goToSSection(this.value)">
		<option value="">[ Scroll To SubCategory ]</option>
		<cfloop query="dscat">
			<option value="#scat#">#dscat#</option>
		</cfloop>
	</select>
	<input type="button" class="lnkBtn" value="Check All" id="checkAll" onclick="checkAll()">
	<input type="button" class="delBtn" value="Check None" id="checkNone" onclick="checkNone()">
	<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">

	<table border class="sortable" id="stbl">
		<tr>
			<th>Show</th>
			<th>Field</th>
			<th>Category</th>
			<th>SubCategory</th>
			<th>Description</th>
		</tr>
		<cfloop query="cf_cat_rec_srch_cols">
			<tr data-category="#category#" data-subcategory="#category#_#subcategory#">
				<td>
					<input 
						data-category='#category#' 
						data-subcategory="#category#_#subcategory#" 
						type="checkbox" 
						name="#obj_name#" <cfif listfind(session.catrec_srch_cols,obj_name)> checked </cfif> >
				</td>
				<td>#display#</td>
				<td>
					<div class="nowrap">
						#category#
						<input type="button" class="lnkBtn" value="All" onclick="cabc('#category#');">
						<input type="button" class="delBtn" value="None" onclick="cnbc('#category#');">
						<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
					</div>
				</td>
				<td>
					<div class="nowrap">
						#subcategory#
						<input type="button" class="lnkBtn" value="All" onclick="cabsc('#category#_#subcategory#');">
						<input type="button" class="delBtn" value="None" onclick="cnbsc('#category#_#subcategory#');">
					<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
					</div>
				</td>
				<td>#description#</td>
			</tr>
		</cfloop>
	</table>
	<input type="button" class="savBtn" value="Save" onclick="saveSearchSettings();">
</cfoutput>