<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------->
<cfset title="Bulk Modify Parts">
<cfif action is "nothing">
<script>
$(document).ready(function() {
	$(".reqdClr:visible").each(function(e){
	    $(this).prop('required',true);
	});

	$('#existing_lot_count').on('change', function() {
		if (this.value.length > 0){
  			$('#new_lot_count').addClass('reqdClr').prop('required',true);
  		} else {
  			$('#new_lot_count').removeClass('reqdClr').prop('required',false);
  		}
	});

	$('#existing_coll_obj_disposition').on('change', function() {
		if (this.value.length > 0){
  			$('#new_coll_obj_disposition').addClass('reqdClr').prop('required',true);
  		} else {
  			$('#new_coll_obj_disposition').removeClass('reqdClr').prop('required',false);
  		}
	});


});

function setRequireAdd(id){
	var onoff=$("#"+id).val();
	var tid=id.replace("part_name_",'');
	if (onoff.length>0){
		$('#lot_count_'+tid).addClass('reqdClr').prop('required',true);
		$('#coll_obj_disposition_'+tid).addClass('reqdClr').prop('required',true);
		$('#condition_'+tid).addClass('reqdClr').prop('required',true);
	} else {
		$('#lot_count_'+tid).removeClass('reqdClr').prop('required',false);
		$('#coll_obj_disposition_'+tid).removeClass('reqdClr').prop('required',false);
		$('#condition_'+tid).removeClass('reqdClr').prop('required',false);
	}
}
function copyEPt(){
	$("#new_part_name").val($("#exist_part_name").val());
}



</script>


<cfoutput>
    <cfset numParts=3>
    <cfif not isdefined("table_name")>
        Bad call.<cfabort>
    </cfif>
<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    select distinct(cataloged_item.COLLECTION_ID) from #table_name#, cataloged_item where
    #table_name#.collection_object_id=cataloged_item.collection_object_id
</cfquery>

<cfset colcdes = valuelist(colcde.COLLECTION_ID)>
<cfif listlen(colcdes) is not 1>
    You can only use this form on one collection at a time. Please revise your search.
    <cfabort>
</cfif>
<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    select count(*) c from #table_name#
</cfquery>
<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
    select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
</cfquery>
<cfquery name="getColnCde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
    select collection_cde from collection where collection_id=#colcdes#
</cfquery>
<cfquery name="ctspecpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select attribute_type from ctspecpart_attribute_type order by attribute_type
</cfquery>
    <p><h1>Bulk-modify parts</h1></p>
    <p>
        Use with caution; you can make very large messes here.
        This form will work on a limited number of records; use an apropriate bulkloader if you experience timeout issues.
        You can download part_ids which work in various bulkloaders from the
        <a href="/info/part_data_download.cfm?table_name=#table_name#&sort=guid">Part Table Download</a> application.

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
                            onchange="setRequireAdd(this.id);findPart(this.id,this.value,'#getColnCde.collection_cde#');"
                            onkeypress="return noenter(event);">
                        <label for="lot_count_#i#">Part Count (#i#)</label>
                        <input type="text" name="lot_count_#i#" id="lot_count_#i#" size="2">
                        <label for="coll_obj_disposition_#i#">Disposition (#i#)</label>
                        <select name="coll_obj_disposition_#i#" id="coll_obj_disposition_#i#" size="1">
                            <cfloop query="ctDisp">
                                <option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
                            </cfloop>
                        </select>
                        <label for="condition_#i#">Condition (#i#)</label>
                        <input type="text" name="condition_#i#" id="condition_#i#">
                        <label for="coll_object_remarks_#i#">Remark (#i#)</label>
                        <input type="text" name="coll_object_remarks_#i#" id="coll_object_remarks_#i#">
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
            coll_object.lot_count,
            coll_object.coll_obj_disposition
        from
            specimen_part,
            coll_object,
            #table_name#
        where
            specimen_part.derived_from_cat_item=#table_name#.collection_object_id and
            specimen_part.collection_object_id=coll_object.collection_object_id
        group by
            coll_object.lot_count,
            coll_object.coll_obj_disposition
    </cfquery>
    <cfquery name="existLotCount" dbtype="query">
        select lot_count from existCO group by lot_count order by lot_count
    </cfquery>
    <cfquery name="existDisp" dbtype="query">
        select coll_obj_disposition from existCO group by coll_obj_disposition order by coll_obj_disposition
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
                        onchange="findPart(this.id,this.value,'#getColnCde.collection_cde#');"
                        onkeypress="return noenter(event);">
                </td>
            </tr>
            <tr>
                <td>Lot Count</td>
                <td>
                    <select name="existing_lot_count" id="existing_lot_count" size="1" class="">
                        <option selected="selected" value="">ignore</option>
                            <cfloop query="existLotCount">
                                <option value="#lot_count#">#lot_count#</option>
                            </cfloop>
                    </select>
                </td>
                <td>
                    <input type="text" name="new_lot_count" id="new_lot_count" class="">
                </td>
            </tr>
            <tr>
                <td>Disposition</td>
                <td>
                    <select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1">
                        <option selected="selected" value="">ignore</option>
                            <cfloop query="existDisp">
                                <option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
                            </cfloop>
                    </select>
                </td>
                <td>
                    <select name="new_coll_obj_disposition" id="new_coll_obj_disposition" size="1">
                        <option value="">no update</option>
                        <cfloop query="ctDisp">
                            <option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
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
        <label for="d_existing_lot_count">Existing Lot Count</label>
        <select name="d_existing_lot_count" id="d_existing_lot_count" size="1" >
            <option selected="selected" value="">ignore</option>
                <cfloop query="existLotCount">
                    <option value="#lot_count#">#lot_count#</option>
                </cfloop>
        </select>
        <label for="d_existing_coll_obj_disposition">Existing Disposition</label>
        <select name="d_existing_coll_obj_disposition" id="d_existing_coll_obj_disposition" size="1">
            <option selected="selected" value="">ignore</option>
                <cfloop query="existDisp">
                    <option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
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
                            <option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
                        </cfloop>
                    </select>
                </td>

                <td>
                    <label for="attribute_type_new">Add New Attribute Type</label>
                    <select id="attribute_type_new" name="attribute_type_new" onchange="setPartAttOptions('new',this.value)">
                        <option value="">New Part Attribute Type</option>
                        <cfloop query="ctspecpart_attribute_type">
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
        <strong>Specimens being Updated</strong>
    </p>
    <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
            flat.collection_object_id,
            flat.guid,
            flat.scientific_name,
            specimen_part.part_name,
            specimen_part.collection_object_id as partID,
            coll_object.condition,
            coll_object.lot_count,
            coll_object.coll_obj_disposition,
            coll_object_remark.coll_object_remarks,
            attribute_type,
            attribute_value,
            attribute_units
        from
            #table_name#
            inner join flat on #table_name#.collection_object_id=flat.collection_object_id
            inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
             inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
            left outer join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
            left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
        order by
            flat.guid
    </cfquery>
    <cfquery name="s" dbtype="query">
        select collection_object_id,guid,scientific_name from d group by collection_object_id,guid,scientific_name
    </cfquery>
    <table border>
            <tr>
                <th>Specimen</th>
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
                            lot_count,
                            coll_obj_disposition,
                            coll_object_remarks
                        from
                            d
                        where
                            collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
                        group by
                            partID,
                            part_name,
                            condition,
                            lot_count,
                            coll_obj_disposition,
                            coll_object_remarks
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
                                    <td>#lot_count#</td>
                                    <td>#coll_obj_disposition#</td>
                                    <td>#coll_object_remarks#</td>
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
                inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
            where 
                specimen_part.part_name=<cfqueryparam value = "#aa_exist_part_name#" CFSQLType="cf_sql_varchar"> and
                coll_object.coll_obj_disposition in (<cfqueryparam value="#aa_exist_disposition#" CFSQLType="cf_sql_varchar" list="true">)
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
                collection.guid_prefix,
                cataloged_item.cat_num,
                identification.scientific_name,
                specimen_part.part_name,
                coll_object.condition,
                coll_object.lot_count,
                coll_object.coll_obj_disposition,
                coll_object_remark.coll_object_remarks
            from
			    #table_name#
	            inner join cataloged_item on #table_name#.collection_object_id=cataloged_item.collection_object_id
	            inner join collection on cataloged_item.collection_id=collection.collection_id
	            inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
	            inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
            	left outer join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
	            inner join identification on cataloged_item.collection_object_id=identification.collection_object_id and accepted_id_fg=1
            where
                part_name=<cfqueryparam value = "#d_exist_part_name#" CFSQLType="cf_sql_varchar">
                <cfif len(d_existing_lot_count) gt 0>
                    and lot_count=<cfqueryparam value = "#d_existing_lot_count#" CFSQLType="cf_sql_int">
                </cfif>
                <cfif len(d_existing_coll_obj_disposition) gt 0>
                    and coll_obj_disposition=<cfqueryparam value = "#d_existing_coll_obj_disposition#" CFSQLType="cf_sql_varchar">
                </cfif>
            order by
                collection.guid_prefix,cataloged_item.cat_num
        </cfquery>

        <form name="modPart" method="post" action="bulkPart.cfm">
            <input type="hidden" name="action" value="delPart2">
            <input type="hidden" name="table_name" value="#table_name#">
            <input type="hidden" name="partID" value="#valuelist(d.partID)#">
            <input type="submit" value="Looks good - do it" class="savBtn">
        </form>
        <table border>
            <tr>
                <th>Specimen</th>
                <th>ID</th>
                <th>PartToBeDeleted</th>
                <th>Condition</th>
                <th>Cnt</th>
                <th>Dispn</th>
                <th>Remark</th>
            </tr>
            <cfloop query="d">
                <tr>
                    <td>#guid_prefix# #cat_num#</td>
                    <td>#scientific_name#</td>
                    <td>#part_name#</td>
                    <td>#condition#</td>
                    <td>#lot_count#</td>
                    <td>#coll_obj_disposition#</td>
                    <td>#coll_object_remarks#</td>
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
                update specimen_part set part_name='#new_part_name#' where collection_object_id=#i#
            </cfquery>
            <cfif len(new_lot_count) gt 0 or len(new_coll_obj_disposition) gt 0 or len(new_condition) gt 0>
                <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    update coll_object set
                        flags=flags
                        <cfif len(new_lot_count) gt 0>
                            ,lot_count=<cfqueryparam value = "#new_lot_count#" CFSQLType="cf_sql_int">
                        </cfif>
                        <cfif len(new_coll_obj_disposition) gt 0>
                            ,coll_obj_disposition=<cfqueryparam value = "#new_coll_obj_disposition#" CFSQLType="cf_sql_varchar">
                        </cfif>
                        <cfif len(new_condition) gt 0>
                            ,condition=<cfqueryparam value = "#new_condition#" CFSQLType="cf_sql_varchar">
                        </cfif>
                    where collection_object_id=<cfqueryparam value = "#i#" CFSQLType="cf_sql_int">
                </cfquery>
            </cfif>
            <cfif len(new_remark) gt 0>
                <cftry>
                    <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                        insert into coll_object_remark (
                            collection_object_id,
                            coll_object_remarks
                        ) values (
                            <cfqueryparam value = "#i#" CFSQLType="cf_sql_int">,
                            <cfqueryparam value = "#new_remark#" CFSQLType="cf_sql_varchar">)
                    </cfquery>
                    <cfcatch>
                        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                            update coll_object_remark set 
                                coll_object_remarks=<cfqueryparam value = "#new_remark#" CFSQLType="cf_sql_varchar"> where 
                                collection_object_id=<cfqueryparam value = "#i#" CFSQLType="cf_sql_int">
                        </cfquery>
                    </cfcatch>
                </cftry>
            </cfif>
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
                collection.guid_prefix,
                cataloged_item.cat_num,
                identification.scientific_name,
                specimen_part.part_name,
                coll_object.condition,
                coll_object.lot_count,
                coll_object.coll_obj_disposition,
                coll_object_remark.coll_object_remarks
            from
                #table_name#
                inner join cataloged_item on #table_name#.collection_object_id=cataloged_item.collection_object_id
                inner join collection on cataloged_item.collection_id=collection.collection_id
                inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
                inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
                left outer join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
                inner join identification on cataloged_item.collection_object_id=identification.collection_object_id and accepted_id_fg=1
            where
                part_name=<cfqueryparam value = "#exist_part_name#" CFSQLType="CF_SQL_VARCHAR">
                <cfif len(existing_lot_count) gt 0>
                    and lot_count=<cfqueryparam value = "#existing_lot_count#" CFSQLType="cf_sql_int">
                </cfif>
                <cfif len(existing_coll_obj_disposition) gt 0>
                    and coll_obj_disposition=<cfqueryparam value = "#existing_coll_obj_disposition#" CFSQLType="CF_SQL_VARCHAR">
                </cfif>
            order by
                collection.guid_prefix,cataloged_item.cat_num
        </cfquery>
        <form name="modPart" method="post" action="bulkPart.cfm">
            <input type="hidden" name="action" value="modPart2">
            <input type="hidden" name="table_name" value="#table_name#">
            <input type="hidden" name="exist_part_name" value="#exist_part_name#">
            <input type="hidden" name="new_part_name" value="#new_part_name#">
            <input type="hidden" name="existing_lot_count" value="#existing_lot_count#">
            <input type="hidden" name="new_lot_count" value="#new_lot_count#">
            <input type="hidden" name="existing_coll_obj_disposition" value="#existing_coll_obj_disposition#">
            <input type="hidden" name="new_coll_obj_disposition" value="#new_coll_obj_disposition#">
            <input type="hidden" name="new_condition" value="#new_condition#">
            <input type="hidden" name="new_remark" value="#new_remark#">
            <input type="hidden" name="partID" value="#valuelist(d.partID)#">
            <input type="submit" value="Looks good - do it" class="savBtn">
        </form>
        <table border>
            <tr>
                <th>Specimen</th>
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
                    <td>#guid_prefix# #cat_num#</td>
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
                    <td>#lot_count#</td>
                    <td>
                        <cfif len(new_lot_count) gt 0>
                            #new_lot_count#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                    <td>#coll_obj_disposition#</td>
                    <td>
                        <cfif len(new_coll_obj_disposition) gt 0>
                            #new_coll_obj_disposition#
                        <cfelse>
                            NOT UPDATED
                        </cfif>
                    </td>
                    <td>#coll_object_remarks#</td>
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
                <cfset thisLotCount = #evaluate("lot_count_" & n)#>
                <cfset thisDisposition = #evaluate("coll_obj_disposition_" & n)#>
                <cfset thisCondition = #evaluate("condition_" & n)#>
                <cfset thisRemark = #evaluate("coll_object_remarks_" & n)#>
                <cfif len(#thisPartName#) gt 0>
                    <cfquery name="insCollPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                        INSERT INTO coll_object (
                            COLLECTION_OBJECT_ID,
                            ENTERED_PERSON_ID,
                            COLL_OBJECT_ENTERED_DATE,
                            LAST_EDITED_PERSON_ID,
                            COLL_OBJ_DISPOSITION,
                            LOT_COUNT,
                            CONDITION,
                            FLAGS )
                        VALUES (
                            nextval('sq_collection_object_id'),
                            <cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
                            current_date,
                            <cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
                            <cfqueryparam value="#thisDisposition#" CFSQLType="CF_SQL_VARCHAR">,
                            <cfqueryparam value="#thisLotCount#" CFSQLType="cf_sql_int">,
                            <cfqueryparam value="#thisCondition#" CFSQLType="CF_SQL_VARCHAR">,
                            0 )
                    </cfquery>
                    <cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                        INSERT INTO specimen_part (
                            COLLECTION_OBJECT_ID,
                            PART_NAME,
                            DERIVED_FROM_cat_item
                        ) VALUES (
                            currval('sq_collection_object_id'),
                            <cfqueryparam value="#thisPartName#" CFSQLType="CF_SQL_VARCHAR">,
                            <cfqueryparam value="#ids.collection_object_id#" CFSQLType="cf_sql_int">
                        )
                    </cfquery>
                    <cfif len(#thisRemark#) gt 0>
                        <cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                            INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
                            VALUES (currval('sq_collection_object_id'), <cfqueryparam value="#thisRemark#" CFSQLType="CF_SQL_VARCHAR">)
                        </cfquery>
                    </cfif>
                </cfif>
            </cfloop>
        </cfloop>
    </cftransaction>
    Success!
    <a href="/search.cfm?collection_object_id=#valuelist(ids.collection_object_id)#">Return to SpecimenResults</a>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">