<cfinclude template="/includes/_header.cfm">
<cfset title="Browse/Edit Bulkloaded Data">
<!----------------------- globals ---------------------------------------->
<cfset reqdFlds="key,status,extras,enteredby">
<cfset hiddenFlds="">

<cfparam name="enteredby" default="">
<cfparam name="accn" default="">
<cfparam name="colln" default="">
<cfparam name="key" default="">
<cfparam name="uuid" default="">
<cfparam name="catnum" default="">
<cfparam name="status" default="">
<!----------------------- /globals ---------------------------------------->
<cfif action is "nothing">
	<link rel="stylesheet" type="text/css" href="/includes/DataTablesnojq/datatables.min.css"/>
	<script type="text/javascript" src="/includes/DataTablesnojq/datatables.min.js"></script>
	<!---- why is htis here??
	<link rel="stylesheet" type="text/css" href="/includes/style.min.css"/>
	---->
	<script>
		function addFltr(id){
			var ids=$("#key").val();
			var idary=ids.split(',');
			idary.push(id); 
			idary = idary.filter(function(e){return e}); 
			var uary = idary.filter((v, i, a) => a.indexOf(v) === i);
			var rid=uary.join(',');
			$("#key").val(rid);
		}
		function massMarkToLoad(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var key=$("#key").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var status=$("#status").val();
			var tg='browseBulk.cfm?action=massmarkToload&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&key=' + key + "&catnum=" + catnum + "&uuid=" + uuid + "&status=" + encodeURIComponent(status);
			document.location=tg;
		}
		function massMarkToDelete(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var key=$("#key").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var status=$("#status").val();
			var tg='browseBulk.cfm?action=massMarkToDelete&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&key=' + key + "&catnum=" + catnum + "&uuid=" + uuid + "&status=" + encodeURIComponent(status);
			document.location=tg;
		}
		function downloadThis(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			var key=$("#key").val();
			var uuid=$("#uuid").val();
			var catnum=$("#catnum").val();
			var status=$("#status").val();
			var tg='browseBulk.cfm?action=download&enteredby=' + e + '&accn=' + encodeURIComponent(a) + '&colln=' + c + '&key=' + key + "&catnum=" + catnum + "&uuid=" + uuid + "&status=" + encodeURIComponent(status);
			document.location=tg;
		}
		function sqltab(){
			var e=$("#enteredby").val().join(',');
			var a=$("#accn").val().join(',');
			var c=$("#colln").val().join(',');
			// this purposefully does not include key, uuid, or catnum, or status
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
		<div class="alertNotification">
			Table customization detected! This can be dangerous. <a href="browseBulk.cfm?action=customize"><input type="button" class="lnkBtn" value="customize"></a>
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
		        idSrc: 'key',
 				formOptions: {
		            inline: {
        	        onBlur: 'submit'
            	}
	        },
    	    fields: [
				<cfloop list="#usrColumnList#" index="col">
					<cfif col is "enteredby" or col is "guid_prefix"  or col is "entered_to_bulk_date" or col is "extras">
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
				        	x = '<a target="_blank" href="/Bulkloader/editBulkloader.cfm?key=' + encodeURIComponent(data) + '">edit ' + data + '</a>';
				        	<!----
				        	x += '<a target="_blank" href="/DataEntry.cfm?action=edit&ImAGod=yes&key=' + encodeURIComponent(data) + '">[ old edit ]</a>';
				        	----->
				            x += '<a target="_blank" href="/Bulkloader/enter.cfm?seed_record_key=' + encodeURIComponent(data) + '"> [ enter ]</a>';
				            x += '<span class="likeLink" onclick="addFltr(\''+encodeURIComponent(data) + '\')"> [ filter ]</span>';
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
						d.key = $('##key').val().toString(),
						d.uuid = $('##uuid').val().toString(),
						d.catnum = $('##catnum').val().toString(),
						d.status = $('##status').val().toString()
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
					data.key = key;
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
										Bulkloader.key
										<br>Comma-list OK
										<br>
									</span>
									<label for="key">Key</label>
									<textarea class="smalltextarea" name="key" id="key">#key#</textarea>
									<label for="uuid">UUID</label>
									<textarea class="smalltextarea" name="uuid" id="uuid">#uuid#</textarea>

									<label for="catnum">CatNum (comma-list OK)</label>
									<textarea class="smalltextarea" name="catnum" id="catnum">#catnum#</textarea>


									<label for="status">Status (exact, case-sensitive)</label>
									<textarea class="smalltextarea" name="status" id="status">#status#</textarea>

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
					<!--- https://github.com/ArctosDB/arctos/issues/8056 --->
					<ul>
						<li>Click the edit key_XXX in the key to edit that record individually</li>
						<li>Click "enter" to seed a new record in the new data entry screen (new tab will open)</li>
						<li>Click the "filter" link to add the identifier record to the filter (<-- over there)</li>
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
<cfif action is "customize">
	<style>
		.rowsorter {
			cursor:move;
		}
		#theBtns{
			border:1px solid black;
			display: inline-flex;
			justify-content: space-between;	
			align-items: center;
			gap: 10px;
			margin:.5em;
			padding:1em;
		}

		#twocols{
			display: grid;
			grid-template-columns: 1fr 1fr;
		}

		#leftcol{
			border:1px solid black;
		}
		#rightcol{
			border:1px solid black;
		}

		#counts_ctr_dec{
			display: grid;
			grid-template-columns: 1fr 1fr;
		}

		
		#counts_ctr_dec > div {
			border:1px solid saddlebrown;
			padding:1em;
		}


	</style>
	<script>
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
			$('#spn option').each(function () {
				var text = $(this).text();
				if (text.length > 100) {
					text = text.substring(0, 100) + '...';
					$(this).text(text);
				}
			});
		});
		function toAry(cb){
			var linkOrderData= [];
			$.each($(".chk:checkbox:checked"), function(){
				linkOrderData.push(this.name);
            });
			$( "#usrcls" ).val(linkOrderData);
			$("#callback").val(cb);
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



	</script>
	<cfoutput>
		<cfquery name="cNames" datasource="uam_god">
			select * from (
			select column_name ,ordinal_position from information_schema.columns where table_name='bulkloader' and
				column_name not in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#hiddenFlds#" list="true">) and
				column_name not in  (<cfqueryparam cfsqltype="cf_sql_varchar" value="#reqdFlds#" list="true">)
			) x order by ordinal_position
		</cfquery>

		<cfquery name="usrPrefs" datasource="uam_god">
			select unnest(usr_fields) as colname from cf_de_approve_settings where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
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
				<ul>
					<li>
						<strong>Caution:</strong>You WILL NOT see unselected columns in the datatables data entry approval/edit screen, even if they have information in them; You can "approve" things that you cannot see. Values that are not selected here will not be visible to you, and can not be changed in the datatables form. Choose carefully.
					</li>
					<li>
						<strong>To Reset:</strong> Click "check none" and save to see all columns in the default order.
					</li>
					<li>
						<strong>To Order:</strong> Click "check all," order the columns, and save to see everything in the order you specify.
					</li>
				</ul>
			</div>
		</p>
		<div id="twocols">
			<div id="leftcol">
				<form id="thefrm" name="f" method="post" action="browseBulk.cfm">
					<div id="theBtns">
						<div><input type="button" onclick="chkAll()" value="check all"></div>
						<div><input type="button" onclick="chkNone()" value="check none"></div>
						<div><input class="savBtn" type="button" onclick="toAry('customize')" value="Save and return"></div>
						<div><input class="savBtn" type="button" onclick="toAry('nothing')" value="Save and exit"></div>
						<div><a href="browseBulk.cfm"><input class="qutBtn" type="button" value="Exit"></a></div>
					</div>
					<input type="hidden" name="action" value="savePrefs">
					<input type="hidden" name="callback" id="callback" value="customize">
					<input type="hidden" id="usrcls" name="usrcls">
					<table id="clastbl" border="1">
						<thead>
							<tr><th>Sort</th><th>Column</th><th>⍻</th></tr>
						</thead>
						<tbody id="sortable">
							<cfloop query="usrPrefs">
								<tr id="cell_#colname#">
									<td class="rowsorter">
										<i class="fas fa-grip-vertical" title="Drag to order"></i>
									</td>
									<td>#colname#</td>
									<td>
										<input class="chk" type="checkbox" id="#colname#" name="#colname#" checked="checked">
									</td>
								</tr>
							</cfloop>
							<cfloop query="notSelected">
								<tr id="cell_#colname#">
									<td class="rowsorter">
										<i class="fas fa-grip-vertical" title="Drag to order"></i>
									</td>
									<td>#colname#</td>
									<td>
										<input class="chk" type="checkbox" id="#colname#" name="#colname#" >
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<input class="savBtn" type="button" onclick="toAry()" value="save">
				</form>
			</div>

			<div id="rightcol">

				<cfinclude template="/Bulkloader/sharedconfig.cfm">

				<cfparam name="identifier_count" default="#bulk_otherid_count#">
				<cfparam name="identification_count" default="#bulk_identification_count#">
				<cfparam name="identification_attribute_count" default="#bulk_identification_attr_count#">
				<cfparam name="identification_determiner_count" default="#bulk_identification_detr_count#">
				<cfparam name="collector_count" default="#bulk_collector_count#">
				<cfparam name="locality_attribute_count" default="#bulk_loc_attr_count#">
				<cfparam name="event_attribute_count" default="#bulk_evt_attr_count#">
				<cfparam name="part_count" default="#bulk_part_count#">
				<cfparam name="part_attribute_count" default="#bulk_part_attr_count#">
				<cfparam name="attribute_count" default="#bulk_attr_count#">




				<h4>Counts</h4>
				<p>Set and save here, then make fine adjustments to the left.</p>
				<form name="fra" method="post" action="browseBulk.cfm">
					<input type="hidden" name="action" value="customizeRoughAdjust">
					<div id="counts_ctr_dec">
						<div>
							<label for="identifier_count">identifier_count: How many identifiers (Other IDs)?</label>
							<select name="identifier_count" id="identifier_count">
								<cfloop from="0" to="#bulk_otherid_count#" index="i">
									<option <cfif identifier_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>			
							<label for="identification_count">identification_count: How many identifications to view?</label>
							<select name="identification_count" id="identification_count">
								<cfloop from="1" to="#bulk_identification_count#" index="i">
									<option <cfif identification_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="identification_attribute_count">identification_attribute_count: How many attributes on each identification?</label>
							<select name="identification_attribute_count" id="identification_attribute_count">
								<cfloop from="0" to="#bulk_identification_attr_count#" index="i">
									<option <cfif identification_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="identification_determiner_count">identification_determiner_count: How many determiners on each identification?</label>
							<select name="identification_determiner_count" id="identification_determiner_count">
								<cfloop from="0" to="#bulk_identification_detr_count#" index="i">
									<option <cfif identification_determiner_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="collector_count">collector_count: How many collector-agents?</label>
							<select name="collector_count" id="collector_count">
								<cfloop from="0" to="#bulk_collector_count#" index="i">
									<option <cfif collector_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="locality_attribute_count">locality_attribute_count: How many locality attributes?</label>
							<select name="locality_attribute_count" id="locality_attribute_count">
								<cfloop from="0" to="#bulk_loc_attr_count#" index="i">
									<option <cfif locality_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="event_attribute_count">event_attribute_count: How many event attributes?</label>
							<select name="event_attribute_count" id="event_attribute_count">
								<cfloop from="0" to="#bulk_evt_attr_count#" index="i">
									<option <cfif event_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>		
							<label for="part_count">part_count: How many parts?</label>
							<select name="part_count" id="part_count">
								<cfloop from="0" to="#bulk_part_count#" index="i">
									<option <cfif part_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>				
							<label for="part_attribute_count">part_attribute_count: How many attributes for each part?</label>
							<select name="part_attribute_count" id="part_attribute_count">
								<cfloop from="0" to="#bulk_part_attr_count#" index="i">
									<option <cfif part_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="attribute_count">attribute_count: How many record attributes?</label>
							<select name="attribute_count" id="attribute_count">
								<cfloop from="0" to="#bulk_attr_count#" index="i">
									<option <cfif attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<input type="submit" class="savBtn" value="Save Rough Settings">
				</form>
			</div>
		</div>
	</cfoutput>
</cfif>

<!-------------------->

<cfif action is "customizeRoughAdjust">
	<cfoutput>
		<!-----------------------

			This is shared code!
			... mostly, but can't figure out how to really make it modular without adding a lot of complexity, 
				so just keep it synced up between

				* form/customizeDataEntry2.cfm
				* Bulkloader/bulkloaderBuilder.cfm


		here is barely-shared, just need a list....


		-------------------->


		<cfset flds = "">
		<cfset flds = listappend(flds,"cat_num")>
		<cfset flds = listappend(flds,"accn")>
		<cfset flds = listappend(flds,"record_type")>
		<cfset flds = listappend(flds,"guid_prefix")>
		<cfset flds = listappend(flds,"entered_to_bulk_date")>
		<cfset flds = listappend(flds,"record_remark")> 	

		<cfset flds = listappend(flds,"uuid")>
		<cfset flds = listappend(flds,"uuid_issued_by")>

		<cfloop from="1" to="#identifier_count#" index="i">
			<cfset flds = listappend(flds,"identifier_#i#_type")>
			<cfset flds = listappend(flds,"identifier_#i#_issued_by")>
			<cfset flds = listappend(flds,"identifier_#i#_value")>
			<cfset flds = listappend(flds,"identifier_#i#_relationship")>
			<cfset flds = listappend(flds,"identifier_#i#_remark")>
		</cfloop>


		<cfloop from="1" to="#identification_count#" index="i">
			<cfset flds = listappend(flds,"identification_#i#")>
			<cfset flds = listappend(flds,"identification_#i#_order")>
			<cfset flds = listappend(flds,"identification_#i#_date")>
			<cfset flds = listappend(flds,"identification_#i#_sensu_publication")>
			<cfset flds = listappend(flds,"identification_#i#_remark")>
			<cfloop from="1" to="#identification_determiner_count#" index="a">
				<cfset flds = listappend(flds,"identification_#i#_agent_#a#")>
			</cfloop>
			<cfloop from="1" to="#identification_attribute_count#" index="a">
				<cfset flds = listappend(flds,"identification_#i#_attribute_type_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_value_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_determiner_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_units_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_date_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_method_#a#")>
				<cfset flds = listappend(flds,"identification_#i#_attribute_remark_#a#")>
			</cfloop>
		</cfloop>
		<cfloop from="1" to="#collector_count#" index="i">
			<cfset flds = listappend(flds,"agent_#i#_role")>
			<cfset flds = listappend(flds,"agent_#i#_name")>
		</cfloop>


		<cfset flds = listappend(flds,"locality_name")>
		<cfset flds = listappend(flds,"locality_id")>
		<cfset flds = listappend(flds,"locality_higher_geog")>
		<cfset flds = listappend(flds,"locality_specific")>
		<cfset flds = listappend(flds,"locality_remark")>
		<cfset flds = listappend(flds,"locality_min_elevation")>
		<cfset flds = listappend(flds,"locality_max_elevation")>
		<cfset flds = listappend(flds,"locality_elev_units")>
		<cfset flds = listappend(flds,"locality_min_depth")>
		<cfset flds = listappend(flds,"locality_max_depth")>
		<cfset flds = listappend(flds,"locality_depth_units")>




		<cfloop from="1" to="#locality_attribute_count#" index="i">
			<cfset flds = listappend(flds,"locality_attribute_#i#_type")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_value")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_units")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_determiner")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_date")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_method")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_remark")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_type")>
			<cfset flds = listappend(flds,"locality_attribute_#i#_type")>
		</cfloop>

		<cfset flds = listappend(flds,"coordinate_lat_long_units")>
		<cfset flds = listappend(flds,"coordinate_datum")>
		<cfset flds = listappend(flds,"coordinate_max_error_distance")>
		<cfset flds = listappend(flds,"coordinate_max_error_units")>
		<cfset flds = listappend(flds,"coordinate_georeference_protocol")>

		<cfset flds = listappend(flds,"coordinate_dec_lat")>
		<cfset flds = listappend(flds,"coordinate_dec_long")>

		<cfset flds = listappend(flds,"coordinate_lat_deg")>
		<cfset flds = listappend(flds,"coordinate_lat_min")>
		<cfset flds = listappend(flds,"coordinate_lat_sec")>
		<cfset flds = listappend(flds,"coordinate_lat_dir")>
		<cfset flds = listappend(flds,"coordinate_long_deg")>
		<cfset flds = listappend(flds,"coordinate_long_min")>
		<cfset flds = listappend(flds,"coordinate_long_sec")>
		<cfset flds = listappend(flds,"coordinate_long_dir")>

		<cfset flds = listappend(flds,"coordinate_dec_lat_deg")>
		<cfset flds = listappend(flds,"coordinate_dec_lat_min")>
		<cfset flds = listappend(flds,"coordinate_dec_lat_dir")>
		<cfset flds = listappend(flds,"coordinate_dec_long_deg")>
		<cfset flds = listappend(flds,"coordinate_dec_long_min")>
		<cfset flds = listappend(flds,"coordinate_dec_long_dir")>


		<cfset flds = listappend(flds,"coordinate_utm_ew")>
		<cfset flds = listappend(flds,"coordinate_utm_ns")>
		<cfset flds = listappend(flds,"coordinate_utm_zone")>

		<cfset flds = listappend(flds,"event_name")>
		<cfset flds = listappend(flds,"event_id")>
		<cfset flds = listappend(flds,"event_verbatim_locality")>
		<cfset flds = listappend(flds,"event_verbatim_date")>
		<cfset flds = listappend(flds,"event_began_date")>
		<cfset flds = listappend(flds,"event_ended_date")>
		<cfset flds = listappend(flds,"event_remark")>

		<cfloop from="1" to="#event_attribute_count#" index="i">

			<cfset flds = listappend(flds,"event_attribute_#i#_type")>
			<cfset flds = listappend(flds,"event_attribute_#i#_value")>
			<cfset flds = listappend(flds,"event_attribute_#i#_units")>
			<cfset flds = listappend(flds,"event_attribute_#i#_determiner")>
			<cfset flds = listappend(flds,"event_attribute_#i#_date")>
			<cfset flds = listappend(flds,"event_attribute_#i#_method")>
			<cfset flds = listappend(flds,"event_attribute_#i#_remark")>

		</cfloop>

		<cfset flds = listappend(flds,"record_event_type")>
		<cfset flds = listappend(flds,"record_event_determiner")>
		<cfset flds = listappend(flds,"record_event_determined_date")>
		<cfset flds = listappend(flds,"record_event_verificationstatus")>
		<cfset flds = listappend(flds,"record_event_verified_by")>
		<cfset flds = listappend(flds,"record_event_verified_date")>
		<cfset flds = listappend(flds,"record_event_collecting_source")>
		<cfset flds = listappend(flds,"record_event_collecting_method")>
		<cfset flds = listappend(flds,"record_event_habitat")>
		<cfset flds = listappend(flds,"record_event_remark")>

		<cfloop from="1" to="#attribute_count#" index="i">

			<cfset flds = listappend(flds,"attribute_#i#_type")>
			<cfset flds = listappend(flds,"attribute_#i#_value")>
			<cfset flds = listappend(flds,"attribute_#i#_units")>
			<cfset flds = listappend(flds,"attribute_#i#_determiner")>
			<cfset flds = listappend(flds,"attribute_#i#_date")>
			<cfset flds = listappend(flds,"attribute_#i#_method")>
			<cfset flds = listappend(flds,"attribute_#i#_remark")>
		</cfloop>

		<cfloop from="1" to="#part_count#" index="i">
			<cfset flds = listappend(flds,"part_#i#_name")>
			<cfset flds = listappend(flds,"part_#i#_count")>
			<cfset flds = listappend(flds,"part_#i#_disposition")>
			<cfset flds = listappend(flds,"part_#i#_condition")>
			<cfset flds = listappend(flds,"part_#i#_barcode")>
			<cfset flds = listappend(flds,"part_#i#_remark")>
			<cfloop from="1" to="#part_attribute_count#" index="a">
				<cfset flds = listappend(flds,"part_#i#_attribute_type_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_value_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_units_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_determiner_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_date_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_method_#a#")>
				<cfset flds = listappend(flds,"part_#i#_attribute_remark_#a#")>
			</cfloop>
		</cfloop>
		<cfquery name="flush" datasource="uam_god">
			delete from cf_de_approve_settings where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
		</cfquery>
		<cfquery name="ins" datasource="uam_god">
			insert into cf_de_approve_settings (
				username,
				usr_fields
			) values (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">,
				'{#flds#}'
			)
		</cfquery>

		<cfset u="browseBulk.cfm?action=customize&identifier_count=#identifier_count#&identification_count=#identification_count#">
		<cfset u=u & "&identification_count=#identification_count#">
		<cfset u=u & "&identification_attribute_count=#identification_attribute_count#">
		<cfset u=u & "&identification_determiner_count=#identification_determiner_count#">
		<cfset u=u & "&collector_count=#collector_count#">
		<cfset u=u & "&locality_attribute_count=#locality_attribute_count#">
		<cfset u=u & "&event_attribute_count=#event_attribute_count#">
		<cfset u=u & "&part_count=#part_count#">
		<cfset u=u & "&part_attribute_count=#part_attribute_count#">
		<cfset u=u & "&attribute_count=#attribute_count#">
		<cflocation url="#u#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------->
<cfif action is "finalMassLoad">
	<cfparam name="ld" default="autoload_core">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader set status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#ld#"> where 1=1
				<cfif len(enteredby) gt 0>
					and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
				</cfif>
				<cfif  len(accn) gt 0>
					and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
				</cfif>
				<cfif len(colln) gt 0>
					and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
				</cfif>
				<cfif len(key) gt 0>
					and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" list="true">)
				</cfif>
				<cfif len(uuid) gt 0>
					and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
				</cfif>
				<cfif len(catnum) gt 0>
					and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
				</cfif>
				<cfif len(status) gt 0>
					and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#" list="true">
				</cfif>
		</cfquery>
		<p>
			Marked.  <a href="browseBulk.cfm?enteredby=#enteredby#&accn=#accn#&colln=#colln#&key=#key#&uuid=#uuid#&catnum=#catnum#&status=#encodeForURL(status)#">Back to table</a>
		</p>
	</cfoutput>
</cfif>
<cfif action is "finalmassMarkToDelete">
	<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update bulkloader set status='DELETE' where 1=1
		<cfif len(enteredby) gt 0>
			and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
		</cfif>
		<cfif  len(accn) gt 0>
			and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
		</cfif>
		<cfif len(colln) gt 0>
			and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
		</cfif>
		<cfif len(key) gt 0>
			and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" list="true">)
		</cfif>
		<cfif len(uuid) gt 0>
			and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
		</cfif>
		<cfif len(catnum) gt 0>
			and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
		</cfif>
		<cfif len(status) gt 0>
			and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#" list="true">
		</cfif>
	</cfquery>
	<p>
		Marked.  <a href="browseBulk.cfm?enteredby=#enteredby#&accn=#accn#&colln=#colln#&key=#key#&uuid=#uuid#&catnum=#catnum#&status=#encodeForURL(status)#">Back to table</a>
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
				identification_1,
				status,
				count(*) c
			from bulkloader where 1=1
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
			</cfif>
			<cfif len(key) gt 0>
				and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" list="true">)
			</cfif>
			<cfif len(uuid) gt 0>
				and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
			</cfif>
			<cfif len(catnum) gt 0>
				and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
			</cfif>
			<cfif len(status) gt 0>
				and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#" list="true">
			</cfif>
			group by
			enteredby,
				guid_prefix,
				identification_1,
				status
		</cfquery>
		<p>
			Please review the table below. If all looks correct, <a href="browseBulk.cfm?action=finalmassMarkToDelete&enteredby=#enteredby#&accn=#accn#&colln=#colln#&key=#key#&uuid=#uuid#&catnum=#catnum#&status=#encodeForURL(status)#">click here</a> to proceed to set status to DELETE for all listed records.
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
					<td>#identification_1#</td>
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
				identification_1,
				status,
				count(*) c
			from bulkloader where 1=1
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" list="true">)
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" list="true">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" list="true">)
			</cfif>
			<cfif isdefined("key") and len(key) gt 0>
				and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" list="true">)
			</cfif>
			<cfif isdefined("uuid") and len(uuid) gt 0>
				and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
			</cfif>
			<cfif isdefined("catnum") and len(catnum) gt 0>
				and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
			</cfif>
			<cfif len(status) gt 0>
				and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#" list="true">
			</cfif>
			group by
			enteredby,
				guid_prefix,
				identification_1,
				status
		</cfquery>
		<p>
			Please review the table below. If all looks correct, you may proceed in two ways:
			<ul>
				<li>
					Mark only "core" data in the catalog record bulkloader to load:
					<a href="browseBulk.cfm?action=finalMassLoad&enteredby=#enteredby#&accn=#accn#&colln=#colln#&key=#key#&uuid=#uuid#&catnum=#catnum#&status=#encodeForURL(status)#&ld=autoload_core">
						<input type="button" class="lnkBtn" value="autoload_core">
					</a>
				</li>
				<li>
					In addition to marking "core" data in the catalog record bulkloader to load,
					at load also mark any linked (via UUID) data in component loaders to load:
					<a href="browseBulk.cfm?action=finalMassLoad&enteredby=#enteredby#&accn=#accn#&colln=#colln#&key=#key#&uuid=#uuid#&catnum=#catnum#&status=#encodeForURL(status)#&ld=autoload_extras">
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
				<th>identification_1</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#c#</td>
					<td>#enteredby#</td>
					<td>#guid_prefix#</td>
					<td>#status#</td>
					<td>#identification_1#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>


<cfif action is "savePrefs">
	<cfquery name="flush" datasource="uam_god">
		delete from cf_de_approve_settings where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
	</cfquery>
	<cfquery name="ins" datasource="uam_god">
		insert into cf_de_approve_settings (username,usr_fields) values (
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">,
			'{#usrcls#}'
		)
	</cfquery>
	<cflocation url="browseBulk.cfm?action=#callback#" addtoken="false">
</cfif>
<cfif action is "download">

	<cfoutput>
		<cfquery name="cNames" datasource="uam_god">
				select column_name from information_schema.columns where table_name='bulkloader'
		</cfquery>


		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from bulkloader where 1=1
			<cfif len(enteredby) gt 0>
				AND enteredby IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true"> )
			</cfif>
			<cfif len(accn) gt 0>
				AND accn IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true"> )
			</cfif>
			<cfif len(colln) gt 0>
				AND guid_prefix IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true"> )
			</cfif>
			<cfif len(key) gt 0>
				AND key IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="#Not Len(Trim(key))#" list="true"> )
			</cfif>
			<cfif len(uuid) gt 0>
				AND uuid IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" null="#Not Len(Trim(uuid))#" list="true"> )
			</cfif>
			<cfif len(catnum) gt 0>
				AND cat_num IN ( <cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" null="#Not Len(Trim(catnum))#" list="true"> )
			</cfif>
			<cfif len(status) gt 0>
				and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#" list="true">
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
		<cfif not isdefined("uc1") or len(uc1) is 0>
			Not enough information. <cfabort>
		</cfif>
		<cfif (not isdefined("uv1") or len(uv1) is 0) and (not isdefined("ucref1") or len(ucref1) is 0)>
			Not enough information. <cfabort>
		</cfif>



		<cfquery name="upBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			<cfif uv1 is "NULL">
	        	update bulkloader set #uc1# = NULL where 1=1
	    	<cfelseif len(uv1) gt 0>
				update bulkloader set #uc1# = <cfqueryparam value="#uv1#" cfsqltype="cf_sql_varchar"> where 1=1
	    	<cfelseif len(ucref1) gt 0>
				update bulkloader set #uc1# = #ucref1#  where 1=1
	    	</cfif>
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				AND enteredby IN ( <cfqueryparam value="#enteredby#" cfsqltype="cf_sql_varchar" list="true"> )
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				AND accn IN ( <cfqueryparam value="#accn#" cfsqltype="cf_sql_varchar" list="true"> ) 
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				AND guid_prefix IN ( <cfqueryparam value="#colln#" cfsqltype="cf_sql_varchar" list="true"> ) 
			</cfif>
			<cfif isdefined("c1") and len(c1) gt 0 and isdefined("op1") and len(op1) gt 0 and isdefined("v1") and len(v1) gt 0>
				and #c1# #op1# 
				<cfif op1 is "=">
					<cfqueryparam value="#v1#" cfsqltype="cf_sql_varchar">
				<cfelseif op1 is "like">
					<cfqueryparam value="%#v1#%" cfsqltype="cf_sql_varchar">
				<cfelseif op1 is "in">
					( <cfqueryparam value="%#v1#%" cfsqltype="cf_sql_varchar" list="true"> )
				<cfelseif op1 is "between">
					<cfset dash = find("-",v1)>
					<cfset f = left(v1,dash-1)>
					<cfset t = mid(v1,dash+1,len(v1))>
					<cfqueryparam value="#f#" cfsqltype="cf_sql_varchar"> and <cfqueryparam value="#t#" cfsqltype="cf_sql_varchar">
				</cfif>
			</cfif>
			<cfif isdefined("c2") and len(c2) gt 0 and isdefined("op2") and len(op2) gt 0 and isdefined("v2") and len(v2) gt 0>
				AND #c2# #op2#
				<cfif op2 is "=">
					<cfqueryparam value="#v2#" cfsqltype="cf_sql_varchar">
				<cfelseif op2 is "like">
					<cfqueryparam value="%#v2#%" cfsqltype="cf_sql_varchar">
				<cfelseif op2 is "in">
					( <cfqueryparam value="%#v2#%" cfsqltype="cf_sql_varchar" list="true"> )
				<cfelseif op2 is "between">
					<cfset dash = find("-",v2)>
					<cfset f = left(v2,dash-1)>
					<cfset t = mid(v2,dash+1,len(v2))>
					<cfqueryparam value="#f#" cfsqltype="cf_sql_varchar"> and <cfqueryparam value="#t#" cfsqltype="cf_sql_varchar">
				</cfif>
			</cfif>
			<cfif isdefined("c3") and len(c3) gt 0 and isdefined("op3") and len(op3) gt 0 and isdefined("v3") and len(v3) gt 0>
				AND #c3# #op3#
				<cfif #op3# is "=">
					<cfqueryparam value="#v3#" cfsqltype="cf_sql_varchar">
				<cfelseif op3 is "like">
					<cfqueryparam value="%#v3#%" cfsqltype="cf_sql_varchar">
				<cfelseif op3 is "in">
					( <cfqueryparam value="%#v3#%" cfsqltype="cf_sql_varchar" list="true"> )
				<cfelseif op3 is "between">
					<cfset dash = find("-",v3)>
					<cfset f = left(v3,dash-1)>
					<cfset t = mid(v3,dash+1,len(v3))>
					<cfqueryparam value="#f#" cfsqltype="cf_sql_varchar"> and <cfqueryparam value="#t#" cfsqltype="cf_sql_varchar">
				</cfif>
			</cfif>
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
	<cfset sql="#sql# limit 500">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>

	<cfquery name="cNames" datasource="uam_god">
		select column_name from information_schema.columns where table_name='bulkloader' 
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
		<br>Update Options
		<ul>
			<li>Value: enter a string to update all matched records to this value</li>
			<li>ColumnValue: choose a column to update from. Ignored is value is not null.</li>
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
				<th>ColumnValue</th>
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
				<td>
					<select name="ucref1" size="1">
						<option value=""></option>
						<cfloop query="cNames">
							<option value="#column_name#">#column_name#</option>
						</cfloop>
					</select>
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
					select * from data where key=<cfqueryparam value="#data.key#" cfsqltype="cf_sql_varchar">
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
<!-------------------------------------------------------------->



<cfinclude template="/includes/_footer.cfm">
