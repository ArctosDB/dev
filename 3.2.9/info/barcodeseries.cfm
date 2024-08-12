
<cfinclude template="/includes/_header.cfm">
<cfset title="barcodes!">
<script>
	function deleteCSeries(key){
		var msg='Are you sure you want to delete this record?';
		msg+=' That is a Really Bad Idea if the series is used and not covered by another entry.';
		var r = confirm(msg);
		if (r == true) {
			document.location='barcodeseries.cfm?action=delete&key=' + key;
		}
	}
</script>

<div class="friendlyNotification">
	Don't want to deal with this form? <a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new/choose">File an Issue for assistance</a>.
</div>
<cfsavecontent variable="doc_barcodeseriessql">
	<div style="max-height:10em;overflow:scroll;">
		<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
		for help in writing SQL
		<p>
			"barcodeseriessql" is the SQL statement that MUST return true when analyzed against any barcode in the intended series, and false
			against any other string. It is evaluated as "select count(*)  where {whatever_you_type}". That MUST return
			1 for all of your intended barcodes, and 0 for any other.
		</p>
		<p>
			Anything that's a valid PSQL statement may be used for testing. There are many ways to test most everything.
		</p>
		<p>
			Use "barcode" (lower-case) as the SQL variable representing the each barcode.
		</p>
		Examples:

		<table border>
			<tr>
				<th>Series</th>
				<th>SQL (what to type)</th>
				<th>What's it mean?</th>
			</tr>
			<tr>
				<td>1</td>
				<td>barcode='1'</td>
				<td>Equality tests come with no surprises; this is ideal.</td>
			</tr>
			<tr>
				<td>1</td>
				<td>barcode~'[0-9]*'</td>
				<td>
					"1" is a number, matches the regular expression, and your intended barcodes will pass -
					as will all other numbers. This is a very bad choice.
				</td>
			</tr>
			<tr>
				<td>
					ABC123 - ABC456
				</td>
				<td>
					barcode~'^ABC[0-9]{3}' and to_number(substr(barcode,4)) between 123 and 456
				</td>
				<td>
					First, consider claiming the entire "ABC{number}" series (but coordinate large "grabs" with the Arctos community).
					<ul>

						<li>
							<strong>barcode,</strong> - "barcode" (the variable, not the string) is the subject of the evaluation
						</li>
						<li>
							<strong>~</strong> is PGSQL for "regexp_like"
						</li>
						<li>
							<strong>'^</strong> - "anchor" to the beginning of the string
						</li>
						<li>
							<strong>ABC</strong> - the next (from the beginning) three characters must be "ABC"
						</li>
						<li>
							<strong>[0-9]</strong> - any number
						</li>
						<li>
							<strong>{3}</strong> - three of the proceeding (so three numbers)
						</li>

						<li>
							<strong>to_number(</strong> - convert some CHAR data to NUMBER (or fail if a conversion is not possible)
						</li>
						<li>
							<strong>substr(</strong> - extract some characters
						</li>
						<li>
							<strong>barcode,</strong> - variable from which to extract
						</li>
						<li>
							<strong>4)</strong> - "start at the 4th character and proceed to the end of the data"
						</li>
						<li>
							<strong>between 123 and 456</strong> - shortcut for "greater than or equal to 4th-and-subsequent characters
							 AND less than or equal to 4th-and-subsequent characters"
						</li>
					</ul>
				</td>
			</tr>
		</table>
	</div>
</cfsavecontent>
<cfoutput>
	<!------------------------------------------------->
	<cfif action is "delete">
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_barcodeseries where key=#val(key)#
		</cfquery>
		<cfif d.whodunit is not session.username>
			Only #d.whodunit# may edit this record.
			<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a> to update.
			<cfabort>
		</cfif>
		<cfquery name="dlt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_barcodeseries where key=#key#
		</cfquery>
		<cflocation url="barcodeseries.cfm" addtoken="false">
	</cfif>
	<!------------------------------------------------->
	<cfif action is "saveNew">
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_barcodeseries (
				barcodeseriessql,
				barcodeseriestxt,
				institution,
				notes,
				createdate,
				whodunit
			) values (
				<cfqueryparam value="#barcodeseriessql#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#barcodeseriestxt#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#institution#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#notes#" CFSQLType="cf_sql_varchar">,
				current_date,
				<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			)
		</cfquery>
		<cflocation url="barcodeseries.cfm" addtoken="false">
	</cfif>
	<!------------------------------------------------->
	<cfif action is "saveEdit">
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_barcodeseries set
				barcodeseriessql=<cfqueryparam value="#barcodeseriessql#" CFSQLType="cf_sql_varchar">,
				barcodeseriestxt=<cfqueryparam value="#barcodeseriestxt#" CFSQLType="cf_sql_varchar">,
				notes=<cfqueryparam value="#notes#" CFSQLType="cf_sql_varchar">
			where
				key=#key#
		</cfquery>
		<cflocation url="barcodeseries.cfm?action=edit&key=#key#" addtoken="false">
	</cfif>

	<!------------------------------------------------->
	<cfif action is "edit">
		<p>
			<a href="barcodeseries.cfm">back to table</a>
		</p>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_barcodeseries where key=#val(key)#
		</cfquery>
		<cfif d.whodunit is not session.username>
			<cfquery name="sc" datasource="uam_god">
				select count(*) c from (
					WITH RECURSIVE cte AS (
					             SELECT pg_roles.oid,
					                pg_roles.rolname
					               FROM pg_roles
					              WHERE upper(pg_roles.rolname) = '#ucase(d.whodunit)#'
					            UNION ALL
					             SELECT m.roleid,
					                pgr.rolname
					               FROM cte cte_1
					                 JOIN pg_auth_members m ON m.member = cte_1.oid
					                 JOIN pg_roles pgr ON pgr.oid = m.roleid
					            )
					     SELECT rolname from cte where upper(rolname) in (select upper(replace(collection.guid_prefix,':','_')) from collection)
					and rolname in (
					WITH RECURSIVE cte AS (
					             SELECT pg_roles.oid,
					                pg_roles.rolname
					               FROM pg_roles
					              WHERE upper(pg_roles.rolname) = '#ucase(session.username)#'
					            UNION ALL
					             SELECT m.roleid,
					                pgr.rolname
					               FROM cte cte_1
					                 JOIN pg_auth_members m ON m.member = cte_1.oid
					                 JOIN pg_roles pgr ON pgr.oid = m.roleid
					            )
					     SELECT rolname from cte where upper(rolname) in (select upper(replace(collection.guid_prefix,':','_')) from collection)
					     )
					    )x
 			</cfquery>
			<div class="importantNotification">
				<cfif not sc.c gt 0>
					You do not have access to edit this record. Only users who share collections with the creator may edit.<cfabort>
				<cfelse>
					You may edit this record, but proceed with caution.
				</cfif>
			</div>
		</cfif>
		<form name="t" method="post" action="barcodeseries.cfm">
			<input type="hidden" name="action" value="saveEdit">
			<input type="hidden" name="key" value="#d.key#">
			<div style="border:1px solid black; margin:1em; padding:1em">
				<label for="barcodeseriessql">
					SQL
				</label>
				<textarea class="hugetextarea reqdClr" name="barcodeseriessql" >#d.barcodeseriessql#</textarea>
				#doc_barcodeseriessql#
			</div>
			<label for="barcodeseriestxt">
				Text - type a clear human-readable (and sortable) description of the series you are claiming
			</label>
			<textarea class="hugetextarea reqdClr" name="barcodeseriestxt">#d.barcodeseriestxt#</textarea>
			<label for="institution">institution</label>
			<br>#d.INSTITUTION#
			<br>
			<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a> to change institution.
			<label for="notes">
				Notes
			</label>
			<textarea class="hugetextarea reqdClr" name="notes">#d.notes#</textarea>
			<br><input type="submit" value="save edits" class="savBtn">
		</form>
	</cfif>
	<!------------------------------------------------->
	<cfif action is "new">
		<cfquery name="ctinstitution" datasource="uam_god">
			select distinct institution_acronym from collection order by institution_acronym
		</cfquery>

		<form name="t" method="post" action="barcodeseries.cfm">
			<input type="hidden" name="action" id="action" value="saveNew">
			<div style="border:1px solid black; margin:1em; padding:1em">
				<label for="barcodeseriessql">
					SQL
				</label>
				<textarea class="hugetextarea" name="barcodeseriessql"></textarea>
				#doc_barcodeseriessql#
			</div>
			<label for="barcodeseriestxt">
				Text - type a clear human-readable (and sortable) description of the series you are claiming
			</label>
			<textarea class="hugetextarea" name="barcodeseriestxt"></textarea>
			<label for="institution">institution</label>
			<select name="institution">
				<option value="">pick one</option>
				<cfloop query="ctinstitution">
					<option value="#institution_acronym#">#institution_acronym#</option>
				</cfloop>
			</select>
			<label for="notes">
				Notes
			</label>
			<textarea class="hugetextarea" name="notes"></textarea>
			<input type="submit" value="create">
		</form>
	</cfif>

	<!------------------------------------------------->
	<cfif action is "nothing">
		<script src="/includes/sorttable.js"></script>
			

		<p>
			<a href="barcodeseries.cfm?action=changelog">view changelog</a>
		</p>
		<p>
			<a href="barcodeseries.cfm?action=new">stake a claim</a>
		</p>

		<p>
			Claim barcodes and barcode series.
			<ul>
				<li>
					Review container documentation, especially
					<span class="helpLink" data-helplink="container_purchase">container purchase guidelines</span>
					, before doing anything here.</li>
				<li>
					<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
					 if you need help with any part of the barcoding process or anything in Arctos,
					including this form.
				</li>
				<li>
					If you claim XYZ1 through XYZ5, don't be surprised if someone else claims XYZ6. Claim what you might need,
					not only what you currently have.
				</li>
				<li>Don't be "that person"; contact the XYZ-folks before claiming what might be part of an intended series.</li>
				<li>
					Don't be redundant. If you already own XYZ1 through XYZ5 and you buy XYZ6 through XYZ10, edit the original
					 entry rather than adding a new entry. This thing is already hard enough to read!
				</li>
			</ul>
		</p>
		<div class="importantNotification">
			IMPORTANT: This form will (probably) allow claims which cannot be used to create containers.
			Most characters other than letters and numbers are disallowed by container rules, but will pass this form.
			<a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5Bexternal+CONTACT%5D" class="external">Contact us</a> <strong>before</strong> purchasing or printing if you have any questions or concerns.
		</div>

		<div style="margin:1em;padding:1em;border:2px solid black">
			Test a barcode against existing claims. This form can be used to determine if a barcode is part of an existing series
			 (e.g., is the series definition correct?), and as a way to explore the possibility of creating a new series. After submitting the
			 form, this page will reload with something in the STATUS column. PASS (and the row turning green) indicates that the tested barcode
			 is part of the series. Anything else in STATUS indicates that the barcode is not part of the series. (Various error
			 messages are displayed as a diagnostic aid; they may make sense when creating a new series.)


			<cfparam name="barcode" default="">
			<form name="t" method="get" action="barcodeseries.cfm">
				<label for="barcode">Enter a barcode to test</label>
				<input type="text" value="#barcode#" name="barcode">
				<input type="submit" value="test this barcode">
			</form>
		</div>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_barcodeseries order by barcodeseriestxt
		</cfquery>
		<p>
			Claimed barcodes (and test results if you entered something in the form; HINT: sort by match).
		</p>
		<table border id="t2" class="sortable">
			<tr>
				<th>match</th>
				<th>edit</th>
				<th>Txt</th>
				<th>sql</th>
				<th>status</th>
				<th>statusSQL</th>
				<th>Inst</th>
				<th>Created</th>
				<th>Edited</th>
				<th>Note</th>
			</tr>
			<cfloop query="d">
				<cfset tststts="">
				<cfif len(barcode) gt 0>
					<cftry>
					<cfset statusSQL=replace(barcodeseriessql,"barcode","'#barcode#'","all")>
					<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select count(*) c  where #preserveSingleQuotes(statusSQL)#
					</cfquery>
					<cfif t.c gt 0>
						<cfset tststts='PASS'>
					<cfelse>
						<cfset tststts='FAIL (count: #t.c#)'>
					</cfif>
					<cfcatch>
						<cfset m=cfcatch.detail>
						<cfset m=replace(m,'[Macromedia][Oracle JDBC Driver][Oracle]','','all')>
						<cfset tststts='FAIL: #m#'>
					</cfcatch>
					</cftry>
				<cfelse>
					<cfset statusSQL='Enter a barcode in the form above to test'>
					<cfset tststts='-'>
				</cfif>
				<tr <cfif tststts is "PASS"> style="background:##b3ffb3;"</cfif>>
					<td>#tststts#</td>
					<td>
						<a href="barcodeseries.cfm?action=edit&key=#key#">edit</a>
						<span class="likeLink" onclick="deleteCSeries('#key#')">delete</span>
					</td>
					<td>
						#barcodeseriestxt#
					</td>
					<td>#barcodeseriessql#</td>
					<td>#tststts#</td>
					<td>#statusSQL#</td>
					<td>#institution#</td>
					<td>#whodunit# @ #createdate#</td>
					<td>#last_edit_by# @ #last_edit_date#</td>
					<td>#notes#</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
	<cfif action is "changelog">
				<cfquery name="log_cf_barcodeseries" datasource="uam_god">
					select * from log_cf_barcodeseries
				</cfquery>
				<p>
						<a href="barcodeseries.cfm?action=nothing">main</a>
				</p>
				<table border id="t3" class="sortable">
					<tr>
						<th>institution</th>
						<th>barcodeseriestxt</th>
						<th>barcodeseriessql</th>
						<th>notes</th>
						<th>createdate</th>
						<th>createdby</th>
						<th>changed_by_user</th>
						<th>changed_on_date</th>
					</tr>
					<cfloop query="log_cf_barcodeseries">
						<tr>
							<td>#institution#</td>
							<td>#barcodeseriestxt#</td>
							<td>#barcodeseriessql#</td>
							<td>#notes#</td>
							<td>#createdate#</td>
							<td>#whodunit#</td>
							<td>#changed_by_user#</td>
							<td>#changed_on_date#</td>
						</tr>
					</cfloop>
				</table>

			</cfif>


</cfoutput>
<cfinclude template="/includes/_footer.cfm">