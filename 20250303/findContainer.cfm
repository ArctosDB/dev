<cfinclude template="/includes/_header.cfm">
<cfset title='Find Containers'>
<script type='text/javascript' src='/includes/dhtmlxtree.js'><!-- --></script>
<script type="text/javascript" src="/includes/dhtmlxcommon.js"></script>
<link rel="STYLESHEET" type="text/css" href="/includes/dhtmlxtree.css">
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<script>
	jQuery(document).ready(function() {
		jQuery("#part_name").autocomplete("/ajax/part_name.cfm", {
			width: 320,
			max: 20,
			autofill: true,
			highlight: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300
		});
		$("#begin_last_date").datepicker();
		$("#end_last_date").datepicker();
	});
</script>
<style >
	.cTreePane {
		height:400px;
		overflow-y:scroll;
		overflow-x:auto;
		padding-right:10px;
	}
	.ajaxWorking{
		top: 20%;
		color: green;
		text-align: center;
		margin: auto;
		position:absolute;
		max-width: 50%;
		right:2%;
		background-color:white;
		padding:1em;
		border:1px solid;
		overflow:hidden;
		z-index:1;
		overflow-y:scroll;
		}
	.ajaxDone {display:none}
	.ajaxMessage {color:green;}
	.ajaxError {color:red;}
</style>
<script type='text/javascript' src='/includes/_treeAjax.js'></script>
<cfquery name="contType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select container_type from ctContainer_Type order by container_type
</cfquery>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select collection_id, guid_prefix from collection order by guid_prefix
</cfquery>
<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select OTHER_ID_TYPE from ctcoll_other_id_type order by OTHER_ID_TYPE
</cfquery>
<cfoutput>
<div id="ajaxMsg"></div>
<table border width="100%">
	<tr>
		<td valign="top"><!--------------------------- search pane ----------------------------->
			<div id="searchPane">
				<form onSubmit="loadTree();return false;">
				<input type="hidden" name="transaction_id" id="transaction_id">
				<!---- https://github.com/ArctosDB/dev/issues/61 remove collection_id ---->
                <label for="cat_num">
                    <span data-helplink="cat_num" class="helpLink">Cat Num (comma-list OK)</span>
                </label>
                <input type="text" name="cat_num" id="cat_num"  />
				
                <label for="barcode">
                    <span data-helplink="barcode" class="helpLink">Container Barcode (comma-list OK)</span>
                </label>
				<input type="text" name="barcode" id="barcode"  />

				<label for="in_barcode">
                    <span data-helplink="barcode" class="helpLink">IN Container Barcode (comma-list OK)</span>
                </label>
				<input type="text" name="in_barcode" id="in_barcode"  />
                    
                <label for="container_label">
                    <span data-helplink="container_label" class="helpLink">Label (% for wildcard)</span>
                </label>
				<input type="text" name="container_label" id="container_label"  />

				<label for="container_remark">
                    <span data-helplink="container_remarks" class="helpLink">Remark</span>
                </label>
				<input type="text" name="container_remark" id="container_remark"  />

				<label for="has_children">Has Children</label>
				<select name="has_children" id="has_children" size="1">
					<option value=""></option>
					<option value="true">true</option>
					<option value="false">false</option>
				</select>
				<label for="begin_last_date">Earliest LastDate</label>
				<input type="text" name="begin_last_date" id="begin_last_date"  />

				<label for="end_last_date">Latest LastDate</label>
				<input type="text" name="end_last_date" id="end_last_date"  />
                    
				<label for="description">
                    <span data-helplink="description" class="helpLink">Description (% for wildcard)</span>
                </label>
				<input type="text" name="description" id="description"  />
                    
				<label for="part_name">
                    <span data-helplink="part_name" class="helpLink">Part</span>
                </label>
				<input type="text" id="part_name" name="part_name">
                    
				<label for="container_type">
                    <span data-helplink="container_type" class="helpLink">Container Type</span>
                </label>
				<select name="container_type" id="container_type" size="1">
					<option value=""></option>
					  <cfloop query="contType">
						<option value="#contType.container_type#">#contType.container_type#</option>
					  </cfloop>
				</select>
                    
				<label for="in_container_type">
                    <span data-helplink="container_type" class="helpLink">Contained By Container Type</span>
                </label>
				<select name="in_container_type" id="in_container_type" size="1">
					<option value=""></option>
					  <cfloop query="contType">
						<option value="#contType.container_type#">#contType.container_type#</option>
					  </cfloop>
				</select>
                    
				<label for="other_id_type">
                    <span data-helplink="other_id_type" class="helpLink">OID Type</span>
                </label>
				<select name="other_id_type" id="other_id_type" size="1" style="width:120px;">
					<option value=""></option>
					<cfloop query="ctcoll_other_id_type">
						<option value="#ctcoll_other_id_type.other_id_type#">#ctcoll_other_id_type.other_id_type#</option>
					</cfloop>
				</select>
                    
				<label for="other_id_value">
                    <span data-helplink="other_id_num" class="helpLink">OID Value (% for wildcard)</span>
                </label>
				<input type="text" name="other_id_value" id="other_id_value" />
                    
				<label for="loan_number">
                    <span data-helplink="loan_number" class="helpLink">Loan Number</span>
                </label>
				<input type="text" name="loan_number" id="loan_number" />

				<label for="sort_by">
                    <span>Sort Expansion</span>
                </label>
				<select name="sort_by" id="sort_by" size="1" style="width:120px;">
					<option value="label_barcode">label, barcode</option>
					<option value="barcode_label">barcode,label</option>
					<option value="label_barcode_int">label, barcode (numeric)</option>
					<option value="barcode_label_int">barcode, label (numeric)</option>
				</select>
                    
				<input type="hidden" name="collection_object_id" id="collection_object_id" />
				<input type="hidden" name="loan_trans_id" id="loan_trans_id" />
				<input type="hidden" name="container_id" id="container_id" />
				<input type="hidden" name="table_name" id="table_name" />
				<br>
				<input type="submit" value="Search"	class="schBtn">
				&nbsp;&nbsp;&nbsp;
				<input class="clrBtn" type="button" value="Clear" onclick='document.location="/findContainer.cfm";'/>
				</form>
				<span class="likeLink" onclick="downloadTree()">Flatten Part Locations</span>
				<br><span class="likeLink" onclick="showTreeOnly()">Drag/Print</span>
				<br><span class="likeLink" onclick="printLabels()">Print Labels</span>
			</div>
		</td><!--------------------------------- end search pane ------------------------------------->
		<td><!------------------------------------- tree pane --------------------------------------------->
			<div style="max-height:2em;overflow:auto;font-size:x-small;">
				Check/uncheck a box for more options. Doubliclick text to expand. Containers prefixed with * have environmental data.
			</div>
			<div id="treePane" class="cTreePane"></div>
		</td><!------------------------------------- end tree pane --------------------------------------------->
		<td valign="top">
			<div id="detailPane"></div>
		</td>
	</tr>
</table>
<div id="thisfooter">
	<cfinclude template="/includes/_footer.cfm">
</div>
<cfif isdefined("url.collection_object_id") and len(url.collection_object_id) gt 0 and not isdefined("url.showControl")>
	<script language="javascript" type="text/javascript">
		try {
			parent.dyniframesize();
		} catch(err) {
			// not where we think we are, maybe....
		}
		showSpecTreeOnly('#url.collection_object_id#');
	</script>
<cfelse>
	<cfset autoSubmit=false>
	<cfloop list="#StructKeyList(url)#" index="key">
		<cfif len(#url[key]#) gt 0>
			<cfset autoSubmit=true>
			<script language="javascript" type="text/javascript">
				if (document.getElementById('#lcase(key)#')) {
					document.getElementById('#lcase(key)#').value='#url[key]#';
				}
			</script>
		</cfif>
	</cfloop>
	<cfif autoSubmit is true>
	<script language="javascript" type="text/javascript">
		loadTree();
	</script>
	</cfif>
</cfif>
</cfoutput>