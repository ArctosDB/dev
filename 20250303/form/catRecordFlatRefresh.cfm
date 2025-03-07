<cfinclude template="/includes/_includeHeader.cfm">
<cfif not isdefined("table_name") or len(table_name) lt 1 or not REFind('[A-Za-z0-9_]', table_name)>>
	<cfthrow message="bad table_name to catRecordFlatRefresh.cfm">
</cfif>
<script>
	$(function() {
	    $('form').on('submit', function(e) {
	        $("#the_button").html('<img src="/images/indicator.gif" alt="thinking....">');
	    });
	});
</script>
<cfoutput>
	<cfif action is "nothing">
		<h3>Flat Cache Refresh Request</h3>

		<p>
			This form provides a means to request refreshing the cache. This should usually be automatic, please file an Issue if you've noticed a problem.
		</p>
		<p>
			NOTE: This form will not reprioritze; check flat status before attempting.			
		</p>
		<p>
			Large requests will time out, file an Issue for assistance. 
		</p>
		<p>
			Certain results preferences may cause failures, file an Issue for assistance.
		</p>
		<p>
			<form name="f" method="post" action="catRecordFlatRefresh.cfm">
				<input type="hidden" name="action" value="finalize">
				<input type="hidden" name="table_name" value="#table_name#">
				<div id="the_button">
					<input type="submit" class="savBtn" value="Got it, let's do this">
				</div>
			</form>
		</p>
	</cfif>
	<cfif action is "finalize">
		<!---- https://github.com/ArctosDB/PG/issues/30 - user request = 2 ---->
		<!---- https://github.com/ArctosDB/dev/issues/64 - run as user, manage_records has update on flat ---->
		<cfquery name="user_refresh_flat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
			update 
				flat 
			set 
				stale_flag=<cfqueryparam value="2" cfsqltype="cf_sql_int">,
				last_edited_table=<cfqueryparam value="user_request" cfsqltype="cf_sql_varchar">
			from 
				#table_name#
			where 
				flat.collection_object_id=#table_name#.collection_object_id and 
				flat.stale_flag not in (<cfqueryparam value="1,2,3,4,5,6,7,8,9,10" cfsqltype="cf_sql_int" list="true">)
		</cfquery>
		<h4>Success!</h4>
		<p>
			The request has been processed, check flat status for the latest.
		</p>
	</cfif>
</cfoutput>