<cfinclude template="/includes/_header.cfm">
<cfset title="Browse/Edit Bulkloaded Data">
<!-----------------------------
<script src="/includes/sorttable.js"></script>

<style>
.blTabDiv {
	width: 100%;
	overflow:scroll;
}
</style>
<cfparam name="enteredby" default="" type="any">
<cfparam name="accn" default="" type="any">
<cfparam name="colln" default="" type="any">


<cfif len(enteredby) gt 0>
	<cfif left(enteredby,1) neq "'">
		<cfset enteredby=listqualify(enteredby,"'")>
	</cfif>
</cfif>

<cfif len(accn) gt 0>
	<cfif left(accn,1) neq "'">
		<cfset accn=listqualify(accn,"'")>
	</cfif>
</cfif>
<cfif len(colln) gt 0>
	<cfif left(colln,1) neq "'">
		<cfset colln=listqualify(colln,"'")>
	</cfif>
</cfif>

--------------------------------->



<!----------------------- globals ---------------------------------------->
<cfset reqdFlds="collection_object_id,status,extras,enteredby">
<cfset hiddenFlds="collection_id,entered_agent_id,wkt_media_id">


<cfparam name="enteredby" default="">
<cfparam name="accn" default="">
<cfparam name="colln" default="">
<cfparam name="collection_object_id" default="">
<cfparam name="uuid" default="">
<cfparam name="catnum" default="">
<!----------------------- /globals ---------------------------------------->



<cfif action is "nothing">
	<link rel="stylesheet" type="text/css" href="/includes/DataTablesnojq/datatables.min.css"/>
	<script type="text/javascript" src="/includes/DataTablesnojq/datatables.min.js"></script>

	<link rel="stylesheet" type="text/css" href="/includes/style.min.css"/>
	<script>

		function addFltr(id){
			var ids=$("#collection_object_id").val();
			var idary=ids.split(',');
			idary.push(id); 
			idary = idary.filter(function(e){return e}); 
			var uary = idary.filter((v, i, a) => a.indexOf(v) === i);
			var rid=uary.join(',');
			$("#collection_object_id").val(rid);
		}


		function massMarkToLoad(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var cid=$("#collection_object_id").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var tg='browseBulk.cfm?action=massmarkToload&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&collection_object_id=' + cid + "&catnum=" + catnum + "&uuid=" + uuid;
			document.location=tg;
		}


		function massMarkToDelete(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var cid=$("#collection_object_id").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var tg='browseBulk.cfm?action=massMarkToDelete&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&collection_object_id=' + cid + "&catnum=" + catnum + "&uuid=" + uuid;
			document.location=tg;
		}


		function downloadThis(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var cid=$("#collection_object_id").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var tg='browseBulk.cfm?action=download&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&collection_object_id=' + cid + "&catnum=" + catnum + "&uuid=" + uuid;
			document.location=tg;
		}


		function sqltab(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			// this purposefully does not include collection_object_id, uuid, or catnum
			var tg='browseBulk.cfm?action=sqlTab&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c;
			document.location=tg;
		}

	</script>



	<!-----------------------
		get columns to display
	------------------------>
	<!--- first see if they've got custom fields --->

	<cfquery name="usrPrefs" datasource="uam_god">
		select unnest(usr_fields) as colname from cf_de_approve_settings where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
	</cfquery>
	<cfquery name="usrPrefRows" datasource="uam_god">
		select coalesce(browse_bulk_rows,10) as browse_bulk_rows from cf_users where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
	</cfquery>
	<input type="hidden" id="browse_bulk_rows" value="<cfoutput>#usrPrefRows.browse_bulk_rows#</cfoutput>">
	<cfif usrPrefs.recordcount gt 0>
		<cfset usrColumnList=reqdFlds>
		<cfset usrColumnList=listappend(usrColumnList,valuelist(usrPrefs.colname))>
		<div class="importantNotification">
			Table customization detected! This can be dangerous. <a href="browseBulk.cfm?action=customize">customize</a>
		</div>
	<cfelse>
		<cfquery name="cNames" datasource="uam_god">
			select column_name from information_schema.columns where table_name='bulkloader' and
				column_name not like '%$%' and
				column_name not in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#hiddenFlds#" list="true">) and
				column_name not in  (<cfqueryparam cfsqltype="cf_sql_varchar" value="#reqdFlds#" list="true">)
		</cfquery>
		<cfset usrColumnList=reqdFlds>
		<cfset usrColumnList=listappend(usrColumnList,valuelist(cNames.column_name))>
	</cfif>
	<!--- duplicates find their way in and kill datatables --->
	<cfset usrColumnList = ListRemoveDuplicates(usrColumnList)>

	<!-----------------------
		/ get columns to display
	------------------------>
	<cfquery name="ctAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			accn
		from
			bulkloader
		group by
			accn
		order by
			accn
	</cfquery>
	<cfquery name="ctColln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid_prefix colln
		from
			bulkloader
		group by
			guid_prefix
		order by guid_prefix
	</cfquery>
	<cfquery name="ctEnteredby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			enteredby
		from
			bulkloader
		group by
			enteredby
		order by
			enteredby
	</cfquery>
	<cfoutput>
	<script>
		$(document).ready(function() {
			 editor = new $.fn.dataTable.Editor( {
			 	 ajax:   '/component/Bulkloader.cfc?method=saveDTableEdit',
    		    table: "##bedit",
		        idSrc: 'collection_object_id',
 				formOptions: {
		            inline: {
        	        onBlur: 'submit'
            	}
	        },
    	    fields: [
				<cfloop list="#usrColumnList#" index="col">
					<cfif col is "enteredby" or col is "guid_prefix"  or col is "enteredtobulkdate" or col is "extras">
						{ label: "#col#" ,name: "#col#",type:'readonly', attr:{ disabled:true } }
					<cfelse>
						{ label: "#col#" ,name: "#col#" }
					</cfif>
					<cfif not listlast(usrColumnList) is col>,</cfif>
				</cfloop>
			     ]
	   		});
			var oTable = $('##bedit').DataTable( {
				"pageLength": #usrPrefRows.browse_bulk_rows#,
        		"processing": true,
		        "serverSide": true,
        		"searching": false,
        		"stateSave": true,
				"stateSaveCallback": function (settings, data) {
					if ($("##browse_bulk_rows").val() != data["length"]){
						$("##browse_bulk_rows").val(data["length"]);
						$.ajax({
							url: "/component/functions.cfc?",
							type: "GET",
							dataType: "json",
							data: {
								method: "changeUserPreference_int",
								returnformat: "json",
								pref: "browse_bulk_rows",
								val: data["length"]
							},
							success: function(r) {
								//nada
							},
							error: function (xhr, textStatus, errorThrown){
							    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
							}
						});
					}
				 },
		        columnDefs: [
				{
				    targets: 0,
			    	render: function (data, type, row, meta)
				    {
				        if (type === 'display') {
				        	x = '<a target="_blank" href="/editBulkloader.cfm?collection_object_id=' + encodeURIComponent(data) + '">' + data + '</a>';
				        	x += '<a target="_blank" href="/DataEntry.cfm?action=edit&ImAGod=yes&collection_object_id=' + encodeURIComponent(data) + '">[ old edit ]</a>';

				            //x = '<a target="_blank" href="/DataEntry.cfm?action=edit&ImAGod=yes&collection_object_id=' + encodeURIComponent(data) + '">' + data + '</a>';
				            //x += '<a target="_blank" href="/editBulkloader.cfm?collection_object_id=' + encodeURIComponent(data) + '"> [ new edit ]</a>';
				            x += '<a target="_blank" href="/enter_data.cfm?seed_record_id=' + encodeURIComponent(data) + '"> [ enter from seed ]</a>';
				            x += '<span class="likeLink" onclick="addFltr(\''+encodeURIComponent(data) + '\')"> [ filter ]</span>';
							//x +='<a target="_blank" href="browseBulk.cfm?action=showExtras&collection_object_id=' + data + '"> [ extras ]</a>';
							data=x;
			    	    }
			        	return data;
			    	},
				}],
		        keys: {
        		    columns: ':not(:first-child)',
			          //  keys: [ 9 ],
            		editor: editor,
		            editOnFocus: true
        		},
		        "ajax": {
        		    "url": "/component/Bulkloader.cfc?method=getDTRecords",
		            "type": "POST",
        		    "data": function ( d ) {
						d.enteredby = $('##enteredby').val().toString(),
						d.accn = $('##accn').val().toString(),
						d.colln = $('##colln').val().toString(),
						d.collection_object_id = $('##collection_object_id').val().toString(),
						d.uuid = $('##uuid').val().toString(),
						d.catnum = $('##catnum').val().toString()
					}
       		 	},
		        columns: [
					<cfloop list="#usrColumnList#" index="col">
						{ data: "#col#" }
						<cfif not listlast(usrColumnList) is col>,</cfif>
					</cfloop>
			    ],
			});

			editor.on( 'preSubmit', function ( e, data, action ) {
				$.each( data.data, function ( key, values ) {
					for (var xxx in values) {
				    	var fld=xxx;
				    	var fldval=values[xxx];
					}
					data.cid = key;
				    data.fld = fld;
				    data.fldval = fldval;
				});
			});

			$("##goFilter").click(function() {
			   $('##bedit').DataTable().ajax.reload();
			});

			$('##bedit').css( 'display', 'table' );

			oTable.responsive.recalc();
		});


		function hideEmptyColumns() {
		    var emptyColumnsIndexes = []; // store index of empty columns here
		    // check each column separately for empty cells
		    $("##bedit thead").find('th').each(function(i) {
			    //	console.log(i);
		        // get all cells for current column
        		var cells = $(this).parents('table').find('tr td:nth-child(' + (i + 1) + ')');
		        var emptyCells = 0;
		        cells.each(function(cell) {
        		    // increase emptyCells if current cell is empty, trim string to remove possible spaces in cell
		            if ($(this).html().trim() === '') {
		                emptyCells++;
		            //    console.log('got empty....');
		            }
		        });
				// if all cells are empty push current column to emptyColumns
		        if (emptyCells === $(cells).length) {
		            emptyColumnsIndexes.push($(this).index());
		        }
 		   });
			// only make changes if there are columns to hide
		    if (emptyColumnsIndexes.length > 0) {
    			emptyColumnsIndexes.forEach(function (item, index) {
					//console.log(item);
					$('##bedit').DataTable().column( item ).visible( false, false );
				   //var tcth=$('##bedit').DataTable().column(item).header() ;
			 	 //console.log( tcth);
				});
			//	$('##bedit').DataTable().columns.adjust().draw( false ); // adjust column sizing and redraw
    		}
		}

		function showAllColumns() {
		    var AllColumnsIndexes = $('##bedit').DataTable().columns().indexes();
			for (var x in AllColumnsIndexes) {
				// just turning everything on throws errors
				// so does pre-checking and only turning on those that weren't
				// but maybe not entirely fatal so whatever??
				// console.log('--------------------------------------');
				// console.log('running for' +  AllColumnsIndexes[x]);

				if (!(Number.isInteger(AllColumnsIndexes[x])==true)){
					// console.log('index is not int, fail');
					continue;
				}

				try {
					var tcth=$('##bedit').DataTable().column(AllColumnsIndexes[x]).header().innerHTML ;
					//console.log( AllColumnsIndexes[x] + 'header is --- ' + tcth);
				} catch(err) {
					//console.log('getting header failed ');
					continue;
				}
				try {
					if ( $('##bedit').DataTable().column(AllColumnsIndexes[x]).visible() )  {
						// console.log('is visible, no need to do anything else');
						continue;
					}
				} catch (err) {
					//console.log('check visibility fail catch');
					continue;
				}
				// console.log('passed checks, try');
				try {
				  	//console.log('tryigng: turning on: ' + AllColumnsIndexes[x]);
					$('##bedit').DataTable().column( AllColumnsIndexes[x] ).visible( true, false );
					// console.log('turned on: ' + AllColumnsIndexes[x]);
				}	catch(err) {
					//console.log('fail to turn on ' + AllColumnsIndexes[x]);
				}
			}
			$('##bedit').DataTable().columns.adjust().draw( false ); // adjust column sizing and redraw
		}
	</script>
	<cfset thisEnteredBy=enteredby>
	<cfset thisAccn=accn>
	<cfset thisColln=colln>
	<form name="f" method="post" action="browseBulk.cfm">
		<table >
			<tr>
				<td>
					<div>Filter</div>
					<div style="border:2px solid yellowgreen;padding:.5em;">
						<table>
							<tr>
								<td align="center">
									Entered By
								</td>
								<td align="center">
									Accession
								</td>
								<td align="center">
									Collection
								</td>
								<td align="center">Identifiers</td>
								<td></td>
							</tr>
							<tr>
								<td align="center">
									<select name="enteredby" multiple="multiple" size="12" id="enteredby">
										<option <cfif len(thisEnteredBy) is 0> selected="selected"</cfif> value="">Any</option>
										<cfloop query="ctEnteredby">
											<option <cfif listfind(thisEnteredBy,"#enteredby#")> selected="selected" </cfif> value="#enteredby#">#enteredby#</option>
										</cfloop>
									</select>
								</td>
								<td align="center">
									<select name="accn" multiple="multiple" size="12" id="accn">
										<option <cfif len(thisAccn) is 0> selected="selected"</cfif> value="" >Any</option>
										<cfloop query="ctAccn">
											<option <cfif listfind(thisAccn,"#accn#")> selected="selected" </cfif> value="#accn#">#accn#</option>
										</cfloop>
									</select>
								</td>
								<td align="center">
									<select name="colln" multiple="multiple" size="12" id="colln">
										<option <cfif len(thisColln) is 0> selected="selected"</cfif> value="" >Any</option>
										<cfloop query="ctColln">
											<option <cfif listfind(thisColln,"#colln#")> selected="selected" </cfif> value="#colln#">#colln#</option>
										</cfloop>
									</select>
								</td>
								<td align="center" valign="top">
									<div style="font-size:x-small">
										Bulkloader.collection_object_id
										<br>Comma-list OK
										<br>
									</span>
									<label for="collection_object_id">Collection Object ID</label>
									<textarea class="smalltextarea" name="collection_object_id" id="collection_object_id">#collection_object_id#</textarea>
									<label for="uuid">UUID</label>
									<textarea class="smalltextarea" name="uuid" id="uuid">#uuid#</textarea>

									<label for="catnum">CatNum (comma-list OK)</label>
									<textarea class="smalltextarea" name="catnum" id="catnum">#catnum#</textarea>

								</td>
								<td colspan="2" valign="middle">
									<div style="margin:3em;">
										<input type="button"id="goFilter" value="filter">
									</div>
								</td>
							</tr>
						</table>

					</div>

				</td>
				<td>
					<div style="margin-left: 5em; border:2px solid yellowgreen;padding:1em;">
						<table width="100%">
							<tr>
								<td align="center">
									Controls
								</td>
							</tr>
							<tr>
								<td>
									<input type="button" onclick="document.location='browseBulk.cfm?action=customize'" value="Customize View">
								</td>
							</tr>
							<tr>
								<td>
									<input type="button" onclick="downloadThis();" value="Download">
								</td>
							</tr>
							<tr>
								<td>
									<input type="button" onclick="sqltab();" value="SQL">
								</td>
							</tr>
							<tr>
								<td>
									<input type="button" onclick="massMarkToLoad()" value="Load All Selected Records">
								</td>
							</tr>

							<tr>
								<td>
									<input type="button" onclick="massMarkToDelete()" value="DELETE All Selected Records">
								</td>
							</tr>

							<tr>
								<td>
									<input type="button" onclick="hideEmptyColumns()" value="Hide Empty Columns">
								</td>
							</tr>
							<tr>
								<td>
									<input type="button" onclick="showAllColumns()" value="Show All Columns">
								</td>
							</tr>
						</table>

					</div>
					
				</td>
				<td valign="top">
					<ul>
						<li>Click the ID in the table to edit</li>
						<li>Click "old edit" in the table to edit in the old screen (recommendation: don't)</li>
						<li>Click "enter from seed" to seed a record in the new data entry app</li>
						<li>Click the "filter" link to add the ID to the filter (<-- over there), then the filter button to limit to selected records</li>
						<li>Actionable Values
							<ul>
								<li>Set status to autoload_core to load a record</li>
								<li>Set status to autoload_extras to load a record and any UUID-linked "extras"</li>
								<li>Set status to DELETE to delete a record. (Case sensitive, expect a ~30 minute delay.)</li>
							</ul>
						</li>
					</ul>
				</td>
			</tr>
		</table>

		
	</form>
	<table id="bedit" class="display compact nowrap stripe" style="width:100%">
		<thead>
			<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
		</thead>
		<tbody></tbody>
		<tfoot>
			<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
		</tfoot>
	</table>
</cfoutput>



</cfif>

<!---------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------->


<cfif action is "customize">
	<!----

		<cfinclude template="/includes/_header.cfm">



		create table cf_de_approve_settings (
			username varchar,
			usr_fields varchar[]
		);

		grant insert, update, select on cf_de_approve_settings to manage_collection;
	---->

<style>
		.dragger {
			cursor:move;
		}
	</style>
	<script>
		function toAry(){
			var linkOrderData= [];
			$.each($(".chk:checkbox:checked"), function(){
				linkOrderData.push(this.name);
            });
			$( "#usrcls" ).val(linkOrderData);
			$("#thefrm").submit();
		}

		function chkAll(){
			$.each($(".chk:checkbox"), function(){
				$(this).prop("checked", true);
            });
		}

		function chkNone(){
			$.each($(".chk:checkbox"), function(){
				$(this).prop("checked", false);
            });
		}


		$(function() {
			$( "#sortable" ).sortable({
				handle: '.dragger'
			});
		});
	</script>
<!---------
	jQuery(document).ready(function() {

			$( "#f" ).submit(function( event ) {
				var linkOrderData= [];
				$.each($(".chk:checkbox:checked"), function(){
               		linkOrderData.push(this.name);
	            });
				$( "#usrcls" ).val(linkOrderData);
				return false;
			});
		});

		select 'extras' as column_name,0 as ordinal_position union
		-------->
	<cfoutput>

	<cfquery name="cNames" datasource="uam_god">
		select * from (
		
		select column_name ,ordinal_position from information_schema.columns where table_name='bulkloader' and
			column_name not like '%$%' and
			column_name not in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#hiddenFlds#" list="true">) and
			column_name not in  (<cfqueryparam cfsqltype="cf_sql_varchar" value="#reqdFlds#" list="true">)
		) x order by ordinal_position
	</cfquery>

	<cfquery name="usrPrefs" datasource="uam_god">
		select unnest(usr_fields) as colname from cf_de_approve_settings where username='#session.username#'
	</cfquery>
	<cfquery name="notSelected" dbtype="query">
		select column_name as colname from cNames where column_name not in (select colname from usrPrefs)
	</cfquery>
	<h3>Datatables Browse/Edit Settings</h3>
	<p>
		Check the box to see the column in the datatables data entry approval/edit screen.
		<br>Drag columns to order.
		<br>Selecting none is the same as selecting all, but without ordering.
		<br>Use tip: check boxes, save, then drag to order.
		<br>Don't forget to save when you're done!
	</p>
	<p>
		<div class="importantNotification">
			You WILL NOT see unselected columns in the datatables data entry approval/edit screen, even if they have information in them; You can "approve" things that you cannot see. Values that are not selected will not be visible to you, and can not be changed in the datatables form.
			<br>If you check none and save, you will see all columns in the default order.
			<br>If you check all and save, you will see all columns as you've ordered them.
			<br>If you selectively check and save, you may not see important data. Use with caution.
		</div>
	</p>
	<a href="browseBulk.cfm">Back to edit</a> (don't forget to save first!)

	<form id="thefrm" name="f" method="post" action="browseBulk.cfm">
		<input type="button" onclick="toAry()" value="save">
		<input type="button" onclick="chkAll()" value="check all">
		<input type="button" onclick="chkNone()" value="check none">
		<input type="hidden" name="action" value="savePrefs">
		<input type="hidden" id="usrcls" name="usrcls">
	<table id="clastbl" border="1">
		<thead>
			<tr><th>Drag Handle</th><th>Column</th><th>Show?</th></tr>
		</thead>
				<tbody id="sortable">
					<cfloop query="usrPrefs">
						<tr id="cell_#colname#">
							<td class="dragger">
								(drag row here)
							</td>
							<td>#colname#</td>
							<td>
								<input class="chk" type="checkbox" name="#colname#" checked="checked">
							</td>
						</tr>
					</cfloop>
					<cfloop query="notSelected">
						<tr id="cell_#colname#">
							<td class="dragger">
								(drag row here)
							</td>
							<td>#colname#</td>
							<td>
								<input class="chk" type="checkbox" name="#colname#" >
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		<input type="button" onclick="toAry()" value="save">
	</form>

</cfoutput>
</cfif>

<!-------------------->

<cfif action is "finalMassLoad">
	<cfparam name="ld" default="autoload_core">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader set status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#ld#"> where collection_object_id>1000
				<cfif len(enteredby) gt 0>
					and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
				</cfif>
				<cfif  len(accn) gt 0>
					and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
				</cfif>
				<cfif len(colln) gt 0>
					and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
				</cfif>
				<cfif len(collection_object_id) gt 0>
					and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" list="true">)
				</cfif>
				<cfif len(uuid) gt 0>
					and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
				</cfif>
				<cfif len(catnum) gt 0>
					and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
				</cfif>
		</cfquery>
		<p>
			Marked.  <a href="browseBulk.cfm?enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#&uuid=#uuid#&catnum=#catnum#">Back to table</a>
		</p>
	</cfoutput>
</cfif>



<cfif action is "finalmassMarkToDelete">
	<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update bulkloader set status='DELETE' where collection_object_id>1000
		<cfif len(enteredby) gt 0>
			and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
		</cfif>
		<cfif  len(accn) gt 0>
			and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
		</cfif>
		<cfif len(colln) gt 0>
			and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
		</cfif>
		<cfif len(collection_object_id) gt 0>
			and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" list="true">)
		</cfif>
		<cfif len(uuid) gt 0>
			and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
		</cfif>
		<cfif len(catnum) gt 0>
			and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
		</cfif>
	</cfquery>
	<p>
		Marked.  <a href="browseBulk.cfm?enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#&uuid=#uuid#&catnum=#catnum#">Back to table</a>
	</p>
	</cfoutput>
</cfif>




<!------------------------------------------------------------------------->
<cfif action is "massMarkToDelete">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				enteredby,
				guid_prefix,
				taxon_name,
				status,
				count(*) c
			from bulkloader where collection_object_id>1000
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
			</cfif>
			<cfif len(collection_object_id) gt 0>
				and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" list="true">)
			</cfif>
			<cfif len(uuid) gt 0>
				and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
			</cfif>
			<cfif len(catnum) gt 0>
				and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
			</cfif>
			group by
			enteredby,
				guid_prefix,
				taxon_name,
				status
		</cfquery>
		<p>
			Please review the table below. If all looks correct, <a href="browseBulk.cfm?action=finalmassMarkToDelete&enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#&uuid=#uuid#&catnum=#catnum#">click here</a> to proceed to set status to DELETE for all listed records.
		</p>
		<table border>
			<tr>
				<th>Count</th>
				<th>Enteredby</th>
				<th>Collection</th>
				<th>status</th>
				<th>ID</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#c#</td>
					<td>#enteredby#</td>
					<td>#guid_prefix#</td>
					<td>#status#</td>
					<td>#taxon_name#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------->
<cfif action is "massmarkToload">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				enteredby,
				guid_prefix,
				taxon_name,
				status,
				count(*) c
			from bulkloader where collection_object_id>1000
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
			</cfif>
			<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
				and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" list="true">)
			</cfif>
			<cfif isdefined("uuid") and len(uuid) gt 0>
				and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
			</cfif>
			<cfif isdefined("catnum") and len(catnum) gt 0>
				and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
			</cfif>
			group by
			enteredby,
				guid_prefix,
				taxon_name,
				status
		</cfquery>
		<p>
			Please review the table below. If all looks correct, you may proceed in two ways:
			<ul>
				<li>
					Mark only "core" data in the catalog record bulkloader to load:
					<a href="browseBulk.cfm?action=finalMassLoad&enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#&uuid=#uuid#&catnum=#catnum#&ld=autoload_core">
						<input type="button" class="lnkBtn" value="autoload_core">
					</a>
				</li>
				<li>
					In addition to marking "core" data in the catalog record bulkloader to load,
					at load also mark any linked (via UUID) data in component loaders to load:
					<a href="browseBulk.cfm?action=finalMassLoad&enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#&uuid=#uuid#&catnum=#catnum#&ld=autoload_extras">
						<input type="button" class="lnkBtn" value="autoload_extras">
					</a>
				</li>
		</p>
		<table border>
			<tr>
				<th>Count</th>
				<th>Enteredby</th>
				<th>Collection</th>
				<th>status</th>
				<th>ID</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#c#</td>
					<td>#enteredby#</td>
					<td>#guid_prefix#</td>
					<td>#status#</td>
					<td>#taxon_name#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>


<cfif action is "savePrefs">
<!---
insert into cf_de_approve_settings (username,usr_fields) values ('#session.username#',<cfqueryparam cfsqltype="CF_SQL_varchar" value="{#usrcls#}" >)

insert into cf_de_approve_settings (username,usr_fields) values ('#session.username#',<cfqueryparam cfsqltype="CF_SQL_array" value="{#usrcls#}" >)

--->
	<cfquery name="flush" datasource="uam_god">
		delete from cf_de_approve_settings where username='#session.username#'
	</cfquery>
	<cfquery name="ins" datasource="uam_god">
		insert into cf_de_approve_settings (username,usr_fields) values ('#session.username#','{#usrcls#}')
	</cfquery>
	<cflocation url="browseBulk.cfm?action=customize" addtoken="false">
</cfif>


<!---------------------------------------------------------------------------------------------->
<cfif action is "showExtras">

	deprecated
	<!----
<cfoutput>
	<cfset de = CreateObject("component","component.DataEntry")>

	<cfset sql = "select * from bulkloader where 1=1">
	<cfif isdefined("enteredby") and len(enteredby) gt 0>
		<cfset sql = "#sql# AND enteredby IN (#enteredby#)">
	</cfif>
	<cfif isdefined("accn") and len(accn) gt 0>
		<cfset sql = "#sql# AND accn IN (#accn#)">
	</cfif>
	<cfif isdefined("colln") and len(colln) gt 0>
		<cfset sql = "#sql# AND guid_prefix IN (#colln#)">
	</cfif>
	<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
		<cfset sql = "#sql# AND collection_object_id IN (#collection_object_id#)">
	</cfif>
	<cfif isdefined("uuid") and len(uuid) gt 0>
		<cfset sql = "#sql# AND uuid IN (#colln#)">
	</cfif>
	<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
		<cfset sql = "#sql# AND collection_object_id IN (#collection_object_id#)">
	</cfif>


	<cfset sql="#sql# and collection_object_id>500  limit 500">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">


	<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">



		#preservesinglequotes(sql)#
	</cfquery>



	<cfquery name="cNames" datasource="uam_god">
		select column_name from information_schema.columns where table_name='bulkloader' and
		column_name not like '%$%' and
		column_name != 'collection_object_id'
		--order by internal_column_id
	</cfquery>

	<!--- add "special" stuff at known positions --->
	<cfset clist="extras,collection_object_id,#valuelist(cNames.column_name)#">

	<div class="blTabDiv">
		<table border id="t" class="sortable">
			<tr>
				<cfloop list="#clist#" index="column_name">
					<th>#column_name#</th>
				</cfloop>
			</tr>
			<cfloop query="data">
				<tr>
					<cfquery name="thisRec" dbtype="query">
						select * from data where collection_object_id=#data.collection_object_id#
					</cfquery>
					<td>
						<cftry>
							<cfset r=de.checkExtendedData(data.collection_object_id)>


							<cfif IsStruct(r)>

								<cfloop collection="#r#" item="key" >
									<br>#key#
									<div style="margin-left:1em;">
										<cfloop collection="#r[key]#" item="key2" >
											<cfif len(r[key][key2]) gt 0>
												<div>
													#key2#: #r[key][key2]#
												</div>
											</cfif>
										</cfloop>
									</div>
								</cfloop>

							<cfelse>
								#r#
							</cfif>
							<cfcatch>

								<cfdump var=#cfcatch#>
								Something bad happened. Adobe may have converted "no" to FALSE or similar,which breaks everything. Click
								collection_object_id to bypass this stupid conversion failure.
							</cfcatch>
						</cftry>
					</td>
					<td>
						<a href="/DataEntry.cfm?action=edit&ImAGod=yes&CFGRIDKEY=#data.collection_object_id#">Edit #data.collection_object_id#</a>
					</td>
					<cfloop query="cNames">
						<cfset thisData = evaluate("thisRec." & cNames.column_name)>
						<td>#thisData#</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
	</div>
</cfoutput>
---->
</cfif>




<cfif action is "loadAll">

	deprecated
	<!----
	<cfoutput>

		<cfset sqlstr="UPDATE bulkloader SET status = NULL WHERE collection_object_id > 500" >
		<cfif len(enteredby) gt 0>
			<cfset sqlstr = "#sqlstr# AND enteredby IN ( #enteredby# )">
		</cfif>
		<cfif len(accn) gt 0>
			<cfset sqlstr = "#sqlstr# AND accn IN ( #accn# )">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sqlstr = "#sqlstr# AND guid_prefix IN ( #colln# )">
		</cfif>
		<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
			<cfset sqlstr = "#sqlstr# AND collection_object_id IN ( #collection_object_id# )">
		</cfif>

		<cfif isdefined("uuid") and len(uuid) gt 0>
			<cfset sqlstr = "#sqlstr# AND guid_prefix IN ( #colln# )">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sqlstr = "#sqlstr# AND guid_prefix IN ( #colln# )">
		</cfif>

		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(sqlstr)#
		</cfquery>
		<cflocation url="browseBulk.cfm?action=#returnAction#&enteredby=#enteredby#&accn=#accn#&colln=#colln#&collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
	---->
</cfif>
<cfif action is "download">

	<cfoutput>
		<cfquery name="cNames" datasource="uam_god">
				select column_name from information_schema.columns where table_name='bulkloader'
				and
		column_name not like '%$%'
		</cfquery>
		<!---
		--			order by internal_column_id
		<cfset sql = "select * from bulkloader where 1=1">
		<cfif len(enteredby) gt 0>
			<cfset sql = "#sql# AND enteredby IN ( 	<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true">">
		</cfif>
		<cfif len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND guid_prefix IN (#colln#)">
		</cfif>

			<cfset sql = "#sql# AND collection_object_id>500">



---->


		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from bulkloader where collection_object_id>500
			<cfif len(enteredby) gt 0>
				AND enteredby IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true"> )
			</cfif>
			<cfif len(accn) gt 0>
				AND accn IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true"> )
			</cfif>
			<cfif len(colln) gt 0>
				AND guid_prefix IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true"> )
			</cfif>
			<cfif len(collection_object_id) gt 0>
				AND collection_object_id IN ( <cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" null="#Not Len(Trim(collection_object_id))#" list="true"> )
			</cfif>
			<cfif len(uuid) gt 0>
				AND uuid IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" null="#Not Len(Trim(uuid))#" list="true"> )
			</cfif>
			<cfif len(catnum) gt 0>
				AND cat_num IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" null="#Not Len(Trim(catnum))#" list="true"> )
			</cfif>
		</cfquery>
		<cfset fname = "BulkPendingData.csv">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=data,Fields=valuelist(cNames.column_name))>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#fname#"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=#fname#" addtoken="false">
		<a href="/download/#fname#">Click here if your file does not automatically download.</a>
	</cfoutput>
</cfif>


<!----------------------------------------------------------->
<cfif action is "runSQLUp">
	<cfoutput>
		<cfif not isdefined("uc1") or not isdefined("uv1") or len(uc1) is 0 or len(uv1) is 0>
			Not enough information. <cfabort>
		</cfif>
		<cfif uv1 is "NULL">
	        <cfset sql = "update bulkloader set #uc1# = NULL where 1=1">
	    <cfelse>
	        <cfset sql = "update bulkloader set #uc1# = '#uv1#' where 1=1">
	    </cfif>
		<cfif isdefined("enteredby") and len(enteredby) gt 0>
			<cfset sql = "#sql# AND enteredby IN (#ListQualify(enteredby,'''')#)">


		</cfif>
		<cfif isdefined("accn") and len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#ListQualify(accn,'''')#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND guid_prefix IN (#ListQualify(colln,'''')#)">
		</cfif>
		<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
			<cfset sql = "#sql# AND #c1# #op1# ">
			<cfif op1 is "=">
				<cfset sql = "#sql# '#v1#'">
			<cfelseif op1 is "like">
				<cfset sql = "#sql# '%#v1#%'">
			<cfelseif op1 is "in">
				<cfset sql = "#sql# ('#replace(v1,",","','","all")#')">
			<cfelseif op1 is "between">
				<cfset dash = find("-",v1)>
				<cfset f = left(v1,dash-1)>
				<cfset t = mid(v1,dash+1,len(v1))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>
		</cfif>
		<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
			<cfset sql = "#sql# AND #c2# #op2# ">
			<cfif op2 is "=">
				<cfset sql = "#sql# '#v2#'">
			<cfelseif op2 is "like">
				<cfset sql = "#sql# '%#v2#%'">
			<cfelseif op2 is "in">
				<cfset sql = "#sql# ('#replace(v2,",","','","all")#')">
			<cfelseif op2 is "between">
				<cfset dash = find("-",v2)>
				<cfset f = left(v2,dash-1)>
				<cfset t = mid(v2,dash+1,len(v2))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>
		</cfif>
		<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
			<cfset sql = "#sql# AND #c3# #op3# ">
			<cfif #op3# is "=">
				<cfset sql = "#sql# '#v3#'">
			<cfelseif op3 is "like">
				<cfset sql = "#sql# '%#v3#%'">
			<cfelseif op3 is "in">
				<cfset sql = "#sql# ('#replace(v3,",","','","all")#')">
			<cfelseif op3 is "between">
				<cfset dash = find("-",v3)>
				<cfset f = left(v3,dash-1)>
				<cfset t = mid(v3,dash+1,len(v3))>
				<cfset sql = "#sql# #f# and #t# ">
			</cfif>
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(sql)#
		</cfquery>
		<cfset rUrl="browseBulk.cfm?action=sqlTab&enteredby=#enteredby#">
		<cfif isdefined("accn") and len(accn) gt 0>
			<cfset rUrl="#rUrl#&accn=#accn#">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset rUrl = "#rUrl#&colln=#colln#">
		</cfif>
		<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
			<cfset rUrl="#rUrl#&c1=#c1#&op1=#op1#&v1=#v1#">
		</cfif>
		<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
			<cfset rUrl="#rUrl#&c2=#c2#&op2=#op2#&v2=#v2#">
		</cfif>
		<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
			<cfset rUrl="#rUrl#&c3=#c3#&op3=#op3#&v3=#v3#">
		</cfif>
		<cflocation url="#rUrl#" addtoken="false">
	</cfoutput>
</cfif>







<!----------------------------------------------------------->
<cfif action is "sqlTab">
<script src="/includes/sorttable.js"></script>
<cfoutput>
	<cfset bakurl="browseBulk.cfm?">
	<cfset sql = "select * from bulkloader where 1=1">
	<cfif isdefined("enteredby") and len(enteredby) gt 0>
		<cfset sql = "#sql# AND enteredby IN (#ListQualify(enteredby,'''')#)">
		<cfset bakurl=bakurl & "&enteredby=#enteredby#">
	</cfif>



	<cfif isdefined("accn") and len(accn) gt 0>
		<cfset sql = "#sql# AND accn IN (#ListQualify(accn,'''')#)">
				<cfset bakurl=bakurl & "&accn=#accn#">

	</cfif>
	<cfif isdefined("colln") and len(colln) gt 0>
		<cfset sql = "#sql# AND guid_prefix IN (#ListQualify(colln,'''')#)">
				<cfset bakurl=bakurl & "&colln=#colln#">
	</cfif>

	<a href="#bakurl#">back to grid</a>
	
	<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
		<cfset sql = "#sql# AND #c1# #op1# ">
		<cfif #op1# is "=">
			<cfset sql = "#sql# '#v1#'">
		<cfelseif op1 is "like">
			<cfset sql = "#sql# '%#v1#%'">
		<cfelseif op1 is "in">
			<cfset sql = "#sql# ('#replace(v1,",","','","all")#')">
		<cfelseif op1 is "between">
			<cfset dash = find("-",v1)>
			<cfset f = left(v1,dash-1)>
			<cfset t = mid(v1,dash+1,len(v1))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>
	</cfif>
	<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
		<cfset sql = "#sql# AND #c2# #op2# ">
		<cfif #op2# is "=">
			<cfset sql = "#sql# '#v2#'">
		<cfelseif op2 is "like">
			<cfset sql = "#sql# '%#v2#%'">
		<cfelseif op2 is "in">
			<cfset sql = "#sql# ('#replace(v2,",","','","all")#')">
		<cfelseif op2 is "between">
			<cfset dash = find("-",v2)>
			<cfset f = left(v2,dash-1)>
			<cfset t = mid(v2,dash+1,len(v2))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>
	</cfif>
	<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
		<cfset sql = "#sql# AND #c3# #op3# ">
		<cfif op3 is "=">
			<cfset sql = "#sql# '#v3#'">
		<cfelseif op3 is "like">
			<cfset sql = "#sql# '%#v3#%'">
		<cfelseif op3 is "in">
			<cfset sql = "#sql# ('#replace(v3,",","','","all")#')">
		<cfelseif op3 is "between">
			<cfset dash = find("-",v3)>
			<cfset f = left(v3,dash-1)>
			<cfset t = mid(v3,dash+1,len(v3))>
			<cfset sql = "#sql# #f# and #t# ">
		</cfif>
	</cfif>
	<cfset sql="#sql# and collection_object_id>500  limit 500">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>
	<cfquery name="cNames" datasource="uam_god">
			select column_name from information_schema.columns where table_name='bulkloader' and
		column_name not like '%$%'
	</cfquery>
	<div style="background-color:##C0C0C0; font-size:smaller;">
		Use the top form to filter the table to the records you are interested in. All values are ANDed together. Everything is case-sensitive.
		You must provide all three values for the filter to apply.
		<br>Then use the bottom form to update them. Values are case sensitive. There is no control here - you can easily update such
		that records will never load. Don't.
		<br>Updates will affect only the records visible in the table below, and ALL records in the table will receive the same updates.
		<br>Click the table headers to sort.
		<br>
		Operator values:
		<ul>
			<li>=: single case-sensitive exact match ("something"-->"<strong>something</strong>")</li>
			<li>like: partial string match ("somet" --> "<strong>somet</strong>hing", "got<strong>somet</strong>oo", "<strong>somet</strong>ime", etc.)</li>
			<li>in: comma-delimited list ("one,two" --> "<strong>one</strong>" OR "<strong>two</strong>")</li>
			<li>between: range ("1-5" --> "1,2...5") Works only when ALL values are numeric (not only those you see in the current table)</li>
		</ul>
		<p>
			NOTE: This form will load at most 500 records.
		</p>
		<p>
			NOTE: This form does not accept all variables from the grid view; refilter as necessary.
		</p>
		<p>
			Set status to DELETE to delete.
		</p>
	</div>
	<form name="filter" method="post" action="browseBulk.cfm">
		<input type="hidden" name="action" value="sqlTab">
		<input type="hidden" name="enteredby" value="#enteredby#">
		<cfif isdefined("accn") and len(accn) gt 0>
			<input type="hidden" name="accn" value="#accn#">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<input type="hidden" name="colln" value="#colln#">
		</cfif>
		<h2>Create Filter:</h2>
		<table border>
			<tr>
				<th>
					Column
				</th>
				<th>Operator</th>
				<th>Value</th>
			</tr>
			<tr>
				<td>enteredby</td>
				<td>IN</td>
				<td>#enteredby#</td>
			</tr>
			<tr>
				<td>accn</td>
				<td>IN</td>
				<td>#accn#</td>
			</tr>
			<tr>
				<td>colln</td>
				<td>IN</td>
				<td>#colln#</td>
			</tr>
			<tr>
				<td>
					<select name="c1" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c1") and c1 is column_name> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op1" size="1">
						<option <cfif isdefined("op1") and op1 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op1") and op1 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op1") and op1 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op1") and op1 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v1" <cfif isdefined("v1")> value="#v1#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td>
					<select name="c2" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c2") and #c2# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op2" size="1">
						<option <cfif isdefined("op2") and op2 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op2") and op2 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op2") and op2 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op2") and op2 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v2" <cfif isdefined("v2")> value="#v2#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td>
					<select name="c3" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option
								<cfif isdefined("c3") and #c3# is #column_name#> selected="selected" </cfif>value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<select name="op3" size="1">
						<option <cfif isdefined("op3") and op3 is "="> selected="selected" </cfif>value="=">=</option>
						<option <cfif isdefined("op3") and op3 is "like"> selected="selected" </cfif>value="like">like</option>
						<option <cfif isdefined("op3") and op3 is "in"> selected="selected" </cfif>value="in">in</option>
						<option <cfif isdefined("op3") and op3 is "between"> selected="selected" </cfif>value="between">between</option>
					</select>
				</td>
				<td>
					<input type="text" name="v3" <cfif isdefined("v3")> value="#v3#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" value="Filter">
				</td>
			</tr>
		</table>
	</form>
	<h2>Update data in table below:</h2>
	<form name="up" method="post" action="browseBulk.cfm">
		<input type="hidden" name="action" value="runSQLUp">
		<input type="hidden" name="enteredby" value="#enteredby#">
		<cfif isdefined("accn") and len(accn) gt 0>
			<input type="hidden" name="accn" value="#accn#">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<input type="hidden" name="colln" value="#colln#">
		</cfif>
		<cfif isdefined("c1") and len(#c1#) gt 0 and isdefined("op1") and len(#op1#) gt 0 and isdefined("v1") and len(#v1#) gt 0>
			<input type="hidden" name="c1" value="#c1#">
			<input type="hidden" name="op1" value="#op1#">
			<input type="hidden" name="v1" value="#v1#">
		</cfif>
		<cfif isdefined("c2") and len(#c2#) gt 0 and isdefined("op2") and len(#op2#) gt 0 and isdefined("v2") and len(#v2#) gt 0>
			<input type="hidden" name="c2" value="#c2#">
			<input type="hidden" name="op2" value="#op2#">
			<input type="hidden" name="v2" value="#v2#">
		</cfif>
		<cfif isdefined("c3") and len(#c3#) gt 0 and isdefined("op3") and len(#op3#) gt 0 and isdefined("v3") and len(#v3#) gt 0>
			<input type="hidden" name="c3" value="#c3#">
			<input type="hidden" name="op3" value="#op3#">
			<input type="hidden" name="v3" value="#v3#">
		</cfif>
		<table border>
			<tr>
				<th>
					Column
				</th>
				<th>Update To</th>
				<th>Value</th>
			</tr>
			<tr>
				<td>
					<select name="uc1" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					-->
				</td>
				<td>
					<input type="text" name="uv1" id="uv1" size="50">
                    <span class="infoLink" onclick="document.getElementById('uv1').value='NULL';">NULL</span>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" value="Update">
				</td>
			</tr>
		</table>
	</form>

	<div class="blTabDiv">
		<table border id="t" class="sortable">
			<tr>
			<cfloop query="cNames">
				<th>#column_name#</th>
			</cfloop>
			<cfloop query="data">
				<tr>
				<cfquery name="thisRec" dbtype="query">
					select * from data where collection_object_id=#data.collection_object_id#
				</cfquery>
				<cfloop query="cNames">
					<cfset thisData = evaluate("thisRec." & cNames.column_name)>
					<td>#thisData#</td>
				</cfloop>
				</tr>
			</cfloop>
			</tr>
		</table>
	</div>
</cfoutput>
</cfif>
<!-------------------------->
<cfif #action# is "saveGridUpdate">
<cfoutput>
<cfquery name="cNames" datasource="uam_god">
	select column_name from information_schema.columns where table_name='bulkloader' and
		column_name not like '%$%'
</cfquery>
<cfset ColNameList = valuelist(cNames.column_name)>
<cfset GridName = "blGrid">
<cfset numRows = #ArrayLen(form.blGrid.rowstatus.action)#>
<p></p>there are	#numRows# rows updated
<!--- loop for each record --->
<cfloop from="1" to="#numRows#" index="i">
	<!--- and for each column --->
	<cfset thisCollObjId = evaluate("Form.#GridName#.collection_object_id[#i#]")>
	<cfset sql ='update BULKLOADER SET collection_object_id = #thisCollObjId#'>
	<cfloop index="ColName" list="#ColNameList#">
		<cfset oldValue = evaluate("Form.#GridName#.original.#ColName#[#i#]")>
		<cfset newValue = evaluate("Form.#GridName#.#ColName#[#i#]")>
		<cfif #oldValue# neq #newValue#>
			<cfset sql = "#sql#, #ColName# = '#newValue#'">
		</cfif>
	</cfloop>

		<cfset sql ="#sql# WHERE collection_object_id = #thisCollObjId#">
	<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>
</cfloop>
<cflocation url="browseBulk.cfm?action=#returnAction#&enteredby=#enteredby#&accn=#accn#&colln=#colln#" addtoken="false">
</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif #action# is "upBulk">
<cfoutput>
	<cfif len(#status#) gt 0 and
		len(#column_name#) gt 0 and
		len(#tValue#) gt 0>
		<cfset sql="UPDATE bulkloader SET status = ">
		<cfif #status# is "NULL">
			<cfset sql="#sql# NULL">
		<cfelse>
			<cfset sql="#sql# '#status#'">
		</cfif>
			<cfset sql="#sql# WHERE #column_name#	=
			'#trim(tValue)#'">
		<cfif len(enteredby) gt 0>
			<cfset sql = "#sql# AND enteredby IN (#enteredby#)">
		</cfif>
		<cfif len(accn) gt 0>
			<cfset sql = "#sql# AND accn IN (#accn#)">
		</cfif>
		<cfif isdefined("colln") and len(colln) gt 0>
			<cfset sql = "#sql# AND guid_prefix IN (#colln#)">
		</cfif>
			#preservesinglequotes(sql)#
		<!---

		<cfabort>
		--->
		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(sql)#
		</cfquery>
	</cfif>

<cflocation url="browseBulk.cfm?action=viewTable&enteredby=#enteredby#&accn=#accn#&colln=#colln#" addtoken="false">

</cfoutput>
</cfif>
<!-------------------------------------------------------------->



<!----------------------------------------------------------->
<cfif action is "saveEditTable">
<cfoutput>


	<cfquery name="cNames" datasource="uam_god">
		select column_name from information_schema.columns where table_name='bulkloader' and
		column_name not like '%$%' and
		column_name!='collection_object_id' and
		column_name!='enteredby' and
		column_name!='guid_prefix'
	</cfquery>

	<cfloop list="#form.fieldnames#" index="fld">
		<br>fld===#fld#
	</cfloop>

	<cfloop query="cNames">
		update bulkloader set
		<cfif isdefined("form.#column_name#")>
			<br>#column_name#
		<cfelse>
			<brNO #column_name#
		</cfif>
	</cfloop>

	<cfdump var=#form#>

</cfoutput>
</cfif>


<!----------
<!----------------------------------------------------------->
<cfif action is "editTable">
	<style>
		tr.saving{background-color:#dbd9cc;}
		tr.goodsave{background-color:#c2e691;}
		tr.badsave{background-color:#eb0e19;}
		tr.highlighted{
			background-color:#e9f505;
		}
		tr.notSaved{background-color:#fffc45;}

	</style>
	<script>
		function denullify(){
			$('#datatable th').each(function(i) {
    			var remove = 0;
    			var tds = $(this).parents('table').find('tr td:nth-child(' + (i + 1) + ')')
   				tds.each(function(j) {
   					//if (this.innerHTML == '') remove++;
   					//console.log(this.innerHTML);
   					//console.log(this);
   					//console.log(this.firstChild.value);
   					if (typeof this.firstChild.value !== 'undefined'){
   						//console.log('has');
   						if (this.firstChild.value.length==0){
   							//console.log('noval');
   							remove++;
   						}
   					}
   				});

			    if (remove == ($('#datatable tr').length - 1)) {
			    	//console.log('hiding');
			        $(this).hide();
			        tds.hide();
			    }
			});
		}



		function toggle(cid){
			if ($("#row_"+cid).hasClass('highlighted')){
				$("#row_"+cid).removeClass();
			} else {
				$("#row_"+cid).removeClass().addClass('highlighted');
			}
		}
		function changedVal(cid){
			$("#row_"+cid).removeClass().addClass('notSaved');
		}
		function saveEdits(cid){
			console.log('saveEdits');
			console.log(cid);
			$("#row_"+cid).removeClass().addClass('saving');
			$.ajax({
				url: "/component/Bulkloader.cfc",
				type: "POST",
				dataType: "json",
				data: {
					method:  "saveEditNoCheck",
					q: $('#f_'+cid).serialize(),
					returnformat : "json",
					queryformat : 'column'
			},
			success: function(r) {
				if (r.STATUS=='SUCCESS') {
					$("#row_"+cid).removeClass().addClass('goodsave');
					console.log('good save');
				} else {
					$("#row_"+cid).removeClass().addClass('badsave');
					alert('FAIL: ' + r.DETAIL);
				}
			},
			error: function (xhr, textStatus, errorThrown){
			    // show error
			    alert(errorThrown);
			  }
			});
		}
	</script>
<p>
Set status to DELETE to delete records. Use the SQL option if you want to delete records in batch.
</p>
<cfoutput>
	<!--- see if we can recover this stuff; it's quoted for old forms --->
	<cfif isdefined("enteredby") and len(enteredby) gt 0>
		<cfset fltr_enteredby=replace(enteredby,"'","","all")>
	</cfif>
	<cfif isdefined("accn") and len(accn) gt 0>
		<cfset fltr_accn=replace(accn,"'","","all")>
	</cfif>
	<cfif isdefined("colln") and len(colln) gt 0>
		<cfset fltr_colln=replace(colln,"'","","all")>
	</cfif>

	<cfquery name="ctAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				accn as acn
			from
				bulkloader
			group by
				accn
			order by
				accn
		</cfquery>
		<cfquery name="ctColln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				guid_prefix con
			from
				bulkloader
			group by
				guid_prefix
			order by guid_prefix
		</cfquery>
		<cfquery name="ctEnteredby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				enteredby as eby
			from
				bulkloader
			group by
				enteredby
			order by
				enteredby
		</cfquery>

		<!----
		pull columns we need, preserve table order
	---->
	<cfquery name="cNames" datasource="uam_god">
		select
			column_name
		from
			information_schema.columns
		where
			table_name='bulkloader' and
			column_name not like '%$%' and
			column_name !='collection_id' and
			column_name !='entered_agent_id' and
			column_name !='collection_object_id'
	</cfquery>


		<cfparam name="fltr_enteredby" default="">
		<cfparam name="fltr_accn" default="">
		<cfparam name="fltr_colln" default="">
		<cfparam name="fltr_sort" default="collection_object_id">
		<cfparam name="fltr_limit" default="10">
		<cfparam name="fltr_pg" default="1">


		<table>
			<tr>
				<td width="50%">
					<form name="f" method="post" action="browseBulk.cfm">
					<table>
						<tr>
							<td align="center">
								<input type="hidden" name="action" value="editTable" />
								<label for="enteredby">Entered By</label>
								<select name="fltr_enteredby" multiple="multiple" size="12" id="fltr_enteredby">
									<option value="" >All</option>
									<cfloop query="ctEnteredby">
										<option <cfif listfind(fltr_enteredby,eby)> selected="selected" </cfif> value="#eby#">#eby#</option>
									</cfloop>
								</select>
							</td>

							<td align="center">
								<label for="accn">Accession</label>
								<select name="fltr_accn" multiple="multiple" size="12" id="fltr_accn">
									<option value="" >All</option>
									<cfloop query="ctAccn">
										<option <cfif listfind(fltr_accn,acn)> selected="selected" </cfif> value="#acn#">#acn#</option>
									</cfloop>
								</select>
							</td>
							<td align="center">
								<label for="colln">Collection</label>
								<select name="fltr_colln" multiple="multiple" size="12" id="fltr_colln">
									<option value="">All</option>
									<cfloop query="ctColln">
										<option <cfif listfind(fltr_colln,con)> selected="selected" </cfif> value="#con#">#con#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="fltr_sort">Sort</label>
								<select name="fltr_sort" multiple="multiple" size="12" id="fltr_sort">
									<option <cfif listfind(fltr_sort,"collection_object_id")> selected="selected" </cfif> value="collection_object_id">collection_object_id</option>
									<cfloop query="cNames">
										<option <cfif listfind(fltr_sort,column_name)> selected="selected" </cfif> value="#column_name#">#column_name#</option>
									</cfloop>
								</select>

							</td>
							<td>
								<label for="fltr_limit">PageSize</label>
								<select name="fltr_limit"  size="1" id="fltr_limit">
									<option <cfif fltr_limit is 5> selected="selected" </cfif>value="5">5</option>
									<option <cfif fltr_limit is 10> selected="selected" </cfif>value="10">10</option>
									<option <cfif fltr_limit is 25> selected="selected" </cfif>value="25">25</option>
									<option <cfif fltr_limit is 50> selected="selected" </cfif>value="50">50</option>
									<option <cfif fltr_limit is 100> selected="selected" </cfif>value="100">100</option>
								</select>

							</td>
							<td>
								<label for="fltr_pg">Page</label>
								<select name="fltr_pg"  size="1" id="fltr_pg">
									<cfloop from="1" to="30" index="i">
										<option <cfif fltr_pg is i> selected="selected" </cfif>value="#i#">#i#</option>
									</cfloop>
								</select>

							</td>
							<td>
								<label for="fltr_pg">Requery</label>
								<input type="submit" class="lnkBtn" value="click to filter results">
							</td>
						</tr>

					</table>
					</form>




	<cfset sql = "select collection_object_id,bulkloaderHasExtraData(collection_object_id) hasExtraData,#valuelist(cNames.column_name)# from bulkloader where 1=1">
	<cfif isdefined("fltr_enteredby") and len(fltr_enteredby) gt 0>
		<cfset sql = "#sql# AND enteredby IN ( #ListQualify(fltr_enteredby,'''')# )">
	</cfif>
	<cfif isdefined("fltr_accn") and len(fltr_accn) gt 0>
		<cfset sql = "#sql# AND accn IN (#ListQualify(fltr_accn,'''')# )">
	</cfif>
	<cfif isdefined("fltr_colln") and len(fltr_colln) gt 0>
		<cfset sql = "#sql# AND guid_prefix IN ( #ListQualify(fltr_colln,'''')#)">
	</cfif>


	<cfset q_offset=(fltr_limit*fltr_pg)-fltr_limit>
	<cfset sql="#sql# and collection_object_id>500 order by #fltr_sort# limit #fltr_limit# offset #q_offset#">


	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>




	<cfset sql = "select count(*) c from bulkloader where 1=1">
	<cfif isdefined("fltr_enteredby") and len(fltr_enteredby) gt 0>
		<cfset sql = "#sql# AND enteredby IN ( #ListQualify(fltr_enteredby,'''')# )">
	</cfif>
	<cfif isdefined("fltr_accn") and len(fltr_accn) gt 0>
		<cfset sql = "#sql# AND accn IN (#ListQualify(fltr_accn,'''')# )">
	</cfif>
	<cfif isdefined("fltr_colln") and len(fltr_colln) gt 0>
		<cfset sql = "#sql# AND guid_prefix IN ( #ListQualify(fltr_colln,'''')#)">
	</cfif>
	<cfset sql = "#sql# AND collection_object_id>500">
	<cfquery name="cnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>


<!--------
see email from jd - this isn't safe here
	<br><a href="browseBulk.cfm?action=loadAll&enteredby=#fltr_enteredby#&accn=#fltr_accn#&colln=#fltr_colln#&returnAction=editTable">Mark all #cnt.c# records which match filter criteria to load</a>
---------------->
<br>Use <a href="/Bulkloader/datatables.cfm">datatables</a> for load-all functionality
	<br><span class="likeLink" onclick="denullify()">hide NULL columns</span>
	<div class="blTabDiv">
		<table border id="datatable">
			<tr>
				<th>controls</th>
				<th>xtra</th>
				<cfloop query="cNames">
					<th>#column_name#</th>
				</cfloop>
				<th>controls</th>
			</tr>
			<cfloop query="data">
			<tr id="row_#data.collection_object_id#">
		        <td nowrap>
			        <form id="f_#data.collection_object_id#" >
				        <input type="hidden" name="action" value="saveEditTable">
				        <input type="hidden" name="collection_object_id" value="#data.collection_object_id#">
				        <input type="button" onclick="saveEdits(#data.collection_object_id#)"  value="Save" class="savBtn">
						<a target="_blank" href="/DataEntry.cfm?action=edit&ImAGod=yes&collection_object_Id=#data.collection_object_id#">Edit</a>
						<span class="likeLink" id="tgl_#data.collection_object_id#" onclick="toggle(#data.collection_object_id#)">Highlight</span>
					</form>
				</td>
				<cfquery name="thisRec" dbtype="query">
					select * from data where collection_object_id=#data.collection_object_id#
				</cfquery>
				<td>
					<a href="browseBulk.cfm?action=showExtras&collection_object_id=#data.collection_object_id#">
						<cfif thisRec.hasExtraData gt 0>yes<cfelse>no</cfif>
					</a>
				</td>
				<cfloop query="cNames">
					<cfset thisData = evaluate("thisRec." & cNames.column_name)>
					<cfif cNames.column_name is 'collection_object_id'>
						<cfset thisDisp=''>
					<cfelseif cNames.column_name is 'enteredby' or cNames.column_name is 'guid_prefix'  or cNames.column_name is 'enteredtobulkdate'>
						<!--- need to display, don't allow edit --->
						<cfset thisDisp=thisData>
					<cfelse>
						<cfset thisDisp='<input  onChange="changedVal(#data.collection_object_id#)" form="f_#data.collection_object_id#" type="text" name="#cNames.column_name#" value="#thisData#">'>
					</cfif>
					<td>#thisDisp#</td>
				</cfloop>
				<td><input form="f_#data.collection_object_id#" type="button" onclick="saveEdits(#data.collection_object_id#)" value="save row" class="savBtn"></td>
				</tr>
			</cfloop>
			</tr>
		</table>
	</div>
</cfoutput>
</cfif>
------>
<cfinclude template="/includes/_footer.cfm">
