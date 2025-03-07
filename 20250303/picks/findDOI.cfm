<!--- no security --->
<cfinclude template="../includes/_includeHeader.cfm">
 <cfif not isdefined("publication_title")>
	Didn't get a publication_title.<cfabort>
</cfif>
<style>
	.mightbe{padding:.2em; margin:.2em; border:2px solid green;}
	.probablynot{padding:.2em;margin:.2em; border:1px solid orange;}
	#help{display:none; border:1px solid black;margin:1em;padding:1em;}
</style>
<script>
	var svbtn='<input type="button" value="save" class="savBtn" onclick="editPub.action.value=\'saveEdit\';editPub.submit();">';

	function useDOI(doi){
		parent.$("#doi").val(doi);
		parent.$("#addadoiplease").after(svbtn);
		closeOverlay('findDOI');
	}
	function nofindDOI(){
		var er=parent.$("#publication_remarks").val();
		var tr=$("#failbox").val();
		if(er.length>0){
			tr+='; ' + er;
		}
		parent.$("#addadoiplease").after(svbtn);
		parent.$("#publication_remarks").val(tr);
		closeOverlay('findDOI');
	}
</script>
<cfoutput>
	<form name="additems" method="post" action="findDOI.cfm">
		<label for="publication_title">Title</label>
		<textarea name="publication_title" class="hugetextarea">#publication_title#</textarea>
		<br><input type="submit" value="Find DOI">

		<!---- simplify failure.... ---->
		<input id="failbox" type="hidden" value="Unable to locate suitable DOI - #session.username# #dateformat(now(),'yyyy-mm-dd')#">
	</form>
	<cfif len(publication_title) gt 0>
		<cfset pt=urldecode(publication_title)>
		<cfset startttl=refind('[0-9]{4}\.',pt) + 5>
		<cfset noauths=mid(pt,startttl,len(pt))>
		<cfset stopttl=refind('\.',noauths)>
		<cfset ttl=Mid(pt, startttl, stopttl)>
		<cfset ttl=rereplace(ttl,'<[^>]*(?:>|$)','','all')>
		<cfset stripttl=ucase(trim(rereplacenocase(ttl, '[^a-z0-9]', '', 'all')))>
		<cfif len(stripttl) lt 10>
			<p style="border:2px solid red;padding:1em;margin:1em;text-align:center;">
				If this is a journal article, it's probably not formatted correctly.
			</p>
		</cfif>
		<p>
			Not finding what you need? <span class="likeLink" onclick="nofindDOI();">Add a remark.</span>
		</p>
		<span class="likeLink" onclick="$('##help').toggle()">help</span>
		<div id="help">
			The box above is the publication full citation as pulled from Arctos.
			If you aren't finding what you're looking for, try editing it (which will increase
			the number of false positives returned, but perhaps also find the
			correct article). For example, removing parenthetical taxa may be useful.
			<p>
				The results below are pulled from CrossRef. Read them before clicking;
				there are many situations in which an incorrect match is highlighted as
				correct, and in which a correct match is buried in the probable failures.
				<br>
				If what you're looking for isn't obvious, try searching (CTL-F or splat-F) by a hopefully-unique
				term from the original title.
				<br>Note that not all publications are in CrossRef; ZooTaxa does not seem to participate in
				DOIs, for example. Note also that many old and obscure publications HAVE been made available
				through CrossRef (largely by BHL).
			</p>
			<p>
				Consider correcting data in Arctos. This form ONLY finds DOIs; close this window and
				edit the publication.
			</p>
			<p>
				This for is a tool, not magic. If you don't find what you're looking for here, try
				<a target="_blank" class="external" href="http://google.com/search?q=#publication_title#">Google</a>.
			</p>
		</div>
		<cftry>
			<cfhttp url="https://api.crossref.org/works?query.bibliographic=#publication_title#"></cfhttp>
			<cfset x=DeserializeJSON(cfhttp.filecontent)>
			<cfset rary=x.message.items>
			<table border="1">
				<tr>
					<th>Use</th>
					<th>DOI</th>
					<th>Title</th>
					<th>Authors
				</tr>
				<cfloop array="#rary#" index="data_index">
					<tr>
						<td>
							<input type="button" class="lnkBtn" onclick="useDOI('https://doi.org/#data_index.DOI#')" value="Use This DOI">
						</td>				
						<td><a href="https://doi.org/#data_index.DOI#" class="external">https://doi.org/#data_index.DOI#</td>
						<td>#data_index.title[1]#</td>
						<td>
							<cfif structKeyExists(data_index, 'author')>
								<cfloop array="#data_index.author#" index="auth">
									<br>#auth.given# #auth.family#
								</cfloop>
							</cfif>
						</td>
					</tr>
				</cfloop>
			</table>
		<cfcatch>
			<div class="importantNotification">
			Blargh, something bad happened with the request to CrossRef. (Try again in a few minutes.) Details follow....
			</div>
			<p>
				<cfdump var=#cfcatch#>

				<cfif isdefined("cfhttp")>
					<cfdump var=#cfhttp#>
				</cfif>
			</p>
		</cfcatch>
		</cftry>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">