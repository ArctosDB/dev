<cfinclude template="/includes/_header.cfm">
<cfset title="part to container">
<script>



function addPartToContainer () {
	var cid,pid1,pid2,parent_barcode,new_container_type;
	document.getElementById('pTable').className='red';
	cid=document.getElementById('collection_object_id').value;
	pid1=document.getElementById('part_name').value;
	pid2=document.getElementById('part_name_2').value;
	parent_barcode=document.getElementById('parent_barcode').value;
	new_container_type=document.getElementById('new_container_type').value;
	if(cid.length===0 || pid1.length===0 || parent_barcode.length===0) {
		alert('Something is null');
		return false;
	}
	$.getJSON("/component/functions.cfc",
		{
			method : "addPartToContainer",
			collection_object_id : cid,
			part_id : pid1,
			part_id2 : pid2,
			parent_barcode : parent_barcode,
			new_container_type : new_container_type,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			statAry=result.split("|");
			var status=statAry[0];
			var msg=statAry[1];
			document.getElementById('pTable').className='';
			var mDiv=document.getElementById('msgs');
			var mhDiv=document.getElementById('msgs_hist');
			var mh=mDiv.innerHTML + '<hr>' + mhDiv.innerHTML;
			mhDiv.innerHTML=mh;
			mDiv.innerHTML=msg;
			if (status===0){
				mDiv.className='error';
			} else {
				mDiv.className='successDiv';
				document.getElementById('oidnum').focus();
				document.getElementById('oidnum').select();
				getParts();
			}
		}
	);
}


 function getParts() {
	
	guid_prefix=document.getElementById('guid_prefix').value;
	other_id_type=document.getElementById('other_id_type').value;
	oidnum=document.getElementById('oidnum').value;
	if (guid_prefix.length>0 && other_id_type.length>0 && oidnum.length>0) {
		s=document.createElement('DIV');
	    s.id='ajaxStatus';
	    s.className='ajaxStatus';
	    s.innerHTML='Fetching parts...';
	    document.body.appendChild(s);
	    noBarcode=document.getElementById('noBarcode').checked;
	    noSubsample=document.getElementById('noSubsample').checked;
	    $.getJSON("/component/functions.cfc",
			{
				method : "getParts",
				guid_prefix : guid_prefix,
				other_id_type : other_id_type,
				oidnum : oidnum,
				noBarcode : noBarcode,
				noSubsample : noSubsample,
				returnformat : "json",
				queryformat : 'struct'
			},
			function (r) {
				s=document.getElementById('ajaxStatus');
				document.body.removeChild(s);
				sDiv=document.getElementById('thisSpecimen');
				ocoln=document.getElementById('guid_prefix');
				specid=document.getElementById('collection_object_id');
				p1=document.getElementById('part_name');
				p2=document.getElementById('part_name_2');
				op1=p1.value;
				op2=p2.value;
				p1.options.length=0;
				p2.options.length=0;
				selIndex = ocoln.selectedIndex;
				coln = ocoln.options[selIndex].text;		
				idt=document.getElementById('other_id_type').value;
				idn=document.getElementById('oidnum').value;
				ss=coln + ' ' + idt + ' ' + idn;
				if (r.status != 'success'){
					sDiv.className='error';
					ss+=' = ' + result.part_name[0];
					specid.value='';
					document.getElementById('pTable').className='red';
					return false;

				}
				result=r.DATA;
				document.getElementById('pTable').className='';
				sDiv.className='';
				specid.value=result[0].collection_object_id;
				option = document.createElement('option');
				option.setAttribute('value','');
				option.appendChild(document.createTextNode(''));
				p2.appendChild(option);
				
				for (i=0;i<result.length;i++) {

					option = document.createElement('option');
					option2 = document.createElement('option');
					option.setAttribute('value',result[i].partid);
					option2.setAttribute('value',result[i].partid);
					pStr=result[i].partstring;
					option.appendChild(document.createTextNode(pStr));
					option2.appendChild(document.createTextNode(pStr));
					p1.appendChild(option);
					p2.appendChild(option2);
				}
				p1.value=op1;
				p2.value=op2;	
				ss+=' = <a target="_blank" href="/guid/' + result[0].guid + '">' + result[0].guid +'</a>';
				//ss+= ' (' + result.customidtype[0] + ' ' + result.customid[0] + ')';
				sDiv.innerHTML=ss;
			}
		);
	}
 }

function checkSubmit() {
	var c;
	c=document.getElementById('submitOnChange').checked;
	if (c===true) {
		addPartToContainer();
	}
}

</script>
<style>
	.messageDiv {
		background-color:lightgray;
		text-align:center;
		font-size:.8em;
		margin:0em .5em 0em .5em;
	}
	.successDiv {
		color:green;
		border:1px solid;
		padding:.5em;
		margin:.5em;
		text-align:center;
	}
</style>
<!------------------------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>
	<cfquery name="ctCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix  FROM collection order by guid_prefix
	</cfquery>
	<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select other_id_type FROM ctcoll_other_id_type order by other_id_type
	</cfquery>
	<cfquery name="ctContType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type	order by container_type
	</cfquery>

	<div style="font-size:.8em;">
		This application puts collection objects into containers.
		Parts are listed in three ways:
		<ul>
			<li><strong>Part Name</strong> = just a part</li>
			<li><strong>Part Name SAMPLE</strong> = a subsample of another part</li>
			<li><strong>Part Name [barcode]</strong> = a part which is in a barcoded container</li>
		</ul>
		Things occasionally get stuck - click Refresh to unstick them.
	</div>
	<p style="font-size:.8em;">
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Submit form with Parent Barcode change? <input type="checkbox" name="submitOnChange" id="submitOnChange">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Filter for un-barcoded parts? <input type="checkbox" name="noBarcode" id="noBarcode"  onchange="getParts()">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			Exclude subsamples? <input type="checkbox" name="noSubsample" id="noSubsample"  onchange="getParts()">
		</span>
		<span style="border:1px solid blue; padding:5px;margin:5px;">
			<span class="likeLink"  onclick="getParts()">Refresh Parts List</span>
		</span>
	</p>
	<table border id="pTable">
	<form name="scans" method="post" id="scans">
		<input type="hidden" name="action" value="validate">
		<input type="hidden" name="collection_object_id" id="collection_object_id">
		<tr>
			<td>
				<label for="collection_id">Collection</label>
				<select name="guid_prefix" id="guid_prefix" size="1" onchange="getParts()">
					<cfloop query="ctCollection">
						<option value="#guid_prefix#">#guid_prefix#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="other_id_type">ID Type</label>
				<select name="other_id_type" id="other_id_type" size="1" style="width:120px;" onchange="getParts()">
					<option value="catalog_number">Catalog Number</option>
					<cfloop query="ctOtherIdType">
						<option value="#other_id_type#">#other_id_type#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="oidnum">ID Number</label>
				<input type="text" name="oidnum" class="reqdClr" id="oidnum" onchange="getParts()">
			</td>
			<td>
				<label for="part_name">Part Name</label>
				<select name="part_name" id="part_name" size="1" style="width:160px;">
				</select>
			</td>
			<td>
				<label for="part_name_2">Part Name 2</label>
				<select name="part_name_2" id="part_name_2" size="1" style="width:160px;">
					<option value=""></option>
				</select>
			</td>
			<td>
				<label for="new_container_type">Parent Cont Type</label>
				<select name = "new_container_type" id="new_container_type" size="1" class="reqdClr">
					<option value=""></option>
					<cfloop query="ctContType">
						<option value="#container_type#">#container_type#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="parent_barcode">Parent Barcode</label>
				<input type="text" name="parent_barcode" id="parent_barcode" onchange="checkSubmit()">
			</td>
	  		<td>
				<input type="button" value="Move it" class="savBtn" onclick="addPartToContainer()">
			</td>
			<!----
			<td>
				<input type="button" value="New Part" class="insBtn" onclick="clonePart()">
			</td>
			---->
		</tr>
	</table>
	</form>
	<div id="thisSpecimen" style="border:1px solid green;font-size:smaller;"></div>
	<div id="msgs"></div>
	<div id="msgs_hist" class="messageDiv"></div>
	<script>
		document.getElementById('oidnum').focus();
		document.getElementById('oidnum').select();
	</script>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm"/>

<!--------------- 202410: this used to be able to cfreate a new part, via /form/newPart.cfm, code here:



function makePart(){
	var collection_object_id,part_name,part_count,disposition,condition,part_remark,barcode,new_container_type,result,status,msg,p,b;
	collection_object_id=document.getElementById('collection_object_id').value;
	part_name=document.getElementById('npart_name').value;
	part_count=document.getElementById('part_count').value;
	disposition=document.getElementById('disposition').value;
	condition=document.getElementById('condition').value;
	part_remark=document.getElementById('part_remark').value;
	barcode=document.getElementById('barcode').value;
	new_container_type=document.getElementById('new_container_type').value;
	$.getJSON("/component/functions.cfc",
		{
			method : "makePart",
			collection_object_id : collection_object_id,
			part_name : part_name,
			part_count : part_count,
			disposition : disposition,
			condition : condition,
			part_remark : part_remark,
			barcode : barcode,
			new_container_type : new_container_type,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r){
			result=r.DATA;
			status=result.STATUS[0];
			if (status=='error') {
				msg=result.MSG[0];
				alert(msg);
			} else {
				msg="Created part: ";
				msg += result.PART_NAME[0] + " ";
				if (result.BARCODE[0]!==null) {
					msg += "barcode " + result.BARCODE[0];
					if (result.NEW_CONTAINER_TYPE[0]!==null) {
						msg += "( " + result.NEW_CONTAINER_TYPE[0] + ")";
					}
				}
				p = document.getElementById('ppDiv');
				document.body.removeChild(p);
				b = document.getElementById('bgDiv');
				document.body.removeChild(b);
				getParts();
			}
		}
	);
}



<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="makePart" access="remote">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="part_name" type="string" required="yes">
	<cfargument name="part_count" type="string" required="yes">
	<cfargument name="disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="part_remark" type="string" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="ccid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_collection_object_id') nv
			</cfquery>
			<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID,
					PART_NAME,
					DERIVED_FROM_cat_item,
					created_agent_id,
					created_date,
					disposition,
					part_count,
					condition,
					part_remark
				) VALUES (
					<cfqueryparam value="#ccid.nv#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#PART_NAME#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
					current_timestamp,
					<cfqueryparam value="#disposition#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#part_count#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#condition#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#part_remark#" cfsqltype="cf_sql_int" null="#Not Len(Trim(part_remark))#">
				)
			</cfquery>
			
			<cfif len(barcode) gt 0>
				<!--- map here to we can copy-paste the procedure call --->
				<cfset thisCollectionObjectID=ccid.nv>
				<cfset thisBarcode=barcode>
				<cfset thisContainerID="">
				<cfset thisParentType=new_container_type>
				<cfset thisParentLabel="">
				<!---- END: map here to we can copy-paste the procedure call --->
				<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				call movePartToContainer(
					<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
					<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
					<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
					<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
					<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
				)
				</cfquery>
			</cfif>
			<cfset q=queryNew("STATUS,PART_NAME,part_count,disposition,CONDITION,part_remark,BARCODE,NEW_CONTAINER_TYPE")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
			<cfset t = QuerySetCell(q, "part_name", "#part_name#", 1)>
			<cfset t = QuerySetCell(q, "part_count", "#part_count#", 1)>
			<cfset t = QuerySetCell(q, "disposition", "#disposition#", 1)>
			<cfset t = QuerySetCell(q, "condition", "#condition#", 1)>
			<cfset t = QuerySetCell(q, "part_remark", "#part_remark#", 1)>
			<cfset t = QuerySetCell(q, "barcode", "#barcode#", 1)>
			<cfset t = QuerySetCell(q, "new_container_type", "#new_container_type#", 1)>
		</cftransaction>
		<cfcatch>
			<cfset q=queryNew("status,msg")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "status", "error", 1)>
			<cfset t = QuerySetCell(q, "msg", "#cfcatch.message# #cfcatch.detail#:: #ccid.nv#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>



function clonePart() {
	var collection_id=document.getElementById('collection_id').value;
	var other_id_type=document.getElementById('other_id_type').value;
	var oidnum=document.getElementById('oidnum').value;
	if (collection_id.length>0 && other_id_type.length>0 && oidnum.length>0) {
		$.getJSON("/component/functions.cfc",
			{
				method : "getSpecimen",
				collection_id : collection_id,
				other_id_type : other_id_type,
				oidnum : oidnum,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {		
				if (toString(r.DATA.COLLECTION_OBJECT_ID[0]).indexOf('Error:')>-1) {
					alert(r.DATA.COLLECTION_OBJECT_ID[0]);	
				} else {
					newPart (r.DATA.COLLECTION_OBJECT_ID[0]);
				}
			}
		);
	} else {
		alert('Error: cannot resolve ID to specimen.');
	}
}

function newPart (collection_object_id) {
	// used by clonePart, which is used by part2container.cfm
	var part,url;
	collection_id=document.getElementById('collection_id').value;
	part=document.getElementById('part_name').value;
	url="/form/newPart.cfm";
	url +="?collection_id=" + collection_id;
	url +="&collection_object_id=" + collection_object_id;
	url +="&part=" + part;
	divpop(url);
}


function divpop (url) {
	// used by newPart
	var req,bgDiv,theDiv;
 	bgDiv=document.createElement('div');
	bgDiv.id='bgDiv';
	bgDiv.className='bgDiv';
	document.body.appendChild(bgDiv);
	theDiv = document.createElement('div');
	theDiv.id = 'ppDiv';
	theDiv.className = 'pickBox';
	theDiv.innerHTML='Loading....';
	theDiv.src = "";
	document.body.appendChild(theDiv);	
	if (window.XMLHttpRequest) {
	  req = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
	  req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	if (req !== undefined) {
	  req.onreadystatechange = function() {divpopDone(req);};
	  req.open("GET", url, true);
	  req.send("");
	}
}
function divpopDone(req) {
	// used by divpop
	if (req.readyState == 4) { // only if req is "loaded"
		if (req.status == 200) { // only if "OK"
		  document.getElementById('ppDiv').innerHTML = req.responseText;
		} else {
		  document.getElementById('ppDiv').innerHTML="ahah error:\n"+req.statusText;
		}
		var p = document.getElementById('ppDiv');
		var cSpan=document.createElement('span');
		cSpan.className='popDivControl';
		cSpan.setAttribute('onclick','divpopClose();');
		cSpan.innerHTML='X';
		p.appendChild(cSpan);
	}
}
function divpopClose(){
	//used by divpop
	var p = document.getElementById('ppDiv');
	document.body.removeChild(p);
	var b = document.getElementById('bgDiv');
	document.body.removeChild(b);
}




	<cfinclude template="/includes/_includeHeader.cfm">
<cfoutput>
	<cfquery name="ctcontainer_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type	order by container_type
	</cfquery>
	<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select disposition from ctdisposition order by disposition
	</cfquery>
	<cfquery name="thisCC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select collection.guid_prefix from collection
		inner join cataloged_item on cataloged_item.collection_id=collection.collection_id
		where cataloged_item.collection_object_id=<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
	</cfquery>

	<cfquery name="defaults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			part_name,
			part_count,
			disposition,
			condition,
			collection.guid_prefix
		from
			specimen_part,
			cataloged_item,
			collection
		where
			specimen_part.derived_from_cat_item=cataloged_item.collection_object_id and
			cataloged_item.collection_id=collection.collection_id and
			cataloged_item.collection_id=#collection_object_id#
			<cfif isdefined("part") and len(part) gt 0>
				and part_name='#part#'
			</cfif>
			limit 1
	</cfquery>
<form name="newPart" method="post" action="/form/newPart.cfm">
	<input type="hidden" name="action" value="newPart">
	<input type="hidden" name="collection_object_id" id="collection_object_id" value="#collection_object_id#">
	<input type="hidden" name="collection_id" value="#collection_id#">
	<label for="npart_name">Part Name</label>
	<input type="text" name="npart_name" id="npart_name" class="reqdClr"
		value="#defaults.part_name#" size="25"
		onchange="findPart(this.id,this.value,'#thisCC.guid_prefix#');"
		onkeypress="return noenter(event);">
	<label for="part_count">Part Count</label>
	<input type="text" name="part_count" id="part_count" class="reqdClr" size="2" value="#defaults.part_count#">
	<label for="disposition">Disposition</label>
	<select name="disposition" id="disposition" size="1"  class="reqdClr">
    	<cfloop query="ctdisposition">
        	<option
				<cfif defaults.disposition is ctdisposition.disposition>selected="selected"</cfif>
				value="#disposition#">#disposition#</option>
        </cfloop>
    </select>
	<label for="condition">Condition</label>
	<input type="text" name="condition" id="condition" class="reqdClr" value="#defaults.condition#">
	<label for="part_remark">Remarks</label>
	<input type="text" name="part_remark" id="part_remark">
	<label for="barcode">Barcode</label>
	<input type="text" name="barcode" id="barcode">
	<label for="new_container_type">Change barcode to Container Type</label>
	<select name="new_container_type" id="new_container_type" size="1">
    	<cfloop query="ctcontainer_type">
        	<option value="#container_type#">#container_type#</option>
        </cfloop>
    </select>
	<br><input type="button" value="Create" class="insBtn" onclick="makePart();">
  </form>
</cfoutput>
----->