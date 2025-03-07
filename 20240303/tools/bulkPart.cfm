<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------->
<cfset title="Bulk Modify Parts">
<cfif action is "nothing">
<script>
$(document).ready(function() {
	$(".reqdClr:visible").each(function(e){
	    $(this).prop('required',true);
	});

	$('#existing_part_count').on('change', function() {
		if (this.value.length > 0){
  			$('#new_part_count').addClass('reqdClr').prop('required',true);
  		} else {
  			$('#new_part_count').removeClass('reqdClr').prop('required',false);
  		}
	});

	$('#existing_disposition').on('change', function() {
		if (this.value.length > 0){
  			$('#new_disposition').addClass('reqdClr').prop('required',true);
  		} else {
  			$('#new_disposition').removeClass('reqdClr').prop('required',false);
  		}
	});
});
function setRequireAdd(id){
	var onoff=$("#"+id).val();
	var tid=id.replace("part_name_",'');
	if (onoff.length>0){
		$('#part_count_'+tid).addClass('reqdClr').prop('required',true);
		$('#disposition_'+tid).addClass('reqdClr').prop('required',true);
		$('#condition_'+tid).addClass('reqdClr').prop('required',true);
	} else {
		$('#part_count_'+tid).removeClass('reqdClr').prop('required',false);
		$('#disposition_'+tid).removeClass('reqdClr').prop('required',false);
		$('#condition_'+tid).removeClass('reqdClr').prop('required',false);
	}
}
function copyEPt(){
	$("#new_part_name").val($("#exist_part_name").val());
}
function setPartAttOptions(patype) {
       $.getJSON("/component/DataEntry.cfc",
        {
            method : "getPartAttCodeTbl",
            returnformat : "json",
            attribute      : patype,
            element: 'x',
            guid_prefix: $("#guid_prefix").val()
        },
        function (r) {
            var id='new';
            if (r.status=='success'){
                valElem='attribute_value_' + id;
                unitElem='attribute_units_' + id;
                if (r.control=='values'){
                    d='<select name="' + valElem + '" id="' + valElem + '">';
                    $.each( r.data, function( k, v ) {
                        d += '<option value="' + v + '">' + v + '</option>';
                    });
                    d+="</select>";
                    $('#v_' + id).html(d);
                    d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
                    $('#u_' + id).html(d);
                } else if (r.control=='units'){
                    d='<input type="text" name="' + valElem + '" id="' + valElem + '">';
                    $('#v_' + id).html(d);
                    d='<select name="' + unitElem + '" id="' + unitElem + '">';
                    $.each( r.data, function( k, v ) {
                        d += '<option value="' + v + '">' + v + '</option>';
                    });
                    d+="</select>";
                    $('#u_' + id).html(d);
                } else if (r.control=='none'){
                    dv='<textarea name="' + valElem + '" id="' + valElem + '" class="smalltextarea"></textarea>';
                    //<input type="text" name="' + valElem + '" id="' + valElem + '">';
                    $('#v_' + id).html(dv);
                    d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
                    $('#u_' + id).html(d);
                    //console.log('added blank units');
                } else {
                    alert('woopsies, file an issue');
                }
            } else {
                alert(r.status);
            }
          
        }
    );
}
</script>
<cfoutput>
    <cfset numParts=3>
    <cfif not isdefined("table_name")>
        Bad call.<cfabort>
    </cfif>
<cfquery name="dgp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    select distinct(collection.guid_prefix) as guid_prefix 
    from #table_name#
    inner join cataloged_item on #table_name#.collection_object_id=cataloged_item.collection_object_id
    inner join collection on cataloged_item.collection_id=collection.collection_id    
</cfquery>

<cfif dgp.recordcount is not 1>
    You can only use this form on one collection at a time. Please revise your search.
    <cfabort>
</cfif>
<input type="hidden" id="guid_prefix" value="#dgp.guid_prefix#">
<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    select count(*) c from #table_name#
</cfquery>
<cfquery name="ctdisposition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
    select disposition from ctdisposition order by disposition
</cfquery>
<cfquery name="ctpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select attribute_type from ctpart_attribute_type where <cfqueryparam value="#dgp.guid_prefix#" cfsqltype="cf_sql_varchar"> = any(collections)
 order by attribute_type
</cfquery>
    <p><h1>Bulk-modify parts</h1></p>
    <p>
        Use with caution; you can make very large messes here.
        This form will work on a limited number of records; use an apropriate bulkloader if you experience timeout issues.
        You can download part_ids which work in various bulkloaders from the
        <a href="/Reports/part_data_download.cfm?table_name=#table_name#&sort=guid">Part Table Download</a> application.

    <p><h2>Option 1: Add Part(s)</h2></p>
    <form name="newPart" method="post" action="bulkPart.cfm">
        <input type="hidden" name="action" value="newPart">
        <input type="hidden" name="table_name" value="#table_name#">
        <input type="hidden" name="numParts" value="#numParts#">
        <table border width="90%">
            <tr>
                <td>
                    Add Part 1
                </td>
                <td>Add part 2 (optional)</td>
                <td>Add part 3 (optional)</td>
            </tr>
            <tr>
                 <cfloop from="1" to="#numParts#" index="i">
                    <td>
                        <label for="part_name_#i#">Add Part (#i#)</label>
                        <input type="text" name="part_name_#i#" id="part_name_#i#"
                            onchange="setRequireAdd(this.id);findPart(this.id,this.value,'#dgp.guid_prefix#');"
                            onkeypress="return noenter(event);">
                        <label for="part_count_#i#">Part Count (#i#)</label>
                        <input type="text" name="part_count_#i#" id="part_count_#i#" size="2">
                        <label for="disposition_#i#">Disposition (#i#)</label>
                        <select name="disposition_#i#" id="disposition_#i#" size="1">
                            <cfloop query="ctdisposition">
                                <option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
                            </cfloop>
                        </select>
                        <label for="condition_#i#">Condition (#i#)</label>
                        <input type="text" name="condition_#i#" id="condition_#i#">
                        <label for="part_remark_#i#">Remark (#i#)</label>
                        <input type="text" name="part_remark_#i#" id="part_remark_#i#">
                    </td>
                </cfloop>
            </tr>
        </table>

        <input type="submit" value="Add Parts" class="savBtn">
    </form>
    <hr>
    <p>
        <h2>Option 2: Modify Existing Parts</h2>
    </p>
    <cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
            specimen_part.part_name
        from
            specimen_part,
            #table_name#
        where
            specimen_part.derived_from_cat_item=#table_name#.collection_object_id
        group by specimen_part.part_name
        order by specimen_part.part_name
    </cfquery>
    <cfquery name="existCO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
            specimen_part.part_count,
            specimen_part.disposition
        from
            specimen_part,
            #table_name#
        where
            specimen_part.derived_from_cat_item=#table_name#.collection_object_id
        group by
            specimen_part.part_count,
            specimen_part.disposition
    </cfquery>
    <cfquery name="existLotCount" dbtype="query">
        select part_count from existCO group by part_count order by part_count
    </cfquery>
    <cfquery name="existDisp" dbtype="query">
        select disposition from existCO group by disposition order by disposition
    </cfquery>
    <form name="modPart" method="post" action="bulkPart.cfm">
        <input type="hidden" name="action" value="modPart">
        <input type="hidden" name="table_name" value="#table_name#">
        <table border>
            <tr>
                <td></td>
                <td>
                    Filter specimens for part...
                </td>
                <td>
                    Update to...
                </td>
            </tr>
            <tr>
                <td>Part Name</td>
                <td>
                    <select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr">
                        <option selected="selected" value=""></option>
                            <cfloop query="existParts">
                                <option value="#Part_Name#">#Part_Name#</option>
                            </cfloop>
                    </select>
					<span class="likeLink" onclick="copyEPt()">copy (no change) --></span>
                </td>
                <td>
                    <input type="text" name="new_part_name" id="new_part_name" class="reqdClr"
                        onchange="findPart(this.id,this.value,'#dgp.guid_prefix#');"
                        onkeypress="return noenter(event);">
                </td>
            </tr>
            <tr>
                <td>Part Count</td>
                <td>
                    <select name="existing_part_count" id="existing_part_count" size="1" class="">
                        <option selected="selected" value="">ignore</option>
                            <cfloop query="existLotCount">
                                <option value="#part_count#">#part_count#</option>
                            </cfloop>
                    </select>
                </td>
                <td>
                    <input type="text" name="new_part_count" id="new_part_count" class="">
                </td>
            </tr>
            <tr>
                <td>Disposition</td>
                <td>
                    <select name="existing_disposition" id="existing_disposition" size="1">
                        <option selected="selected" value="">ignore</option>
                            <cfloop query="existDisp">
                                <option value="#disposition#">#disposition#</option>
                            </cfloop>
                    </select>
                </td>
                <td>
                    <select name="new_disposition" id="new_disposition" size="1">
                        <option value="">no update</option>
                        <cfloop query="ctdisposition">
                            <option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
                        </cfloop>
                    </select>
                </td>
            </tr>
            <tr>
                <td>Condition</td>
                <td>
                    Existing CONDITION will be ignored
                </td>
                <td>
                    <input type="text" name="new_condition" id="new_condition">
                </td>
            </tr>
            <tr>
                <td>Remark</td>
                <td>
                    Existing REMARKS will be ignored
                </td>
                <td>
                    <input type="text" name="new_remark" id="new_remark">
                </td>
            </tr>
            <tr>
                <td colspan="3" align="center">
                    <input type="submit" value="Update Parts" class="savBtn">
                </td>
            </tr>
        </table>
    </form>
    <hr>
    <p>
        <h2>Option 3: Delete parts</h2>
        <div class="importantNotification">
          Caution: Part Attributes are cascade-deleted.
        </div>
    </p>
    <form name="delPart" method="post" action="bulkPart.cfm">
        <input type="hidden" name="action" value="delPart">
        <input type="hidden" name="table_name" value="#table_name#">
        <label for="d_exist_part_name">Existing Part Name</label>
        <select name="d_exist_part_name" id="d_exist_part_name" size="1" class="reqdClr">
            <option selected="selected" value=""></option>
                <cfloop query="existParts">
                    <option value="#Part_Name#">#Part_Name#</option>
                </cfloop>
        </select>
        <label for="d_existing_part_count">Existing Part Count</label>
        <select name="d_existing_part_count" id="d_existing_part_count" size="1" >
            <option selected="selected" value="">ignore</option>
                <cfloop query="existLotCount">
                    <option value="#part_count#">#part_count#</option>
                </cfloop>
        </select>
        <label for="d_existing_disposition">Existing Disposition</label>
        <select name="d_existing_disposition" id="d_existing_disposition" size="1">
            <option selected="selected" value="">ignore</option>
                <cfloop query="existDisp">
                    <option value="#disposition#">#disposition#</option>
                </cfloop>
        </select>
        <br><input type="submit" value="Delete Parts" class="delBtn">
    </form>
    <hr>
    <p>
        <h2>Option 4: Add Part Attributes</h2>
    </p>
     <form name="addPartAttr" method="post" action="bulkPart.cfm">
        <input type="hidden" name="action" value="addPartAttr">
        <input type="hidden" name="table_name" value="#table_name#">
        <table border="1">
            <tr>
                <td>
                    <label for="aa_exist_part_name">For every below Part of type....</label>
                    <select name="aa_exist_part_name" id="aa_exist_part_name" size="1" class="reqdClr">
                        <option selected="selected" value=""></option>
                            <cfloop query="existParts">
                                <option value="#Part_Name#">#Part_Name#</option>
                            </cfloop>
                    </select>
                </td>

                <td>
                    <label for="aa_exist_disposition">...with disposition...</label>
                    <select name="aa_exist_disposition" id="aa_exist_disposition" size="10" class="reqdClr" multiple>
                        <option selected="selected" value=""></option>
                        <cfloop query="existDisp">
                            <option value="#disposition#">#disposition#</option>
                        </cfloop>
                    </select>
                </td>

                <td>
                    <label for="attribute_type_new">Add New Attribute Type</label>
                    <select id="attribute_type_new" name="attribute_type_new" onchange="setPartAttOptions(this.value)">
                        <option value="">New Part Attribute Type</option>
                        <cfloop query="ctpart_attribute_type">
                            <option value="#attribute_type#">#attribute_type#</option>
                        </cfloop>
                    </select>
                </td>
                <td>
                    <label for="attribute_value_new">New Attribute Value</label>
                    <div id="v_new">(select attribute type for options)</div>
                </td>
                <td>
                    <label for="attribute_units_new">New Attribute Units</label>
                    <div id="u_new">(select attribute type for options)</div>
                </td>
                <td>
                    <label for="determined_date_new">New Attribute Determined Date</label>
                    <input type="datetime" name="determined_date_new" id="determined_date_new">
                </td>
                <td>
                    <label for="determined_agent_new">New Attribute Determiner</label>
                    <input type="hidden" name="determined_id_new" id="determined_id_new">
                    <input type="text" name="determined_agent_new" id="determined_agent_new"
                        onchange="pickAgentModal('determined_id_new',this.id,this.value);">
                </td>
                <td>
                    <label for="attribute_remark_new">New Attribute Remark</label>
                    <input type="text" name="attribute_remark_new" id="attribute_remark_new">
                </td>
                <td>
                    <label for="determination_method_new">New Attribute Method</label>
                    <input type="text" name="determination_method_new" id="determination_method_new">
                </td>
            </tr>
        </table>


        <br><input type="submit" value="Add attribute for all matching parts in the table below" class="savBtn">
    </form>
    <hr>

    <p>
        <strong>Records being Updated</strong>
    </p>
    <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
            flat.collection_object_id,
            flat.guid,
            flat.scientific_name,
            specimen_part.part_name,
            specimen_part.collection_object_id as partID,
            specimen_part.condition,
            specimen_part.part_count,
            specimen_part.disposition,
            specimen_part.part_remark,
            attribute_type,
            attribute_value,
            attribute_units
        from
            #table_name#
            inner join flat on #table_name#.collection_object_id=flat.collection_object_id
            inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
            left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
        order by
            flat.guid
    </cfquery>
    <cfquery name="s" dbtype="query">
        select collection_object_id,guid,scientific_name from d group by collection_object_id,guid,scientific_name
    </cfquery>
    <table border>
            <tr>
                <th>Record</th>
                <th>ID</th>
                <th>Parts</th>
            </tr>
            <cfloop query="s">
                <tr>
                    <td><a href="/guid/#guid#">#guid#</a></td>
                    <td>#scientific_name#</td>
                    <cfquery name="sp" dbtype="query">
                        select
                            partID,
                            part_name,
                            condition,
                            part_count,
                            disposition,
                            part_remark
                        from
                            d
                        where
                            collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
                        group by
                            partID,
                            part_name,
                            condition,
                            part_count,
                            disposition,
                            part_remark
                        order by
                            part_name
                    </cfquery>
                    <td>
                        <table border width="100%">
                            <th>Part</th>
                            <th>Condition</th>
                            <th>Count</th>
                            <th>Dispn</th>
                            <th>Remark</th>
                            <th>Attributes</th>
                            <cfloop query="sp">
                                <tr>
                                    <td>#part_name#</td>
                                    <td>#condition#</td>
                                    <td>#part_count#</td>
                                    <td>#disposition#</td>
                                    <td>#part_remark#</td>
                                    <cfquery name="spa" dbtype="query">
                                        select attribute_type,attribute_value,attribute_units 
                                         from d
                                            where attribute_type is not null and partID=<cfqueryparam value = "#partID#" CFSQLType="cf_sql_int">
                                    </cfquery>
                                    <td>
                                        <cfloop query="spa">
                                            #attribute_type#=#attribute_value# #attribute_units#<br>
                                        </cfloop>
                                    </td>
                                </tr>
                            </cfloop>
                        </table>
                    </td>
                </tr>
            </cfloop>
        </table>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "addPartAttr">
    <cfoutput>
        <cfparam name="attribute_units_new" default="">
       <cfquery name="ids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
            select
                specimen_part.collection_object_id as partID
            from 
                #table_name#
                inner join specimen_part on #table_name#.collection_object_id=specimen_part.derived_from_cat_item
            where 
                specimen_part.part_name=<cfqueryparam value = "#aa_exist_part_name#" CFSQLType="cf_sql_varchar"> and
                specimen_part.disposition in (<cfqueryparam value="#aa_exist_disposition#" CFSQLType="cf_sql_varchar" list="true">)
        </cfquery>
        <cftransaction>
            <cfloop query="ids">
                <cfquery name="insanatr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    insert into specimen_part_attribute (
                        collection_object_id,
                        attribute_type,
                        attribute_value,
                        attribute_units,
                        determined_by_agent_id,
                        determined_date,
                        attribute_remark,
                        determination_method
                    ) values (
                        <cfqueryparam value = "#partID#" CFSQLType="cf_sql_int">,
                        <cfqueryparam value = "#attribute_type_new#" CFSQLType="cf_sql_varchar">,
                        <cfqueryparam value = "#attribute_value_new#" CFSQLType="cf_sql_varchar">,
                        <cfqueryparam value="#attribute_units_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_units_new))#">,
                        <cfqueryparam value="#determined_id_new#" CFSQLType="cf_sql_int" null="#Not Len(Trim(determined_id_new))#">,
                        <cfqueryparam value="#determined_date_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determined_date_new))#">,
                        <cfqueryparam value="#attribute_remark_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_remark_new))#">,
                        <cfqueryparam value="#determination_method_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determination_method_new))#">
                    )
                </cfquery>
            </cfloop>
        </cftransaction>
        <cflocation url="bulkPart.cfm?table_name=#table_name#" addtoken="false">
    </cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "delPart2">
    <cfoutput>
        <cftransaction>
            <cfloop list="#partID#" index="i">
                <cfquery name="dpa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    delete from specimen_part_attribute where collection_object_id=<cfqueryparam value = "#i#" CFSQLType="cf_sql_int">
                </cfquery>
                <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    delete from specimen_part where collection_object_id=<cfqueryparam value = "#i#" CFSQLType="cf_sql_int">
                </cfquery>
            </cfloop>
        </cftransaction>
    </cfoutput>
    <cflocation url="bulkPart.cfm?table_name=#table_name#" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "delPart">
    <cfoutput>
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
            select
                specimen_part.collection_object_id partID,
                flat.guid,
                flat.scientific_name,
                specimen_part.part_name,
                specimen_part.condition,
                specimen_part.part_count,
                specimen_part.disposition,
                specimen_part.part_remark
            from
			    #table_name#
	            inner join flat on #table_name#.collection_object_id=flat.collection_object_id
	            inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
            where
                part_name=<cfqueryparam value = "#d_exist_part_name#" CFSQLType="cf_sql_varchar">
                <cfif len(d_existing_part_count) gt 0>
                    and part_count=<cfqueryparam value = "#d_existing_part_count#" CFSQLType="cf_sql_int">
                </cfif>
                <cfif len(d_existing_disposition) gt 0>
                    and disposition=<cfqueryparam value = "#d_existing_disposition#" CFSQLType="cf_sql_varchar">
                </cfif>
            order by
                flat.guid
        </cfquery>

        <form name="modPart" method="post" action="bulkPart.cfm">
            <input type="hidden" name="action" value="delPart2">
            <input type="hidden" name="table_name" value="#table_name#">
            <input type="hidden" name="partID" value="#valuelist(d.partID)#">
            <input type="submit" value="Looks good - do it" class="savBtn">
        </form>
        <table border>
            <tr>
                <th>Record</th>
                <th>ID</th>
                <th>PartToBeDeleted</th>
                <th>Condition</th>
                <th>Cnt</th>
                <th>Dispn</th>
                <th>Remark</th>
            </tr>
            <cfloop query="d">
                <tr>
                    <td>#guid#</td>
                    <td>#scientific_name#</td>
                    <td>#part_name#</td>
                    <td>#condition#</td>
                    <td>#part_count#</td>
                    <td>#disposition#</td>
                    <td>#part_remark#</td>
                </tr>
            </cfloop>
        </table>
    </cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "modPart2">
    <cfoutput>
        <cftransaction>
            <cfloop list="#partID#" index="i">
                <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    update 
                        specimen_part 
                    set 
                        part_name=<cfqueryparam value="#new_part_name#" cfsqltype="cf_sql_varchar">
                        <cfif len(new_part_count) gt 0>
                            ,part_count=<cfqueryparam value = "#new_part_count#" CFSQLType="cf_sql_int">
                        </cfif>
                        <cfif len(new_disposition) gt 0>
                            ,disposition=<cfqueryparam value = "#new_disposition#" CFSQLType="cf_sql_varchar">
                        </cfif>
                        <cfif len(new_condition) gt 0>
                            ,condition=<cfqueryparam value = "#new_condition#" CFSQLType="cf_sql_varchar">
                        </cfif>
                         <cfif len(new_remark) gt 0>
                            ,part_remark= <cfqueryparam value = "#new_remark#" CFSQLType="cf_sql_varchar">
                        </cfif>
                    where 
                        collection_object_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
                </cfquery>
            </cfloop>
        </cftransaction>
        <cflocation url="bulkPart.cfm?table_name=#table_name#" addtoken="false">
    </cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "modPart">
    <cfif len(exist_part_name) is 0 or len(new_part_name) is 0>
        Not enough information.
        <cfabort>
    </cfif>
    <cfoutput>
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
            select
                specimen_part.collection_object_id partID,
                flat.guid,
                flat.scientific_name,
                specimen_part.part_name,
                specimen_part.condition,
                specimen_part.part_count,
                specimen_part.disposition,
                specimen_part.part_remark
            from
                #table_name#
                inner join flat on #table_name#.collection_object_id=flat.collection_object_id
                inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
            where
                part_name=<cfqueryparam value = "#exist_part_name#" CFSQLType="CF_SQL_VARCHAR">
                <cfif len(existing_part_count) gt 0>
                    and part_count=<cfqueryparam value = "#existing_part_count#" CFSQLType="cf_sql_int">
                </cfif>
                <cfif len(existing_disposition) gt 0>
                    and disposition=<cfqueryparam value = "#existing_disposition#" CFSQLType="CF_SQL_VARCHAR">
                </cfif>
            order by
                flat.guid
        </cfquery>
        <form name="modPart" method="post" action="bulkPart.cfm">
            <input type="hidden" name="action" value="modPart2">
            <input type="hidden" name="table_name" value="#table_name#">
            <input type="hidden" name="exist_part_name" value="#exist_part_name#">
            <input type="hidden" name="new_part_name" value="#new_part_name#">
            <input type="hidden" name="existing_part_count" value="#existing_part_count#">
            <input type="hidden" name="new_part_count" value="#new_part_count#">
            <input type="hidden" name="existing_disposition" value="#existing_disposition#">
            <input type="hidden" name="new_disposition" value="#new_disposition#">
            <input type="hidden" name="new_condition" value="#new_condition#">
            <input type="hidden" name="new_remark" value="#encodeForHTML(new_remark)#">
            <input type="hidden" name="partID" value="#valuelist(d.partID)#">
            <input type="submit" value="Looks good - do it" class="savBtn">
        </form>
        <table border>
            <tr>
                <th>Record</th>
                <th>ID</th>
                <th>OldPart</th>
                <th>NewPart</th>
                <th>OldCondition</th>
                <th>NewCondition</th>
                <th>OldCnt</th>
                <th>NewdCnt</th>
                <th>OldDispn</th>
                <th>NewDispn</th>
                <th>OldRemark</th>
                <th>NewRemark</th>
            </tr>
            <cfloop query="d">
                <tr>
                    <td>#guid#</td>
                    <td>#scientific_name#</td>
                    <td>#part_name#</td>
                    <td>#new_part_name#</td>
                    <td>#condition#</td>
                    <td>
                        <cfif len(new_condition) gt 0>
                            #new_condition#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                    <td>#part_count#</td>
                    <td>
                        <cfif len(new_part_count) gt 0>
                            #new_part_count#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                    <td>#disposition#</td>
                    <td>
                        <cfif len(new_disposition) gt 0>
                            #new_disposition#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                    <td>#part_remark#</td>
                    <td>
                        <cfif len(new_remark) gt 0>
                            #new_remark#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                </tr>
            </cfloop>
        </table>
    </cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "newPart">
<cfoutput>
    <cfquery name="ids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select distinct collection_object_id from #table_name#
    </cfquery>
    <cftransaction>
        <cfloop query="ids">
            <cfloop from="1" to="#numParts#" index="n">
                <cfset thisPartName = #evaluate("part_name_" & n)#>
                <cfset thisLotCount = #evaluate("part_count_" & n)#>
                <cfset thisDisposition = #evaluate("disposition_" & n)#>
                <cfset thisCondition = #evaluate("condition_" & n)#>
                <cfset thisRemark = #evaluate("part_remark_" & n)#>
                <cfif len(#thisPartName#) gt 0>
              
                    <cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                        INSERT INTO specimen_part (
                            COLLECTION_OBJECT_ID,
                            PART_NAME,
                            DERIVED_FROM_cat_item,
                            created_agent_id,
                            created_date,
                            part_count,
                            DISPOSITION,
                            CONDITION,
                            part_remark
                        ) VALUES (
                            nextval('sq_collection_object_id'),
                            <cfqueryparam value="#thisPartName#" CFSQLType="CF_SQL_VARCHAR">,
                            <cfqueryparam value="#ids.collection_object_id#" CFSQLType="cf_sql_int">,
                            <cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
                            current_date,
                            <cfqueryparam value="#thisLotCount#" CFSQLType="cf_sql_int">,
                            <cfqueryparam value="#thisDisposition#" CFSQLType="CF_SQL_VARCHAR">,
                            <cfqueryparam value="#thisCondition#" CFSQLType="CF_SQL_VARCHAR">,
                            <cfqueryparam value="#thisRemark#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(thisRemark))#">
                        )
                    </cfquery>
                </cfif>
            </cfloop>
        </cfloop>
    </cftransaction>
    Success!
    <a href="/search.cfm?collection_object_id=#valuelist(ids.collection_object_id)#">Return to SpecimenResults</a>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">