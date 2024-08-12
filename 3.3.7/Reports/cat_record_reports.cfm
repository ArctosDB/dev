<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<cfset title="Transarctos Unified Reporting Directive">
	<script src="/includes/sorttable.js"></script>
	<script>
		$(document).ready(function() {
			// allow shift-click to select multiple rows
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
		});
		function showPageThingee(pgs,cpg){
			console.log(pgs);
			console.log(cpg);
			var opts='';
			for (var n = 1; n <= pgs; ++ n){
				opts+='<option  ';
				if (n==cpg){
					opts+=' selected="selected" ';
				}
				opts+=' value="' + n + '">' + n + '</option>';
			}
			console.log(opts);
			$('#pg_number').empty().append(opts);
		}
	</script>
	<style>
		.subheader {
			font-size: small;
			font-style: italic;
			margin-left: 3em;
		}
		.frow {
			display: flex;
		}
		.fcolumn {
			justify-content: flex-start;
			margin:.1em;
			padding: .1em;
		}
		@media screen and (max-width: 800px) {
			.frow {
				flex-direction: column;
			}
		}
	</style>
	<h3>
		Transarctos Unified Reporting Directive
		<div class="subheader">Records that could use a little polish</div>
	</h3>
	<p>
		This report finds catalog record related problems. Click headers to sort. manage_collection users may delete. Reports are generated periodically, generally about monthly.
	</p>
	<cfquery name="coln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection group by guid_prefix order by guid_prefix
	</cfquery>
	<cfquery name="qreport_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select report_name from cat_record_reports group by report_name order by report_name
	</cfquery>
	<cfoutput>
		<cfparam name="guid_prefix" default="">
		<cfparam name="report_name" default="">
		<cfparam name="txt_srch" default="">
		<cfparam name="pg_size" default="2500">
		<cfparam name="pg_number" default="1">
		<form name="filter" id="filter" method="get" action="cat_record_reports.cfm">
			<div class="frow">
				<div class="fcolumn">
					<label for="guid_prefix">GUID Prefix</label>
					<cfset gp=guid_prefix>
					<select name="guid_prefix" id="guid_prefix">
						<option value=""></option>
						<cfloop query="coln">
							<option <cfif gp is coln.guid_prefix> selected="selected" </cfif> value="#coln.guid_prefix#">#coln.guid_prefix#</option>
						</cfloop>
					</select>
				</div>
				<div class="fcolumn">
					<label for="report_name">Report</label>
					<cfset tr=report_name>
					<select name="report_name" id="report_name" class="">
						<option value=""></option>
						<cfloop query="qreport_name">
							<option <cfif tr is qreport_name.report_name> selected="selected" </cfif> value="#qreport_name.report_name#">#qreport_name.report_name#</option>
						</cfloop>
					</select>
				</div>
			</div>
			<div class="frow">
				<div class="fcolumn">
					<label for="txt_srch">Search</label>
					<input type="text" name="txt_srch" size="50" value="#encodeforhtml(txt_srch)#">
				</div>
				<div class="fcolumn">
					<label for="pg_size">Page Size</label>
					<select name="pg_size" id="pg_size" class="">
						<option <cfif pg_size is 500> selected="selected" </cfif> value="500">500</option>
						<option <cfif pg_size is 2500> selected="selected" </cfif> value="2500">2500</option>
					</select>
				</div>
			</div>
			<div class="frow">
				<div class="fcolumn">
					<input type="submit" value="filter" class="lnkBtn">
					<a href="/Reports/cat_record_reports.cfm"><input type="button" value="clear" class="clrBtn"></a>
				</div>
				<div class="fcolumn">
				</div>
			</div>
		</form>
		<cfif len(guid_prefix) gt 0 or len(report_name) gt 0 or len(txt_srch) gt 0>
			<cfset pgoffset=(pg_size * pg_number) - pg_size>
			<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * , count(*) OVER() AS full_count from temp_cache.cat_record_reports where 1=1
				<cfif len(guid_prefix) gt 0>
					 and guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(report_name) gt 0>
					and report_name=<cfqueryparam value="#report_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(txt_srch) gt 0>
					and (
						report_summary ilike <cfqueryparam value="%#txt_srch#%" CFSQLType="CF_SQL_VARCHAR"> or
						report_detail ilike <cfqueryparam value="%#txt_srch#%" CFSQLType="CF_SQL_VARCHAR">
					)
				</cfif>
				limit #pg_size# offset #pgoffset#
			</cfquery>

			<cfif isdefined('getCSV') and getCSV is true>
				<cfset flds=raw.columnlist>
				<cfif listfindnocase(flds,'full_count')>
					<cfset flds=listdeleteat(flds,listfindnocase(flds,'full_count'))>
				</cfif>
				<cfset  util = CreateObject("component","component.utilities")>
				<cfset csv = util.QueryToCSV2(Query=raw,Fields=flds)>
				<cffile action = "write"
				    file = "#Application.webDirectory#/download/turd.csv"
				    	output = "#csv#"
				    	addNewLine = "no">
				<cflocation url="/download.cfm?file=turd.csv" addtoken="false">
			</cfif>

			<hr>
				#raw.full_count# matches
				<cfif raw.full_count is 0 and pg_size gt 1>
					-check page size-
				</cfif>
				<cfif raw.full_count gt pg_size>
					<cfset numPages=ceiling(raw.full_count/pg_size)>
					Page: 
					<cfloop from="1" to="#numPages#" index="pg">
						<cfif pg is pg_number>
							[#pg#]
						<cfelse>
							<a href="/Reports/cat_record_reports.cfm?guid_prefix=#guid_prefix#&report_name=#encodeforhtml(report_name)#&txt_srch=#encodeforhtml(txt_srch)#&pg_size=#pg_size#&pg_number=#pg#"><input type="button" value="#pg#"></a>
						</cfif>
					</cfloop>
				</cfif>
			<hr>
			<cfif listfindnocase(session.roles,'manage_collection')>
				<form name="getcsv" method="post" action="cat_record_reports.cfm">
					<input type="submit" name="dcsvsbtn" class="lnkBtn" value="CSV">
					<input type="hidden" name="guid_prefix" value="#guid_prefix#">
					<input type="hidden" name="report_name" value="#report_name#">
					<input type="hidden" name="txt_srch" value="#encodeForHTML(txt_srch)#">
					<input type="hidden" name="pg_size" value="#pg_size#">
					<input type="hidden" name="pg_number" value="#pg_number#">
					<input type="hidden" name="getCSV" value="true">
				</form>
			</cfif>
			<form name="drpt" method="post" action="cat_record_reports.cfm">
				<cfif listfindnocase(session.roles,'manage_collection')>
					<input type="submit" name="dsbtn" class="delBtn" value="Delete Checked">
					<input type="hidden" name="action" value="deleteChecked">
					<input type="hidden" name="guid_prefix" value="#guid_prefix#">
					<input type="hidden" name="report_name" value="#report_name#">
				</cfif>
				<table border class="sortable" id="tbl">
					<tr>
						<th></th>
						<th>guid</th>
						<th>report_name</th>
						<th>report_summary</th>
						<th>report_detail</th>
						<th>generated_date</th>
					</tr>
					<cfloop query="raw">
						<tr>
							<td><input type="checkbox" name="cat_record_report_id" value="#cat_record_report_id#"></td>
							<td><a class="external" href="/guid/#guid#">#guid#</a></td>
							<td>#report_name#</td>
							<td>#report_summary#</td>
							<td>#report_detail#</td>
							<td>#generated_date#</td>
						</tr>
					</cfloop>
				</table>
			</form>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "deleteChecked">
  	<cfif not listfindnocase(session.roles,'manage_collection')>
  		nope<cfabort>
  	</cfif>
	<cfquery name="diediedie" datasource="uam_god">
       	delete from cat_record_reports
		where cat_record_report_id in (<cfqueryparam value="#cat_record_report_id#" CFSQLType="cf_sql_int" list="true"> )
	</cfquery>
	<cflocation url="cat_record_reports.cfm?guid_prefix=#guid_prefix#&report_name=#report_name#" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">