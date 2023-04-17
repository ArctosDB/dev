<!----



create table cf_temp_locality_attributes (
	key serial not null,
	locality_name varchar not null,
	attribute_type varchar(60) not null,
	attribute_value varchar not null,
	attribute_units varchar,
	attribute_determiner varchar,
	attribute_remark varchar,
	determination_method varchar,
	determined_date varchar,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar
);

grant select,insert,update,delete on cf_temp_locality_attributes to manage_collection;

grant select, usage on cf_temp_locality_attributes_key_seq to public;

---->




<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="Bulkload Locality Attributes">

<cfset recordLimit=2500>

<cfparam name="status" default="">
<cfparam name="username" default="">

<cfif not listcontainsnocase(session.roles,"manage_collection")>
	Manage Collection is required to access this form.<cfabort>
</cfif>
<cfif action is "nothing">
	<style>
		.inlinedocs{
			border:2px solid green;
			margin:1em;
			padding:1em;
		}
	</style>
	<cfoutput>

		<div class="inlinedocs">
			<p>
				Bulkload Locality Attributes: inline docs
			</p>
			<p>
				Visit <a href="bulkloadLocalityAttributes.cfm?action=ld">Load from CSV</a> for field documentation and a template.
			</p>
			<p>
				Click links in the table below to change status, which can cause records to validate and load.
				Note that there are controls for by-user operations, and by-user-and-status.
			</p>
			<p>
				Managing status is limited to #recordLimit# records, you may need to use status to organize the data into manageable chunks.
			</p>
			<p>
				You may manage data for users in your collection(s) with this form. These data may have been uploaded directly, or come from Data Entry Extras.
			</p>
			<p>
				A status beginning with "autoload" (examples: "autoload", "autoload: this part is ignored") will queue records to be checked and loaded.
				All other values are ignored by automation. You may use status to flag records for various reasons. Loading may happen at any time, including
				while records are being reviewed; change status to autoload% with care. Records are deleted as they load.
			</p>
			<p>
				It is advisable to download CSV before changing anything with this form.
			</p>
		</div>


		<cfquery name="usrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				count(*) c,
				username,
				status
			from
				cf_temp_locality_attributes
			where
				lower(username) in (
			       select unnest(string_to_array(get_share_collection_user_noactives(array_to_string(has_roles,',') ),',')) from current_user_roles
			)
			group by username,status
			order by username
		</cfquery>



		<h4>In-process data</h3>


		<cfquery name="du" dbtype="query">
			select distinct username from usrs order by username
		</cfquery>



		<table border>
			<tr>
				<th>User</th>
				<th>Ctl</th>
				<td>Bits-n-Pieces</td>
			</tr>
			<cfloop query="du">
				<tr>
					<td>
						#username#
					</td>
					<td>
						<a href="bulkloadLocalityAttributes.cfm?action=table&username=#username#">change status</a>
						<br><a href="bulkloadLocalityAttributes.cfm?action=csv&username=#username#">get CSV</a>
						<br><a href="bulkloadLocalityAttributes.cfm?action=preDel&username=#username#">delete</a>
					</td>
					<td>
						<cfquery name="tu" dbtype="query">
							select status,c from usrs where username='#username#' order by status
						</cfquery>
						<table border>
							<tr>
								<th>Status</th>
								<th>Count</th>
								<th>Ctl</th>
							</tr>
							<cfloop query="tu">
								<tr>
									<td>#status#</td>
									<td>#c#</td>
									<td>
										<a href="bulkloadLocalityAttributes.cfm?action=table&username=#username#&status=#status#">change status</a>
										<br><a href="bulkloadLocalityAttributes.cfm?action=csv&username=#username#&status=#status#">get CSV</a>
										<br><a href="bulkloadLocalityAttributes.cfm?action=preDel&username=#username#&status=#status#">delete</a>
									</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
	</cfoutput>
</cfif>

<!------------------------------------------------------->
<cfif action is "yesDel">
	<cfoutput>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
       	delete from cf_temp_locality_attributes
		where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
		<cfif len(status) gt 0>
			and status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar" list="false">
		</cfif>
	</cfquery>

	<p>
		Delete successful.
	</p>
	<p>
		<a href="bulkloadLocalityAttributes.cfm">continue</a>
	</p>

	</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif action is "preDel">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	select status,username,count(*) c
 			from cf_temp_locality_attributes
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif len(status) gt 0>
				and status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar" list="false">
			</cfif>
			group by status,username
		</cfquery>


		<table border>
			<tr>
				<th>User</th>
				<th>Status</th>
				<th>Count</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						#username#
					</td>
					<td>
						#status#
					</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
		<p>
			CAREFULLY review the table above before proceeding. Deleting is permanent. You should probably download CSV first.
		</p>
		<p>
			<a href="bulkloadLocalityAttributes.cfm">back to manage</a>
		</p>
		<p>
			<a href="bulkloadLocalityAttributes.cfm?action=yesDel&username=#username#&status=#status#">continue to delete</a>
		</p>
	</cfoutput>

</cfif>
<!------------------------------------------------------->
<cfif action is "csv">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	select
	       		status,
	       		locality_name,attribute_type,attribute_value,attribute_units,attribute_determiner,attribute_remark,determination_method,determined_date
			from cf_temp_locality_attributes
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif isdefined("status") and len(status) gt 0>
				and status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar" list="false">
			</cfif>
		</cfquery>

		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=d,Fields=d.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/bulkloadLocalityAttributeDownload.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=bulkloadLocalityAttributeDownload.csv" addtoken="false">

		<ul>
			<li>
				<a href="bulkloadLocalityAttributes.cfm">back to manage</a>
			</li>
		</ul>
	</cfoutput>
</cfif>

<!---------------------------------------------------------->
<cfif action is "ld">
	<ul>
		<li>
			<a href="bulkloadLocalityAttributes.cfm">go to manage</a>
		</li>
	</ul>
	Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.
	<ul>
		<li>
			<a href="bulkloadLocalityAttributes.cfm?action=makeTemplate">get a template</a>
		</li>
	</ul>

	<p>
		<div class="importantNotification">
			This form will happily accept and create duplicates. Proceed with caution.
		</div>
		<div class="importantNotification">
			It is advisable to keep a copy of any data uploaded here until you have confirmed successful completion.
		</div>
	</p>

	<table border>
		<tr>
			<th>Field</th>
			<th>Required?</th>
			<th>Def.</th>
		</tr>
		<tr>
			<td>locality_name</td>
			<td>yes</td>
			<td>
				Locality Name of existing Locality to which Attributes will be attached
			</td>
		</tr>
		<tr>
			<td>attribute_type</td>
			<td>yes</td>
			<td><a href="/info/ctDocumentation.cfm?table=ctlocality_attribute_type">ctlocality_attribute_type</a></td>
		</tr>
		<tr>
			<td>attribute_value</td>
			<td>yes</td>
			<td>Some are controlled by tables from <a href="/info/ctDocumentation.cfm?table=ctlocality_att_att">ctlocality_att_att</a></td>
		</tr>
		<tr>
			<td>attribute_units</td>
			<td>conditionally</td>
			<td>If required, units are from <a href="/info/ctDocumentation.cfm?table=ctlocality_att_att">ctlocality_att_att</a></td>
		</tr>
		<tr>
			<td>attribute_determiner</td>
			<td>no</td>
			<td>Unique-match to existing Agent</td>
		</tr>
		<tr>
			<td>attribute_remark</td>
			<td>no</td>
			<td></td>
		</tr>
		<tr>
			<td>determination_method</td>
			<td>no</td>
			<td></td>
		</tr>
		<tr>
			<td>determined_date</td>
			<td>no</td>
			<td>ISO8601 format</td>
		</tr>

	</table>

	<form name="oids" method="post" enctype="multipart/form-data" action="bulkloadLocalityAttributes.cfm">
		<input type="hidden" name="action" value="getFile">
		<input type="file"
			name="FiletoUpload"
			size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="insBtn">
	</form>
</cfif>
<!------------------------------------------------------->
<cfif action is "makeTemplate">

	<cfset header="locality_name,attribute_type,attribute_value,attribute_units,attribute_determiner,attribute_remark,determination_method,determined_date">
	<cffile action = "write"
    file = "#Application.webDirectory#/download/bulkloadLocality.csv"
    output = "#header#"
    addNewLine = "no">
	<cflocation url="/download.cfm?file=bulkloadLocality.csv" addtoken="false">
</cfif>
<!------------------------------------------------------->
<cfif action is "getFile">
	<cfoutput>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="cf_temp_locality_attributes">
			</cfinvoke>
		</cftransaction>
		<p>
			data uploaded - <a href="bulkloadLocalityAttributes.cfm">continue</a>
		</p>
	</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif action is "update">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        update cf_temp_locality_attributes
			set status=<cfqueryparam value="#newstatus#" CFSQLType="CF_SQL_varchar" list="false">
			 where
			 key in (<cfqueryparam value="#key#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cflocation url="bulkloadLocalityAttributes.cfm?action=table&username=#username#&status=#status#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif action is "table">
<script src="/includes/sorttable.js"></script>

<script>
	function checkAll(){
	    $('input:checkbox').prop('checked', true);
	}
	function checkAllSS(){
		$('input:checkbox').prop('checked', true);
		$("#newstatus").val('autoload');
	}
	function setAutoload(){
		$("#newstatus").val('autoload');
	}
	function checkNone(){
	    $('input:checkbox').prop('checked', false);
	}
</script>
<cfoutput>
	<ul>
		<li>
			<a href="bulkloadLocalityAttributes.cfm">back to manage</a>
		</li>
	</ul>

	<cfif not isdefined("username") or len(username) is 0>
		username is required here<cfabort>
	</cfif>



	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select * from cf_temp_locality_attributes where
			username in (<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="true">)
			<cfif len(status) gt 0>
				and status in ( <cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			order by status
			limit #recordLimit#
	</cfquery>

	<div style="border:2px solid green;margin:1em;padding:1em;">
		A status beginning with "autoload" (examples: "autoload", "autoload: this part is ignored") will queue records to be checked and loaded.
		All other values are ignored by automation.
	</div>
<form name="f" method="post" action="bulkloadLocalityAttributes.cfm">
	<input type="hidden" name="action" value="update">
	<input type="hidden" name="username" value="#username#">
	<input type="hidden" name="status" value="#status#">
	<label for="newstatus">Update status for checked records</label>
	<input type="text" name="newstatus" id="newstatus">

	<p>
		<input type="submit" class="savBtn" value="Change Status for checked records">
	</p>
	<br>
	<input type="button" class="lnkBtn" onclick="checkNone()" value="Check None">
	<input type="button" class="lnkBtn" onclick="checkAll()" value="Check All">
	<input type="button" class="lnkBtn" onclick="checkAllSS()" value="Check All, status-->autoload">
	<input type="button" class="lnkBtn" onclick="setAutoload()" value="Status-->autoload">

	<table border id="t" class="sortable">
	   <tr>
   		<th>
   		</th>

          <th>status</th>
          <th>locality_name</th>
          <th>attribute_type</th>
		  <th>attribute_value</th>
		  <th>attribute_units</th>
          <th>attribute_determiner</th>
          <th>attribute_remark</th>
          <th>determination_method</th>
          <th>determined_date</th>
		</tr>
		<cfloop query="d">
		 <tr>
		 	<td><input type="checkbox" name="key" value="#key#"></td>
          <td>#status#</td>
          <td>#locality_name#</td>
          <td>#attribute_type#</td>
          <td>#attribute_value#</td>
          <td>#attribute_units#</td>
          <td>#attribute_determiner#</td>
          <td>#attribute_remark#</td>
          <td>#determination_method#</td>
          <td>#determined_date#</td>
        </tr>
		</cfloop>
	</table>

	</form>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">