
<!-----------------

	removing editing for https://github.com/ArctosDB/dev/issues/111, a lot of crazy has founds its way in here
---->


<cfinclude template="/includes/_header.cfm">
<!-------------

https://github.com/ArctosDB/arctos/issues/849#issuecomment-224385884

update cf_ctuser_roles set DESCRIPTION='"Good student" basics. Manipulate most things at SpecimenDetail; manage Citations' where
	ROLE_NAME='manage_specimens';

grant insert,update,delete on citation to manage_specimens;


------------------------>
<cfset title="User Roles">
<cfif action IS "nothing">
	<style>
		#pkg_div{
			margin: 1em;
			padding: 1em;
			max-height: 20em;
			overflow: auto;
			border: 3px solid darkblue;
		}
		.open{
			background-color: var(--arctos_level_0_color);
		}
		.operator{
			background-color: var(--arctos_level_1_color);
		}
		.administrator{
			background-color: var(--arctos_level_2_color);
		}
		.restricted{
			background-color: var(--arctos_level_3_color);
		}

	</style>
	<script>
		$(document).ready(function() {
			//now rescroll to the anchor
			var hash = window.location.hash;
	  		if (hash) {
			    $('html, body').animate({scrollTop:$(window.location.hash).offset().top-1}, 1000);
			}
		});

		function copydoc(id){
			var tempInput = document.createElement("textarea");
			tempInput.style = "position: absolute; left: -1000px; top: -1000px";
			var dl=$("#" + id).val();
			if (dl.length==0){
				$('<span class="copyalert">nothing to copy</span>').insertAfter('#btn' + id).delay(3000).fadeOut();
				return;
			}
			dl='* ' + dl.replace(/,/g,   '\n* ' );
			tempInput.value = dl;
			document.body.appendChild(tempInput);
			tempInput.select();
			document.execCommand("copy");
			document.body.removeChild(tempInput);
			$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#btn' + id).delay(3000).fadeOut();
		}

		function copylink(id){
			var tempInput = document.createElement("input");
			tempInput.style = "position: absolute; left: -1000px; top: -1000px";
			var url = window.location.href.split('#')[0] + '#' + id;
			location.href = url; 
	    	history.replaceState(null,null,url);  		
			tempInput.value = url;
			document.body.appendChild(tempInput);
			tempInput.select();
			document.execCommand("copy");
			document.body.removeChild(tempInput);
			$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#cplnk' + id).delay(3000).fadeOut();
		}

		function highlightmultirow(r){
			var ar=r.split(',');
			$(".highlight").removeClass("highlight");
			for (a=0; a<ar.length; ++a) {
				$("#" + ar[a]).addClass('highlight');
			}
			$('html, body').animate({
			    scrollTop: $('.highlight:visible:first').offset().top
			}, 1000);
		}
		function getPackageDoc(k,r){
			if (r.length==0){
				$('<span class="copyalert">nothing to copy</span>').insertAfter('#' + k).delay(3000).fadeOut();
				return;
			}
			var ar=r.split(',');
			const rall = [];
			for (a=0; a<ar.length; ++a) {
				var d=$("#doc_" + ar[a]).val();
				var tmp=d.split(',');
				rall.push.apply(rall, tmp);
			}
			let noblank = rall.filter(function (e) {
			    return e; // Returns only the truthy values
			});
			let uniqueItems = [...new Set(noblank)];
			uniqueItems.sort(); 
			let dl = uniqueItems.toString(); 
			dl='* ' + dl.replace(/,/g,   '\n* ' );
			var tempInput = document.createElement("textarea");
			tempInput.style = "position: absolute; left: -1000px; top: -1000px";
			tempInput.value = dl;
			document.body.appendChild(tempInput);
			tempInput.select();
			document.execCommand("copy");
			document.body.removeChild(tempInput);
			$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#' + k).delay(3000).fadeOut();
		}
	</script>
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfquery name="current" datasource="uam_god">
			select 
				role_name,
				description,
				user_type,
				shared,
				documentation,
				role_category,
				sort_order
			from 
				cf_ctuser_roles 
			order by sort_order
		</cfquery>

		The following table summarizes Arctos Operator Roles, and may be out of date. Please file an issue if you notice errors. 
		<ul>
			<li>The <a href="https://en.wikipedia.org/wiki/Create,_read,_update_and_delete" class="external">CRUD</a> button is the only source of a current and complete role defintion.</li>
			<li>Roles are additive; "manage_geography" does NOT include SELECT access to table geog_auth_rec because all users already have such access through the PUBLIC role.</li>
			<li>The link button will copy the URL of a row to your clipboard; pleae use this when communicating.</li>
			<li>The copyMD button will copy documentation to your clipboard. This format is suitable for pasting in a GitHub Issue.</li>
			<li>Role categories are:
				<ul>
					<li>open: public account, anyone may access</li>
					<li>operator: User with database access</li>
					<li>administrator: Operator who can make long-term decisions (eg mint "forever identifiers")</li>
					<li>restricted: Operator with special needs/access</li>
				</ul>
			</li>
		</ul>
		<br>Do not grant access without also providing this information!
		<div id="pkg_div">
			<h3>Packages</h3>
			"Packages" are commonly-bundled roles that may be given together in various situations. These are converniences only; you may use or ignore this section.
			<cfquery name="cf_ctuser_packages" datasource="uam_god">
				select
					key,
					package_source,
					package_name,
					package_description,
					package_role_list,
					order_within_source
				from
					cf_ctuser_packages
				order by 
					package_source,
					order_within_source
			</cfquery>
			<table border="1">
				<tr>
					<th>Clicky</th>
					<th>Source</th>
					<th>Package</th>
					<th>Description</th>
					<th>Roles</th>
				</tr>
				<cfloop query="cf_ctuser_packages">
					<tr>
						<td>
							<input type="button" value="show roles" onclick="highlightmultirow('#package_role_list#')">
							<input type="button" value="copyMD" id="#key#" onclick="getPackageDoc('#key#','#package_role_list#')">
						</td>
						<td>#package_source#</td>
						<td>#package_name#</td>
						<td>#package_description#</td>
						<td>#listchangedelims(package_role_list,', ')#</td>
					</tr>
				</cfloop>
			</table>
		</div>
		<h3>Roles</h3>
		<table border id="t" class="sortable">
			<tr>
				<td>Role Name</td>
				<td>Tools</td>
				<td>Category</td>
				<td>Description</td>
				<td>Appropriate For</td>
				<td>Documentation</td>
				<td>Sort</td>
			</tr>
		<cfloop query="current">
			<cfset alldocs=documentation>
			<cfif SHARED is 'yes'>
				<cfset alldocs=listPrepend(alldocs, 'https://handbook.arctosdb.org/documentation/sharing-data-and-resources.html')>
			</cfif>
			<input type="hidden" name="doc_#role_name#"  id="doc_#role_name#" value="#alldocs#">
			<tr id="#role_name#" class="#role_category#">
				<td>
					#role_name#
				</td>
				<td>
					<div class="nowrap">
						<input type="button" value="link" id="cplnk#role_name#" onclick="copylink('#role_name#')">
					</div>
					<div class="nowrap">
						<a href="user_roles.cfm?action=defineRole&role_name=#role_name#" target="_blank"><input type="button" value="CRUD"></a>
					</div>
					<div class="nowrap">
						<input id="btndoc_#role_name#" type="button" value="copyMD" onclick="copydoc('doc_#role_name#');">
					</div>
				</td>
				<td>
					#role_category#
				</td>
				<td>#Description#</td>
				<td>#USER_TYPE#</td>
				
				<td nowrap>
					<cfloop list="#alldocs#" index="i">
						<div class="nowrap">
							<a href="#i#" class="external">#i#</a>
						</div>
					</cfloop>
				</td>
				<td>#sort_order#</td>
			</tr>
		</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action IS "defineRole">
	<cfoutput>
		The following table is authoritative as of #dateformat(now(), 'YYYY-MM-DD')#.
		<cfquery name="d" datasource="uam_god">
			select * from information_schema.table_privileges where grantee=<cfqueryparam value="#role_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfquery name="dt" dbtype="query">
			select distinct table_name from d order by table_name
		</cfquery>
		<p>
			Table privileges for #role_name#
		</p>
		<table border>
			<tr>
				<td>Table Name</td>
				<td>Select?</td>
				<td>Delete?</td>
				<td>Insert?</td>
				<td>Update?</td>
				<td>TableBrowser</td>
			</tr>
			<cfloop query="dt">
				<cfquery name="dts" dbtype="query">
					select privilege_type from d where table_name=<cfqueryparam value="#table_name#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset dtlst=valuelist(dts.privilege_type)>
				<tr>
					<td>#table_name#</td>
					<td>
						<cfif listfindnocase(dtlst,'select')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td>
						<cfif listfindnocase(dtlst,'delete')>
							yes
						<cfelse>
							no
						</cfif>
					</td>

					<td>
						<cfif listfindnocase(dtlst,'update')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td>
						<cfif listfindnocase(dtlst,'insert')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td><a href="/tblbrowse.cfm?tbl=#table_name#" target="_blank">[ new tab ]</a></td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">