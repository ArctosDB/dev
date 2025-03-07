<cfinclude template="/includes/_includeHeader.cfm">
<cfoutput>
<!---- let this also pick piblicationID, init use multiIdentification ---->
<cfparam name="mode" default="">
<cfif mode is 'pubguidpicker'>
	<script>
		function useThisOne(pid,ps){
			parent.$("###pubStringFld#").val('https://arctos.database.museum/publication/' + pid);
			closeOverlay('findPublication');
			//parent.$("###pubIdFld#").val(pid);
			//parent.$("###pubStringFld#").val(ps).removeClass('badPick').addClass('goodPick');
			///parent.$(".ui-dialog-titlebar-close").trigger('click');
		}
	</script>
<cfelse>
	<script>
		function useThisOne(pid,ps){
			parent.$("###pubIdFld#").val(pid);
			parent.$("###pubStringFld#").val(ps).removeClass('badPick').addClass('goodPick');
			parent.$(".ui-dialog-titlebar-close").trigger('click');
		}
	</script>
</cfif>
	<cfparam name="publication_title" default="">
	<!--- make sure we're searching for something --->
	<form name="searchForPub" action="findPublication.cfm" method="post">
		<label for="publication_title">Publication Title</label>
		<input type="text" name="publication_title" id="publication_title" value="#publication_title#">
		<input type="submit"
			value="Search"
			class="lnkBtn"
			onmouseover="this.className='lnkBtn btnhov'"
			onmouseout="this.className='lnkBtn'">
		<cfoutput>
			<input type="hidden" name="pubIdFld" value="#pubIdFld#">
			<input type="hidden" name="pubStringFld" value="#pubStringFld#">
		</cfoutput>
	</form>
	<cfif len(publication_title) gt 0>
		<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				publication_id,
				full_citation,
				short_citation
			FROM
				publication
			WHERE
				UPPER(regexp_replace(full_citation,'<[^>]*>','','g')) LIKE <cfqueryparam value = "%#trim(ucase(publication_title))#%" CFSQLType="CF_SQL_VARCHAR"> or
				UPPER(regexp_replace(short_citation,'<[^>]*>','','g')) LIKE <cfqueryparam value = "%#trim(ucase(publication_title))#%" CFSQLType="CF_SQL_VARCHAR">
			ORDER BY
				full_citation
		</cfquery>

		<cfif getPub.recordcount is 0>
			Nothing matched <strong>#publication_title#</strong>
		<cfelseif getPub.recordcount is 1>
			<script>
				useThisOne('#getPub.publication_id#','#replace(getPub.short_citation,"'","`","all")#');
			</script>
		<cfelse>
			<table border>
				<tr>
					<td>Title</td>
				</tr>
				<cfloop query="getPub">
					<tr>
						<td>
							<span class="likeLink" onclick="useThisOne('#publication_id#','#replace(getPub.short_citation,"'","`","all")#');">
								#short_citation#
							</span>
							<blockquote>
								#full_citation#
							</blockquote>
						</td>
					</tr>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">