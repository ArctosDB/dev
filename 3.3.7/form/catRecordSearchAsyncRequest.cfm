<cfinclude template="/includes/_includeHeader.cfm">
<style>
	.qvk{
		text-align: right;
		font-weight: bold;
	}
</style>
<cfoutput>
	<cfif action is "nothing">
		<h3>Data Request</h3>
		<p>
			This form provides a means to request data (in CSV format) that cannot be accessed through the standard search UI. Use of this form is limited, please carefully review the request below and revise as necessary before submitting. 
		</p>
		<p>
			NOTE: It is not necessary to submit the query to change this request. Simply close this overlay, change search parameters, and choose the data request option to revise.			
		</p>
		<p>
			Requests may be tracked though Async Requests (username tab).
		</p>
		<p>
			Please <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=[external+CONTACT]%20data%20request" class="external">contact us</a> if you have any questions or concerns, or if requests are not processing within 24 hours of submission.
		</p>

		<h4>Query Parameters</h4>
		<p>
			The following query parameters will be used in preparing your request:
		</p>
		<cfset soo=deSerializeJSON(so)>
		<table border>
			<tr>
				<th>Parameter</th>
				<th>Value</th>
			</tr>
			<cfloop collection="#soo#" item="key">
				<tr>
					<td><div class="qvk">#key#</div></td>
					<td>#soo[key]#</td>
				</tr>
			</cfloop>
		</table>

		<h4>Results Columns</h4>
		<p>
			The following columns will be included:
		</p>

		<table border>
			<tr>
				<th>Data Column</th>
			</tr>
			<cfloop list="#rc#" index="c">
				<tr>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>

		
		<h4>Finalize</h4>
		<form name="f" method="post" action="catRecordSearchAsyncRequest.cfm">
			<input type="hidden" name="action" value="finalize">
			<input type="hidden" name="rc" value="#rc#">
			<input type="hidden" name="so" value="#encodeforhtml(so)#">
			After carefully reviewing all information on this page, you may
			<input type="submit" class="insBtn" value="intiate the request">
		</form>
	</cfif>
	<cfif action is "finalize">
		<cfset theID='temp_catrecdata_#rereplace(createUUID(),'[^A-Za-z]','','all')#'>
		<cfquery name="create_async_request" datasource="uam_god">
			insert into cf_temp_async_job (
				internal_job_identifier,
				job,
				username,
				job_description,
				status,
				create_date,
				cr_data_cols,
				cr_data_params
			) values (
				<cfqueryparam value="#theID#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="catalog record data request" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#so# ==> #rc#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="new" cfsqltype="cf_sql_varchar">,
				current_date,
				<cfqueryparam value="#rc#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#so#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>

		<h4>Success!</h4>
		<p>
			Job #theID# has been successfully added to the queue. Please reference this ID in any correspondence.
		</p>
	</cfif>
</cfoutput>