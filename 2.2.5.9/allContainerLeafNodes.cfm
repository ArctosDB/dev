<!-----
https://github.com/ArctosDB/arctos/issues/4706
see v1.7 for old iterative code; initial is faster but loops are slower, this seems overall better performing
----->
<cfinclude template="includes/_header.cfm">
<cfsetting requesttimeout="600">
<script src="/includes/sorttable.js"></script>
<cfset title = "Container Locations">
<cfoutput>
	<cfif action is "nothing">
		<p>
			<a href="/search.cfm?anyContainerId=#container_id#">Catalog Records</a>
		</p>
		<cfset rtnLmt=1500>
		<p>Note: This form will display a maximum of #rtnLmt# records.</p>
		<cfquery name="leaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			WITH RECURSIVE subordinates AS (
			    SELECT
			        container.container_id,
			        container.container_type,
			        container.label,
			        container.description,
			        container.container_remarks,
			        getContainerParentage(container.container_id) fullPath,
			        0 lvl
			    FROM
			        container
			    WHERE
			        container_id=<cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">
			    UNION SELECT
			        e.container_id,
			        e.container_type,
			        e.label,
			        e.description,
			        e.container_remarks,
			        getContainerParentage(e.container_id) fullPath,
			        s.lvl + 1 lvl
			    FROM
			        container e
			        INNER JOIN subordinates s ON s.container_id=e.parent_container_id
			    where lvl<20
			) SELECT
			    subordinates.container_id,
			    subordinates.container_type,
			    subordinates.label,
			    subordinates.description,
			    subordinates.container_remarks,
			    subordinates.fullPath,
			    specimen_part.part_name,
			    specimen_part.collection_object_id partID,
			    coll_object.COLL_OBJ_DISPOSITION,
			    concat(collection.guid_prefix,':',cataloged_item.cat_num) as guid,
			    identification.scientific_name
			FROM
			    subordinates 
			    inner join coll_obj_cont_hist on subordinates.container_id=coll_obj_cont_hist.container_id
			    inner join specimen_part on coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id
			    inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
			    inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			    inner join identification on cataloged_item.collection_object_id = identification.collection_object_id and accepted_id_fg=1
			    inner join collection on cataloged_item.collection_id=collection.collection_id
			where 
			    subordinates.container_type='collection object' 
			order by
			    COALESCE(SUBSTRING(subordinates.fullPath FROM '^(\\d+)')::INTEGER, 99999999),
			    SUBSTRING(subordinates.fullPath FROM '^\\d* *(.*?)( \\d+)?$'),
			    COALESCE(SUBSTRING(subordinates.fullPath FROM ' (\\d+)$')::INTEGER, 0),
			    fullPath
			limit #rtnLmt#
		</cfquery>
		<cfset partIDs="">
		<cfset displ="">
		<strong>
			<a href="/findContainer.cfm?container_id=#container_id#" target="_detail">Container #container_id#</a>
		 	has #leaf.recordcount# leaf containers:
		</strong>
		<table border id="t" class="sortable">
			<tr>
				<td><strong>Label</strong></td>
				<td><strong>Description</strong></td>
				<td><strong>Next2Layers</strong></td>
				<td><strong>Remarks</strong></td>
				<td><strong>Part Name</strong></td>
				<td><strong>Disposition</strong></td>
				<td><strong>Cat Num</strong></td>
				<td><strong>Scientific Name</strong></td>
			</tr>
			<cfloop query="leaf">
				<cfset partIDs=listappend(partIDs,partID)>
				<cfset displ=listappend(displ,COLL_OBJ_DISPOSITION)>
				<tr>
					<td>
						<a href="/findContainer.cfm?container_id=#container_id#" target="_detail">#label#</a>
					</td>
					<td>#description#&nbsp;</td>
					<td>
						<cftry>
							<cfset fprepl=replace(fullpath,"):[",")#chr(7)#[","all")>
							<cfset fll=listlen(fprepl,chr(7))>
							<cfset prnt1=listgetat(fprepl,fll-1,chr(7))>
							<cfset prnt2=listgetat(fprepl,fll-2,chr(7))>
							<cfset l= prnt2 & ":" & prnt1 >
						<cfcatch>
							<cfset l=fullpath>
						</cfcatch>
						</cftry>
						#l#
					</td>
					<td>#container_remarks#&nbsp;</td>
					<td>#part_name#</td>
					<td>#COLL_OBJ_DISPOSITION#</td>
					<td>
						<a href="/guid/#guid#">#guid#</a>
					</td>
					<td>#scientific_name#</td>
				</tr>
			</cfloop>
		</table>

		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix ,collection_id from collection order by guid_prefix
		</cfquery>
		<cfquery name="CTCOLL_OBJ_DISP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by COLL_OBJ_DISPOSITION
		</cfquery>

		<cfif listcontains(displ,"on loan")>
			You can't use this to add loan items because some listed items are already on loan.
		<cfelse>
			<hr>
			<label for="f">Add All Items To Loan and update part disposition to "on loan"</label>
			<form name="f" method="post" action="">
				<input type="hidden" name="Action" value="addPartsToLoan">
				<input type="hidden" name="partIDs" value="#partIDs#">
				<label for="collection">Collection</label>
				<select name="collection_id" id="collection_id">
					<cfloop query="ctcollection">
						<option value="#collection_id#">#guid_prefix#</option>
					</cfloop>
				</select>
				<label for="loan_number">Loan Number</label>
				<input type="text" name="loan_number" size="25">
				<br>
				<input type="submit" class="insBtn" value="add all items to loan">
			</form>
		</cfif>
		<hr>
		<form name="f2" method="post" action="">
			<input type="hidden" name="Action" value="updateAllDisposition">
			<input type="hidden" name="partIDs" value="#partIDs#">
			<input type="hidden" name="container_id" value="#container_id#">
			<label for="disposition">Update All Part Disposition To</label>
			<select name="disposition" id="disposition">
				<option value=""></option>
				<cfloop query="CTCOLL_OBJ_DISP">
					<option value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
				</cfloop>
			</select>
			<input type="submit" class="lnkBtn" value="mass-update disposition">
		</form>
	</cfif>


</cfoutput>

<cfif action is "updateAllDisposition">
	<cfquery name="ud" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		update coll_object set COLL_OBJ_DISPOSITION='#disposition#' where COLLECTION_OBJECT_ID in (
			<cfqueryparam value="#partIDs#" CFSQLType="cf_sql_int" list="true">
		)
	</cfquery>
	<cflocation url="allContainerLeafNodes.cfm?container_id=#container_id#" addtoken="false">
</cfif>


<cfif action is "addPartsToLoan">
	<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select loan.transaction_id from loan,trans where loan.transaction_id=trans.transaction_id and
		loan.loan_number=<cfqueryparam value="#loan_number#" CFSQLType="cf_sql_varchar"> and
		trans.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif getLoan.recordcount is not 1>
		error finding loan
		<cfdump var=#getLoan#>
		<cfabort>
	</cfif>
	<cftransaction>
			<cfquery name="insItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into loan_item (
					TRANSACTION_ID,
					COLLECTION_OBJECT_ID,
					RECONCILED_BY_PERSON_ID,
					RECONCILED_DATE,
					ITEM_DESCR
				) values 
				<cfloop list="#partIDs#" index="li">
					(
						<cfqueryparam value="#getLoan.transaction_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#li#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						current_date,
						(
							select
								guid || ' ' || part_name
							from
								flat,
								specimen_part
							where
								flat.collection_object_id=specimen_part.derived_from_cat_item and
								specimen_part.collection_object_id=<cfqueryparam value="#li#" CFSQLType="cf_sql_int">
						)
					)<cfif li neq listlast(partIDs)>,</cfif>
				</cfloop>
			</cfquery>
			<cfquery name="upD" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update coll_object set COLL_OBJ_DISPOSITION='on loan' where COLLECTION_OBJECT_ID in (
					<cfqueryparam value="#partIDs#" CFSQLType="cf_sql_int" list="true">
				) 
			</cfquery>
	</cftransaction>
	<cfoutput>
		Added #listlen(partIDs)# items to loan <a href="Loan.cfm?action=editLoan&transaction_id=#getLoan.transaction_id#">#loan_number#</a>

		<p><a href="allContainerLeafNodes.cfm?container_id=#container_id#">back</a>
	</cfoutput>
	<cfabort>
</cfif>
<cfinclude template="includes/_footer.cfm">