<cfinclude template="/includes/_header.cfm">
look at code for usage - use contact link if that doesn't make sense


<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<style>
	.done{background-color:lightgray;}
	.err{border:5px solid red;}
	.d{border:2px solid black;}

</style>
<cfoutput>
	<cfif action is "nothing">
		<ul>
			<li>Load CSV with one column, "spec_locality", in the form below</li>
			<li>
				check <a href="getGeogFromSpecloc.cfm?action=validate">validate</a> for any existing records
			</li>
			<li>
				 <a href="getGeogFromSpecloc.cfm?action=csv">get results as CSV</a>
			</li>
		</ul>
<!---
onchange="checkCSV(this);"
---->
		<form name="fas" method="post" enctype="multipart/form-data" action="getGeogFromSpecloc.cfm">
			<input type="hidden" name="Action" value="getFile">
			<label for="">upload CSV</label>
			<input type="file" name="FiletoUpload" size="45" >
			<input type="submit" value="Upload this file">
		</form>

	</cfif>

	<cfif action is "csv">
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				*
			from cf_temp_spec_to_geog
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=getData,Fields=getData.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/cf_temp_spec_to_geog.csv"
		   	output = "#csv#"
		   	addNewLine = "no">

		<cflocation url="/download.cfm?file=cf_temp_spec_to_geog.csv" addtoken="false">
		<a href="/download/cf_temp_spec_to_geog.csv">Click here if your file does not automatically download.</a>
	</cfif>
	<cfif action is "getFile">
		<!--- put this in a temp table --->
		<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_temp_spec_to_geog
		</cfquery>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="cf_temp_spec_to_geog">
		</cfinvoke>
		<a href="getGeogFromSpecloc.cfm?action=validate">File uploaded, proceed to validate</a>
	</cfif>
<cfif action is "validate">



<script>
	$(document).ready(function() {
		$.each($("input[id^='geog_']"), function() {
			$("##" + this.id).autocomplete("/ajax/higher_geog.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
	    });
		$("form").submit(function( event ) {
			event.preventDefault();
			var formId = this.id;
			var iid=formId.replace('f','');
			var tSL=$("##sl" + iid).val();
			var tNG=$("##geog_" + iid).val();
			useThisOne(tSL,tNG,'d'+iid);
		});
	});
	function useThisOne(o,n,d){
		$.getJSON("/component/DSFunctions.cfc",
			{
				method : "updatecf_temp_spec_to_geog",
				returnformat : "json",
				queryformat : 'column',
				old: o,
				new: n
			},
			function(r) {
				if (r=='ok'){
					$("##"+d).removeClass().addClass('done');
				} else {
					$("##"+d).removeClass().addClass('err');
				}
			}
		);
	}

</script>



	<p>
		This will load 20 records and provide some guesses for appropriate geography (and some static suggestions, which may be wildly inappropriate).
		<br>Click stuff, click load more at the bottom to load a new set
	</p>

	<cfquery name="d" datasource="uam_god">
		select * from (select * from cf_temp_spec_to_geog where higher_geog is null order by spec_locality) asl limit 20
	</cfquery>
	<cfset rnum=1>
	<cfloop query="d">
		<cfset qp=replace(spec_locality,';',',','all')>
		<cfset qp=replace(qp,'?',' ','all')>
		<cfset qp=replace(qp,'/',' ','all')>
		<cfset qp=replace(qp,'  ',' ','all')>
		<cfset qp=trim(qp)>
		<cfif len(qp) gt 0>
			<cfquery name="sp" datasource="uam_god">
				select higher_geog as sugn from (
					select
						higher_geog
					from
						geog_auth_rec
					where
						upper(country) like <cfqueryparam value="%#ucase(trim(qp))#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(qp))#"> and
						state_prov is null and
						quad is null and
						feature is null and
						sea is null and
						island is null and
						island_group is null and
						county is null
					union
					select
						higher_geog
					from
						geog_auth_rec
					where
						upper(state_prov) like <cfqueryparam value="%#ucase(trim(qp))#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(qp))#"> and
						quad is null and
						feature is null and
						sea is null and
						island is null and
						island_group is null and
						county is null
					union
					select
						higher_geog
					from
						geog_auth_rec
						inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
					where
						upper(spec_locality) like <cfqueryparam value="%#ucase(trim(qp))#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(qp))#">
					<cfif listlen(spec_locality,",") gt 0>
						<cfloop list="#qp#" index="x">
							union
							select
								higher_geog
							from
								geog_auth_rec
							where
								upper(country) like <cfqueryparam value="%#ucase(trim(x))#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(x))#"> and
								state_prov is null and
								quad is null
								and feature is null
								and sea is null
								and island is null and
								island_group is null and
								county is null
							union
							select
								higher_geog
							from
								geog_auth_rec
							where
								upper(state_prov) like <cfqueryparam value="%#ucase(trim(x))#%" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(x))#"> and
								quad is null and feature is null and sea is null and island is null and island_group is null and county is null
						</cfloop>
					</cfif>
					) als group by higher_geog order by higher_geog
			</cfquery>
			<div id="d#rnum#" class="d">
				<a target="_blank" class="external" href="https://www.google.com/search?q=#spec_locality#">#spec_locality#</a>
				<ul>
					<cfloop query="sp">
						<li>
							<span class="likeLink" onclick="useThisOne('#d.spec_locality#','#sp.sugn#','d#rnum#');">#sp.sugn#</span>
						</li>
					</cfloop>
				</ul>
				<!--- static defaults ---->
				<ul>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','North America, United States, Alaska','d#rnum#');">North America, United States, Alaska</span>
					</li>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','North America, United States','d#rnum#');">North America, United States</span>
					</li>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','North America, Canada','d#rnum#');">North America, Canada</span>
					</li>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','North America','d#rnum#');">North America</span>
					</li>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','Eurasia, Russia','d#rnum#');">Eurasia, Russia</span>
					</li>
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','no higher geography recorded','d#rnum#');">no higher geography recorded</span>
					</li>
					<!----
					<li>
						<span class="likeLink" onclick="useThisOne('#d.spec_locality#','xxxx','d#rnum#');">xxxxx</span>
					</li>
					---->
				</ul>
				<form id="f#rnum#">
					<input type="text"  class="ac" name="geog_#rnum#" size="40" id="geog_#rnum#" placeholder="type to get suggestions">
					<input type="hidden" id="sl#rnum#" name="sl#rnum#" value="#d.spec_locality#">
					<input type="submit" value="use <--- that">
				</form>
			<cfset rnum=rnum+1>
		</div>
		</cfif>
	</cfloop>
	<p>
		<a href="getGeogFromSpecloc.cfm?action=validate">check another set</a>
	</p>
	<p>
		<a href="getGeogFromSpecloc.cfm">manage</a>
	</p>
	</cfif>
</cfoutput>