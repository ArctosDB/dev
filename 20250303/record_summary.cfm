<cfinclude template="/includes/_header.cfm">
<cfset title='Catalog Record Summary'>

<script src="/includes/sorttable.js"></script>
<cfquery name="cf_cat_rec_summary_cols"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select * from cf_cat_rec_summary_cols order by column_order
</cfquery>
<script>
	function getCSV(){
		$("#get_csv").val('true');
		$("#qfrm").submit();
	}
	function clear_csv_request(){
		$("#get_csv").val('false');

	}
	setInterval(clear_csv_request, 5000);
	function getGuidPrefix(){
		var gps=$("#guid_prefix").val();
		//console.log(gps);
		var guts = "/picks/pickMultiGuidPrefix.cfm?gps="+gps;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'top'],
			title: 'Choose',
				width:1200,
	 			height:600,
			close: function() {
				$( this ).remove();
			}
		}).width(1200-10).height(600-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}

	function getParamaterizedURL(){
		var fary = $("#qfrm input[type=text]").serializeArray();
		var dataObj = {};
		$(fary).each(function(i, field){
		  dataObj[field.name] = field.value;
		});
		$.each(dataObj, function(key, value){
		    if (value === "" || value === null){
		        delete dataObj[key];
		    }
		});
		var urlparams='';
		$.each(dataObj, function( k, v ) {
			urlparams+='&'+ k + '=' + v;
		});
		urlparams=urlparams.substring(1);
		urlparams='/record_summary.cfm?' + urlparams;
		var cbary = [];
		$("input:checkbox[name=result_columns]:checked").each(function(){
    		cbary.push($(this).val());
    	});
		var cbs=cbary.join(',');
		urlparams+='&result_columns=' + cbs;
		//console.log(urlparams);
		window.location=urlparams;
	}
	jQuery(document).ready(function() {
		$('html, body').animate({
		    scrollTop: $('#rsltsmry').offset().top
		}, 1000);
	});
</script>
<cfoutput>
	<h3>Catalog Record Summary</h3>
	<p>
		Summary of catalog records. 
		<ul>
			<li>Search column is search parameters; prefix with = for exact match and best performance, otherwise substring.</li>
			<li>Check Results column to include in summary</li>
		</ul>
	</p>
	<cfparam name="result_columns" default="">
	<form id="qfrm" name="qfrm" method="post" action="record_summary.cfm">
		<input type="hidden" name="get_csv" id="get_csv" value="false">
		<table border="1">
			<tr>
				<th>Field</th>
				<th>Search</th>
				<th>Results</th>
				<th>Description</th>
			</tr>
			<cfloop query="cf_cat_rec_summary_cols">
				<tr>
					<td>
						#display#
					</td>
					<td>
						<cfif queryable is 1>
							<cfparam name="#obj_name#" default="">
							<input type="text" name="#obj_name#" id="#obj_name#" value="#evaluate(obj_name)#">
						<cfelse>
							<cfparam name="#obj_name#" default="">
							<input type="hidden" name="#obj_name#" id="#obj_name#" value="">
							
						</cfif>
					</td>
					<td>
						<input type="checkbox" class="hugecheckbox" name="result_columns" value="#obj_name#" <cfif listFindNoCase(result_columns, obj_name)> checked="checked"</cfif> >
					</td>
					<td>
						<cfif obj_name is 'guid_prefix'>
							<input type="button" class="picBtn" value="choose" onclick="getGuidPrefix();">
						</cfif>
						#description#
					</td>
				</tr>
			</cfloop>
		</table>
		<input type="submit" value="Query" class="lnkBtn">
	</form>
	<cfset canquery=false>
	<cfif len(result_columns) gt 0>
		<cfloop query="cf_cat_rec_summary_cols">
			<cfset x=evaluate(obj_name)>
			<cfif len(x) gt 0>
				<cfset canquery=true>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>
	<cfif canquery is true>
		<cfset grpby="">
		<cfquery name="qry_rslt"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="55" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select
			count(*) as record_count,
			<cfset i=0>
			<cfloop query="cf_cat_rec_summary_cols">
				<cfif listfindnocase(result_columns,obj_name)>
					<cfset i=i+1>
					<cfif obj_name is 'link_to_records'>
						'#Application.serverRootURL#/search.cfm?guid=' || #replace(sql_element,'flatTableName',session.flatTableName)# as #obj_name#<cfif i lt listlen(result_columns)>,</cfif>
					<cfelse>
						#replace(sql_element,'flatTableName',session.flatTableName)# as #obj_name#<cfif i lt listlen(result_columns)>,</cfif>
					</cfif>

					<cfif obj_name is not "individualcount" and obj_name is not "link_to_records">
						<cfset grpby=listAppend(grpby, obj_name)>
					</cfif>
				</cfif>
			</cfloop>
			from #session.flatTableName#
			where 1=1
			<cfloop query="cf_cat_rec_summary_cols">
				<cfset qval=evaluate(obj_name)>
				<cfif len(qval) gt 0>
					and #obj_name# 
					<cfif obj_name is 'guid_prefix'>
						in (  <cfqueryparam value="#qval#" cfsqltype="cf_sql_varchar" list="true"> )
					<cfelseif left(qval,1) is '='>
						<cfset qval=right(qval,len(qval)-1)>
						ilike <cfqueryparam value="#qval#" cfsqltype="cf_sql_varchar">
					<cfelse>
						ilike <cfqueryparam value="%#qval#%" cfsqltype="cf_sql_varchar">
					</cfif>
				</cfif>
			</cfloop>
			group by
			#grpby#
			order by 
			#grpby#
		</cfquery>
		<!----
		<cfdump var="#qry_rslt#">
		<cfdump var="#qry_rslt#">
		---->
		<cfif qry_rslt.recordcount gt 0>
			<cfquery name="smry" dbtype="query">
				select sum(record_count) as src from qry_rslt
			</cfquery>
			<div id="rsltsmry">
				#smry.src# records in #qry_rslt.recordcount# groups
			</div>
			<input type="button" value="download CSV" class="lnkBtn" onclick="getCSV();">
			<input type="button" value="Reload with sharable URL" class="lnkBtn" onclick="getParamaterizedURL();">
			<table border="1" class="sortable" id="tblRslt">
				<tr>
					<th>RecordCount</th>
					<cfloop query="cf_cat_rec_summary_cols">
						<cfif listfindnocase(result_columns,obj_name)>
							<th>#display#</th>
						</cfif>
					</cfloop>
				</tr>
				<cfloop query="qry_rslt">
					<tr>
						<td>#record_count#</td>
						<cfloop query="cf_cat_rec_summary_cols">
							<cfif listfindnocase(result_columns,obj_name)>
								<cfif obj_name is 'link_to_records'>
									<cfset thisVal=evaluate("qry_rslt." & obj_name)>
									<cfset thisVal='<a class="external" href="#thisVal#">[ open ]</a>'>
								<cfelse>
									<cfset thisVal=evaluate("qry_rslt." & obj_name)>
								</cfif>
								<td>#thisVal#</td>
							</cfif>
						</cfloop>
					</tr>
				</cfloop>
			</table>
			<cfif isdefined("get_csv") and get_csv is "true">
				<cfset flds=qry_rslt.columnlist>
				<cfset  util = CreateObject("component","component.utilities")>
				<cfset csv = util.QueryToCSV2(Query=qry_rslt,Fields=flds)>
				<cffile action = "write"
		    		file = "#Application.webDirectory#/download/catalog_record_summary.csv"
	    			output = "#csv#"
	    			addNewLine = "no">
				<cflocation url="/download.cfm?file=catalog_record_summary.csv" addtoken="false">
			</cfif>
		<cfelse>
			<div id="rsltsmry">
				Nothing found; please adjust the query and try again.
			</div>
		</cfif>
	</cfif>
</cfoutput>

<cfinclude template="/includes/_footer.cfm">