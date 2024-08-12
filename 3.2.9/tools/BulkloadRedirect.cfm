<!----



---->

<cfinclude template="/includes/_header.cfm">
<cfset title="Bulkload Redirects">

<cfif action is "makeTemplate">
	<cfset header="old_path,new_path">
	<cffile action = "write"
    file = "#Application.webDirectory#/download/BulkloadRedirect.csv"
    output = "#header#"
    addNewLine = "no">
	<cflocation url="/download.cfm?file=BulkloadRedirect.csv" addtoken="false">
</cfif>


<cfif action is "nothing">
	Step 1: Upload a comma-delimited text file (csv).
	Include CSV column headings.
	<ul>
		<li><a href="BulkloadRedirect.cfm?action=makeTemplate">Get a template</a></li>
	</ul>

	This app just loads stuff to the table. There's minimal checking, and failures will fail entirely - fix your CSV and try again.

	<table border>
		<tr>
			<th>ColumnName</th>
			<th>Required</th>
			<th>Explanation</th>
		</tr>
		<tr>
			<td>old_path</td>
			<td>yes</td>
			<td>
				Local path (without the http://arctos.database.museum bit) that you wish to redirect from. Must start with slash,
				and the resource must not exist for users to be redirected. ("mask record" encumbered specimens do not exist to non-operator
				users.) Must start with "/". Example: /guid/DGR:Mamm:49316
			</td>
		</tr>
		<tr>
			<td>new_path</td>
			<td>yes</td>
			<td>
				Local path or remote URL target. Examples: /guid/MSB:Mamm:194821 or http://arctosdb.wordpress.com/home/governance/joining-arctos/
			</td>
		</tr>
	</table>
	<p></p>
	<form name="oids" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<label for="FiletoUpload">Upload CSV</label>
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="insBtn">
	</form>
</cfif>
<!------------------------------------------------------->
<cfif action is "getFile">
<cfoutput>

	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="redirect">
		</cfinvoke>
	</cftransaction>


	all done
	<a href="/Admin/redirect.cfm">Manage Redirects</a>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
