<cfinclude template="/includes/_includeHeader.cfm">
<script src="/includes/sorttable.js"></script>
<cfparam name="gps" default="">
<script>
	function useSeld() {
		var chkd = [];
		$('input[type=checkbox]').each(function() {
   			if ($(this).is(":checked")) {
       			chkd.push($(this).attr('name'));
   			}
		});
		var chkd_l=chkd.join(',');
		parent.$("#guid_prefix").val(chkd_l);

   		parent.$(".ui-dialog-titlebar-close").trigger('click');
	}
	function checkAllNone(){
		if ($("#checkAllNone").is(":checked")){
			$('input:checkbox').prop('checked', true);
		} else {
			$('input:checkbox').prop('checked', false);
		}
	}
	function ckall(){
		$('input:checkbox').prop('checked', true);
	}
	function cknone(){
		$('input:checkbox').prop('checked', false);
	}
	function ch_cc(v){
		$("input:checkbox").each(function() {
			if ($(this).data("ccde") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
		$("#cc").val('');
	}
	function ch_ia(v){
		$("input:checkbox").each(function() {
			if ($(this).data("insta") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
		$("#ia").val('');
	}
	function ch_inst(v){
		$("input:checkbox").each(function() {
			if ($(this).data("instn") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
		$("#inst").val('');
	}
	function ch_colln(v){
		$("input:checkbox").each(function() {
			if ($(this).data("colln") == v) {      
				$(this).prop('checked', true).trigger('change');                                        
			} 
		}); 
		$("#colln").val('');
	}
</script>
<cfquery name="ctcollection_dets" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select 
		guid_prefix,
		collection_cde,
		institution_acronym,
		institution,
		collection
	from collection order by guid_prefix
</cfquery>
<cfquery name="ctcolncde" dbtype="query">
	select collection_cde from ctcollection_dets group by collection_cde  order by collection_cde 
</cfquery>
<cfquery name="ctinsta" dbtype="query">
	select institution_acronym from ctcollection_dets group by institution_acronym  order by institution_acronym 
</cfquery>
<cfquery name="ctcollection" dbtype="query">
	select collection from ctcollection_dets group by collection  order by collection 
</cfquery>
<cfquery name="ctinstitution" dbtype="query">
	select institution from ctcollection_dets group by institution  order by institution 
</cfquery>
<cfoutput>
	<input type="button" class="lnkBtn" value="Select All" onclick="ckall();">
	<input type="button" class="lnkBtn" value="Select None" onclick="cknone();">
	<input type="button" class="savBtn" value="Use Selected" onclick="useSeld();">
	<label for="cc">Check all...</label>
	<select name="cc" id="cc" onChange="ch_cc(this.value)">
		<option value="">[ CollectionCode ]</option>
		<cfloop query="ctcolncde">
			<option value="#collection_cde#">#collection_cde#</option>
		</cfloop>
	</select>
	<label for="ia">Check all...</label>
	<select name="ia" id="ia" onChange="ch_ia(this.value)">
		<option value="">[ InstitutionAcronym ]</option>
		<cfloop query="ctinsta">
			<option value="#institution_acronym#">#institution_acronym#</option>
		</cfloop>
	</select>
	<label for="inst">Check all...</label>
	<select name="inst" id="inst" onChange="ch_inst(this.value)">
		<option value="">[ Institution ]</option>
		<cfloop query="ctinstitution">
			<option value="#institution#">#institution#</option>
		</cfloop>
	</select>
	<label for="colln">Check all...</label>
	<select name="colln" id="colln" onChange="ch_colln(this.value)">
		<option value="">[ Collection ]</option>
		<cfloop query="ctcollection">
			<option value="#collection#">#collection#</option>
		</cfloop>
	</select>
	<table border="1" id="t" class="sortable">
		<tr>
			<th><input type="checkbox" id="checkAllNone" onchange="checkAllNone();"></th>
			<th>GUIDPrefix</th>
			<th>InstitutionAcronym</th>
			<th>CollectionCode</th>
			<th>Institution</th>
			<th>Collection</th>
		</tr>
		<cfloop query="ctcollection_dets">
			<tr>
				<td>
					<input 
						data-ccde="#collection_cde#" 
						data-insta="#institution_acronym#" 
						data-colln="#collection#" 
						data-instn="#institution#" 
						type="checkbox" 
						name="#guid_prefix#" 
						<cfif listfind(gps,guid_prefix)> checked </cfif> 
					>
				</td>
				<td>#guid_prefix#</td>
				<td>#institution_acronym#</td>
				<td>#collection_cde#</td>
				<td>#institution#</td>
				<td>#collection#</td>
			</tr>
		</cfloop>
	</table>
	<input type="button" class="savBtn" value="Use Selected" onclick="useSeld();">
</cfoutput>