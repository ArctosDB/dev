<cfinclude template="/includes/_header.cfm">


<!---- relies on table bulkloader_clone
	
 drop table bulkloader_clone;
create table bulkloader_clone as select * from bulkloader where 1=0;
grant all on bulkloader_clone to coldfusion_user;


---->


<cfset title="scan barcodes to make copies of a record">
<cfif action IS "nothing">
	<h3>
		Clone records in the bulkloader by barcode.
	</h3>

	<p>Purpose:</p>
	<ul>
		<li>Create one or more copies of a record in the catalog item bulkloader, with new barcodes in part_1_barcode.</li>
	</ul>
	<p>
		Requirements:
		<ul>
			<li>A record in the bulkloader has part_1_barcode</li>
			<li>One or more barcodes are available for clones</li>
		</ul>
	</p>
	<form name="f" method="post" action="cloneWithBarcodes.cfm">
		<input type="hidden" name="action" value="findSeed">
		<label for="barcode">Enter a "seed" part_1_barcode that matches a barcode of a record in the bulkloader to clone.</label>
		<input type="text" size="60" name="barcode">
		<br><input type="submit" value="go" class="lnkBtn">
	</form>
</cfif>
<cfif action is "findSeed">
	<cfoutput>
		<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select key,guid_prefix,enteredby,accn,cat_num,identification_1 from bulkloader where
			part_1_barcode=<cfqueryparam cfsqltype="cf_sql_varchar" value="#barcode#" null="#Not Len(Trim(barcode))#">
		</cfquery>
		<cfif seed.recordcount is 0>
			Not found. <cfabort>
		</cfif>
		Summary of Matching Records:
		<table border>
			<tr>
				<th>key</th>
				<th>guid_prefix</th>
				<th>enteredby</th>
				<th>accn</th>
				<th>cat_num</th>
				<th>identification_1</th>
			</tr>
			<cfloop query="seed">
				<tr>
					<td>
						<a class="newWinLocal" href="/Bulkloader/browseBulk.cfm?key=#key#">#key#</a>
					</td>
					<td>#guid_prefix#</td>
					<td>#enteredby#</td>
					<td>#accn#</td>
					<td>#cat_num#</td>
					<td>#identification_1#</td>
				</tr>
			</cfloop>
		</table>
		<cfif seed.recordcount neq 1>
			<p>
				The seed barcode cannot be used for cloning.<cfabort>
			</p>
		</cfif>
		<p>
			Confirm that the seed above is the intended record. Enter one or more barcodes below, then click continue for confirmation. A clone of the seed will be created for each, the barcodes
			will be used as part_1_barcode of the clones. Note that the normal barcode checks will apply when records are created; eg you can use labels here, but you won't be able to
			create the records until you convert them to non-label types.
		</p>
		<form name="goClones" method="post" action="cloneWithBarcodes.cfm">
			<input type="hidden" name="action" value="confirmBarcodes">
			<input type="hidden" name="seed_id" value="#seed.key#">
			<label for="barcodes">Barcodes (comma-list, no spaces or other extraneous characters)</label>
			<textarea name="barcodes" class="hugetextarea"></textarea>
		<br><input type="submit" value="continue" class="lnkBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "confirmBarcodes">
	<cfoutput>
		<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select key,guid_prefix,enteredby,accn,cat_num,identification_1 from bulkloader where
			key=<cfqueryparam cfsqltype="cf_sql_varchar" value="#seed_id#">
		</cfquery>
		<cfif seed.recordcount is 0>
			Not found. <cfabort>
		</cfif>
		<p>
			Seed Summary
		</p>

		<table border>
			<tr>
				<th>key</th>
				<th>guid_prefix</th>
				<th>enteredby</th>
				<th>accn</th>
				<th>cat_num</th>
				<th>identification_1</th>
			</tr>
			<cfloop query="seed">
				<tr>
					<td>
						<a class="newWinLocal" href="/Bulkloader/browseBulk.cfm?key=#key#">#key#</a>
					</td>
					<td>#guid_prefix#</td>
					<td>#enteredby#</td>
					<td>#accn#</td>
					<td>#cat_num#</td>
					<td>#identification_1#</td>
				</tr>
			</cfloop>
		</table>
		<cfquery name="codes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				container_id,
				container_type,
				barcode,
				label,
				description,
				container_remarks,
				institution_acronym,
				width,
				height,
				length,
				dimension_units,
				getcontainerparentage(container_id) locStk
			from container where barcode in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#barcodes#" null="#Not Len(Trim(barcodes))#" list="true"> )
		</cfquery>
		<p>
			Supplied Barcodes Summary
		</p>
		<table border>
			<tr>
				<th>ID</th>
				<th>barcode</th>
				<th>container_type</th>
				<th>label</th>
				<th>description</th>
				<th>container_remarks</th>
				<th>institution_acronym</th>
				<th>W</th>
				<th>H</th>
				<th>L</th>
				<th>U</th>
				<th>Parentage</th>
			</tr>
			<cfloop query="codes">
				<tr>
					<td><a href="/findContainer.cfm?container_id=#container_id#" class="newWinLocal">#container_id#</a></td>
					<td>#barcode#</td>
					<td>#container_type#</td>
					<td>#label#</td>
					<td>#description#</td>
					<td>#container_remarks#</td>
					<td>#institution_acronym#</td>
					<td>#width#</td>
					<td>#height#</td>
					<td>#dimension_units#</td>
					<td>#length#</td>
					<td>#locStk#</td>
				</tr>
			</cfloop>
		</table>
		<cfif listlen(barcodes) neq codes.recordcount>
			<p>
				Some of the barcodes you provided were not found; you cannot continue.<cfabort>
			</p>
		</cfif>
		<p>
			Carefully confirm that the intended seed has been selected and the intended barcodes have been provided, then use the button below to finalize clone creation.
		</p>
		<form name="f" method="post" action="cloneWithBarcodes.cfm">
			<input type="hidden" name="action" value="finalCreateClones">
			<input type="hidden" name="seed_id" value="#seed_id#">
			<input type="hidden" name="barcodes" value="#barcodes#">
			<br><input type="submit" value="finalize clone creation" class="insBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "finalCreateClones">
	<cfoutput>
		<cftransaction>
	         <cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	            delete from bulkloader_clone
            </cfquery>
            <cfloop list="#barcodes#" index="i">
	            <cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	                insert into bulkloader_clone (select * from bulkloader where key=<cfqueryparam value="#seed_id#" cfsqltype="cf_sql_varchar">)
                </cfquery>
                <!--- should now have ONE record in clone with passed-in coid --->
                <cfquery name="fix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	                update
                        bulkloader_clone
                    set
                        key='key_'||nextval('sq_bulkloader'::regclass),
                        part_1_barcode=<cfqueryparam value="#trim(i)#" cfsqltype="cf_sql_varchar">
                    where
                        key=<cfqueryparam value="#seed_id#" cfsqltype="cf_sql_varchar">
                </cfquery>
	        </cfloop>
            <!--- move the new stuff over --->
            <cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                insert into bulkloader (select * from bulkloader_clone)
            </cfquery>
            <cfquery name="newIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                select key from bulkloader_clone
            </cfquery>
        </cftransaction>
		<p>
			Success! Use the button below to view the newly-created records and the "seed" record in browse-and-edit.
		</p>
		<form name="f" method="post" action="/Bulkloader/browseBulk.cfm">
			<input type="hidden" name="key" value="#valuelist(newIDs.key)#,#seed_id#">
			<br><input type="submit" value="view in browse-n-edit" class="lnkBtn">
		</form>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">