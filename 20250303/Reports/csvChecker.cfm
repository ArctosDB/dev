<!----
revistions: https://github.com/ArctosDB/arctos/issues/6570
---->
<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="CSV Header Checker">
<h2>CSV Header Checker</h2>
<style>
	.fa-check{
		color: green;
		font-size: 2em;
	}
	.fa-xmark {
		color: red;
		font-size: 2em;
	}
	
	.ctrdv {
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
		width: 100%;
		justify-content: space-between;
  		align-items:flex-start;
  		align-content:flex-start;
	}
	.rtbl{
		width: 40vw;
		border:2px solid black;
		margin:1em;
		padding:1em;
	}
</style>
<cfoutput>
	<cfif action is "nothing">
		<p>
			Load CSV and select tool to check headers. Only headers are checked, data may be removed before uploading.
		</p>
		<p>
			This forms checks the header row of an uploaded CSV with the acceptable field names in the bulkloader. It is provided as a tool for you to check your CSV prior to bulkloading so typos, missing fields, and other header row issues can be addressed by the user. It does not check any values beyond the first row.
		</p>
		<cfparam name="loader" default="bulkloader">
		<form name="oids" method="post" enctype="multipart/form-data" action="csvChecker.cfm">
			<input type="hidden" name="action" value="getFile">
			<label for="loader">Choose Tool</label>
			<select name="loader">
				<option value="">Choose Tool</option>
				<option <cfif loader is "bulkloader"> selected="selected" </cfif> value="bulkloader">Record Bulkloader</option>
			</select>
			<br>
			<label for="FiletoUpload">Select File</label>
			<input type="file" name="FiletoUpload" size="45" accept=".csv">
			<br><input type="submit" value="Continue" class="insBtn">
		</form>
	</cfif>
	<cfif action is "getFile">
		<p><a href="csvChecker.cfm">start over</a>
		<cfif not isdefined("loader") or len(loader) is 0>
			<div class="importantNotification">
				No tool specified.
			</div>
			<cfabort>
		</cfif>
		<cfif not isdefined("FiletoUpload") or len(FiletoUpload) is 0>
			<div class="importantNotification">
				No file provided.
			</div>
			<cfabort>
		</cfif>
		<p>Checking uploaded file against #loader#</p>
		<cffile action="read" file="#FiletoUpload#" variable="file">
		<cfset header=listGetAt(file, 1,chr(10))>
		<cfset header=replace(header, '"', "", 'all')>
		<cfset header=lCase(header)>
		<cfset header=trim(header)>
		<cfset headerUnique=listRemoveDuplicates(header)>
		<cfif header neq headerUnique>
			<div class="importantNotification">
				The following are duplicated in the input:
				<cfset header2=header>
				<cfloop list="#headerUnique#" index="i">
					<cfset header2=listDeleteAt(header2, listfind(header2,i))>
				</cfloop>
				<ul>
					<cfloop list="#header2#" index="i">
						<li>#i#</li>
					</cfloop>
				</ul>
			</div>
		</cfif>
		<cfif len(header) is 0>
			<div class="importantNotification">
				The file could not be read.
			</div>
			<cfabort>
		</cfif>
		<cfquery name="getTblDef" datasource="uam_god">
			select * from #loader# where 1=2
		</cfquery>
		<cfset tblCls=getTblDef.columnlist>
		<cfset tblCls=lCase(tblCls)>
		<div class="ctrdv">
			<div class="ltbl">
				<table border class="sortable" id="entityTable">
					<tr>
						<th>Column</th>
						<th>Uploaded CSV</th>
						<th>Validation Table</th>
					</tr>
					<cfloop list="#header#" index="hv">
						<tr>
							<td>#hv#</td>
							<td>
								<i class="fas fa-check"></i>
							</td>
							<td>
								<cfif listFindNoCase(tblCls, hv) or (tblCls eq hv)>
									<i class="fas fa-check"></i>
									<cfset tblCls=listdeleteat(tblCls,listFindNoCase(tblCls, hv))>
								<cfelse>
									<i class="fa-solid fa-xmark"></i>
								</cfif>
							</td>
						</tr>
					</cfloop>
					<cfloop list="#tblCls#" index="c"><tr>
							<td>#c#</td>
							<td>
								<i class="fa-solid fa-xmark"></i>
							</td>
							<td>
								<i class="fas fa-check"></i>
							</td>
						</tr>
					</cfloop>
				</table>
			</div>
			<div class="rtbl">
				<h3>About Results</h3>
				<h4>Columns</h4>
				<ul>
					<li><strong>Uploaded CSV</strong> is a column as found in the CSV you've loaded.</li>
					<li><strong>Validation Table</strong> is a column in the target table or tool you've chosen.</li>
					<li><i class="fas fa-check"></i> indicates the column was found.</li>
					<li><i class="fa-solid fa-xmark"></i> indicates the column was not found.</li> 
				</ul>
				<h4>Examples</h4>
				<table border>
					<tr>
						<th>Column</th>
						<th>Uploaded CSV</th>
						<th>Validation Table</th>
					</tr>
					<tr>
						<td>good_example</td>
						<td><i class="fas fa-check"></i></td>
						<td><i class="fas fa-check"></i></td>
					</tr>
					<tr>
						<td>bad_example</td>
						<td><i class="fas fa-check"></i></td>
						<td><i class="fa-solid fa-xmark"></i></td>
					</tr>
					<tr>
						<td>missing_example</td>
						<td><i class="fa-solid fa-xmark"></i></td>
						<td><i class="fas fa-check"></i></td>
					</tr>
				</table>
				<h4>Explanations</h4>
				<ul>
					<li>
						In the table above, column <strong>good_example</strong> is present in the upload and validation table. Everything is as expected.
					</li>
					<li>
						In the table above, column <strong>bad_example</strong> is present in the upload and <strong>not</strong> in the validation table. An unknown column exists in the CSV and the load will fail.
					</li>
					<li>
						In the table above, column <strong>missing_example</strong> is <strong>not</strong>  present in the upload and <strong>is</strong>  present in the validation table. This may be acceptable as many tools have optional columns (such as many attributes in the record bulkloader). However, if it is a field that should be included in your record, then be sure to add those fields with the proper field name and desired values.
					</li>
				</ul>
			</div>
		</div>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">