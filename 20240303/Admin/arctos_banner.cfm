<!----
https://github.com/ArctosDB/dev/issues/97
---->
<!---- force-refresh cache---->
<cfquery name="g_a_t" datasource="uam_god" cachedwithin="#createtimespan(0,0,0,0)#">
	select announcement_text from arctos_banner where announcement_expires>=current_date
</cfquery>
<cfinclude template="/includes/_header.cfm">
<cfoutput>
	<cfif action is "nothing">
		<script language="javascript" type="text/javascript">
			jQuery(document).ready(function() {
				jQuery("##announcement_expires").datepicker();
			});
		</script>
		<cfset title="Arctos Banner: be careful in here!">
		<cfquery name="d" datasource="uam_god">
			select * from arctos_banner
		</cfquery>
		<h2>
			Arctos Banner
		</h2>
		<h3>You can break everything here. Please don't.</h3>
		<form method="post" action="arctos_banner.cfm" name="f" id="f" autocomplete="off">
			<input type="hidden" name="action" value="saveBanner">

			<div style="display:table">
				<div style="display:table-row">
					<div style="display:table-cell">
						<label for="announcement_text">announcement_text</label>
						<textarea name="announcement_text" id="announcement_text" rows="6" cols="50" class="hugetextarea">#d.announcement_text#</textarea>
					</div>
					<div style="display:table-cell; border:1px solid red;margin:1em;padding:1em;">
						announcement_text displays in header
						<p>
							IMPORTANT: links should include  target="_blank" and class="external" - like this:
							<br>&lt;a target="_blank" class="external" href="http://google.com"&gt;this is an HTML link to Google&lt;/a&gt;
						</p>
						<p>
							Loading this page clears the ColdFusion cache; you should be seeing current announcement_text
							after save. Your browser may be caching as well - hard-reload (probably shift-reload) this page
							and CAREFULLY confirm that the news is doing what you want and not breaking anything else before
							leaving.
						</p>
						<p>
							Experiment in test, not production.
						</p>
						<p>
							announcement_text will not display without an accompanying future announcement_expires value
						</p>
					</div>
				</div>
			<label for="announcement_expires">announcement_expires (show announcement_text through DATE)

			</label>
			<input type="text" name="announcement_expires" id="announcement_expires" size="80" value="#dateformat(d.announcement_expires,'YYYY-MM-DD')#">

			<p>
				<input type="submit" value="saveAll" class="savBtn">
			</p>
			</div>
		</form>

	</cfif>
		<!------------------------------------>
	<cfif action is "saveBanner">
		<cfquery name="flush" datasource="uam_god">
			delete from arctos_banner
		</cfquery>
		<cfquery name="d" datasource="uam_god">
			insert into arctos_banner (
				announcement_text,
				announcement_expires
			) values (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#announcement_text#">,
				<cfqueryparam CFSQLType="CF_SQL_DATE" value='#announcement_expires#'>
			)
		</cfquery>
		<cflocation url="arctos_banner.cfm?action=nothing" addtoken="false">
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">