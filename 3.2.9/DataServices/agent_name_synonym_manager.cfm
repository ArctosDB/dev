<!--- need a key on the table to make this work
ALTER TABLE ds_ct_namesynonyms ADD COLUMN id SERIAL PRIMARY KEY;


grant insert, update on ds_ct_namesynonyms to manage_codetables;


grant select, usage on ds_ct_namesynonyms_id_seq to public;

---->
<cfinclude template="/includes/_header.cfm">
<cfset title="Agent Name Synonyms">

<cfif action is "nothing">
	<style>
		.nameBlock{
			border:2px solid green;
			margin: 1em;
			paddnig: 1em;
		}
	</style>

	<cfoutput>
		<div class="inlineDocs">
			<h2>Agent Name Synonomizer</h2>
			<p>
				DO NOT use this form unless you've read and fully understand ALL directions.
			</p>
			<p>
				If you're tempted to delete something, please carefully and fully read the directions and intent again before proceeding.
			</p>
			<p>
				This form establishes very loose synonyms/nicknames/variants between agent names. These data are used by various Arctos forms for "might be the same as..." predictions.
				Nothing about these data are authoriative; they are used to form suggestions. Erroneously adding names has some potential to lead to faulty suggestions; not adding a name will
				lead to duplicates, with which the data cannot serve its purpose.
			</p>
			<p>
				Names in each group might be used interchangeably. Data should be as inclusive as possible; do not exclude an assertion without being very sure that it's not relevant.
				Uncommon usage, archaic usage, multi-language usage, etc. are encouraged and should not be removed.
			</p>
			<p>
				Names are not limited to English or ASCII. There is no specified scope to these data; the following are encouraged, but should not be viewed as limitations.
				<ul>
					<li>translations</li>
					<li>transliterations</li>
					<li>untranslated versions (any Unicode character set may be used)</li>
					<li>misspellings</li>
					<li>alternate spellings</li>
					<li>nicknames</li>
					<li>abbreviations</li>
				</ul>
			</p>
			<p>
				Usage Instructions:
				<ul>
					<li>Blank a box to remove a name</li>
					<li>Use the empty boxes at the bottom of each group to insert</li>
					<li>The Save button works for one group, not the entire page</li>
					<li>Do not attempt to use commas in agent names; it won't work.
					<li>Do paste comma-lists in a single block; they'll be automagically parsed.</li>
				</ul>
			</p>
		</div>
		<div class="nameBlock" >
			<p>Create a new group. Use this only after you've THOROUGHLY searched for an appropriate existing group.</p>
			<form name="f" action="agent_name_synonym_manager.cfm" method="post">
				<input type="hidden" name="action" value="create">
				<cfset numNames=0>
				<cfloop from="1" to="5" index="i">
					<cfset numNames=numNames+1>
					<br><input name="name#numNames#">
				</cfloop>
				<br>
				<input type="hidden" name="numNames" value="#numNames#">
				<input type="submit" value="create this block" class="insBtn">
			</form>
		</div>
		<cfparam name="namefilter" default="">
		<cfparam name="recLimit" default="100">
		<form name="f" action="agent_name_synonym_manager.cfm" method="get">
			<label for="recLimit">Record Limit (caution: large values may eay your browser)</label>
			<select name="recLimit">
				<option value="10" <cfif recLimit is 10> selected="selected" </cfif> >10</option>
				<option value="50" <cfif recLimit is 50> selected="selected" </cfif> >50</option>
				<option value="100" <cfif recLimit is 100> selected="selected" </cfif> >100</option>
				<option value="1000" <cfif recLimit is 1000> selected="selected" </cfif> >1000</option>

			</select>
			<label for="namefilter">Name Contains (filter)</label>
			<input type="text" size="60" value="#namefilter#" name="namefilter">
			<br><input type="submit" value="filter" class="lnkBtn">
		</form>

		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from ds_ct_namesynonyms
			<cfif len(namefilter) gt 0>
				where upper(names) like <cfqueryparam value = "%#ucase(namefilter)#%" CFSQLType="CF_SQL_VARCHAR">
			</cfif>
			 order by names limit #recLimit#
		</cfquery>
		<br>Found #d.recordcount# groups.
		<cfif d.recordcount eq recLimit>
			<br>This form will return a maximum of #recLimit# groups; you may not be seeing relevant data.
		</cfif>
		<cfloop query="d">
			<cfset nq=queryNew("n")>
			<cfloop list="#names#" index="i">
				<cfset queryAddRow(nq,{n=i})>
			</cfloop>
			<cfquery name="nqo" dbtype="query">
				select * from nq order by n
			</cfquery>
			<div class="nameBlock" id="aid#id#">
				<form name="f" action="agent_name_synonym_manager.cfm" method="post">
					<input type="hidden" name="id" value="#id#">
					<input type="hidden" name="action" value="save">
					<cfset numNames=0>
					<cfloop query="nqo">
						<cfset numNames=numNames+1>
						<br><input name="name#numNames#" value="#n#">
					</cfloop>
					<cfloop from="1" to="5" index="i">
						<cfset numNames=numNames+1>
						<br><input name="name#numNames#">
					</cfloop>
					<br>
					<input type="hidden" name="numNames" value="#numNames#">
					<input type="submit" value="save this block" class="savBtn">
				</form>
			</div>
		</cfloop>
<!--------------
		<table border>
			<tr>
				<th>Names</th>
				<th>ctl</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						#names#
					</td>
					<td>x</td>
				</tr>
			</cfloop>

		</table>
------------>
	</cfoutput>
</cfif>

<cfif action is "create">
	<cfoutput>
		<cfset theAgentNameString="">
		<cfloop from="1" to="#numNames#" index="i">
			<cfset thisName=evaluate("name" & i)>
			<cfset thisName=trim(thisName)>
			<cfif len(thisName) gt 0>
				<cfset theAgentNameString=listappend(theAgentNameString,thisName)>
			</cfif>
		</cfloop>
		<cfif len(theAgentNameString) is 0>
			<cfthrow message="this is a bad place to experiment" detail="attempted create empty group">
			<cfabort>
		</cfif>
		<cfif listlen(theAgentNameString) lt 2>
			<cfthrow message="this is a bad place to experiment" detail="at least two names are required to initiate.">
			<cfabort>
		</cfif>
		<cfquery name="uptbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into ds_ct_namesynonyms (names) values (<cfqueryparam value = "#theAgentNameString#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery name="rdirid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select id from ds_ct_namesynonyms where names=<cfqueryparam value = "#theAgentNameString#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cflocation url="agent_name_synonym_manager.cfm##aid#rdirid.id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "save">
	<cfoutput>
		<cfset theAgentNameString="">
		<cfloop from="1" to="#numNames#" index="i">
			<cfset thisName=evaluate("name" & i)>
			<cfset thisName=trim(thisName)>
			<cfif len(thisName) gt 0>
				<cfif not listfind(theAgentNameString,thisName)>
					<cfset theAgentNameString=listappend(theAgentNameString,thisName)>
				</cfif>
			</cfif>
		</cfloop>
		<cfif len(theAgentNameString) is 0>
			<cfthrow message="this is a bad place to experiment" detail="attempted save empty group">
			<cfabort>
		</cfif>
		<cfif listlen(theAgentNameString) lt 2>
			<cfthrow message="this is a bad place to experiment" detail="at least two names are required to save.">
			<cfabort>
		</cfif>
		<cfquery name="uptbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update ds_ct_namesynonyms set names=<cfqueryparam value = "#theAgentNameString#" CFSQLType="CF_SQL_VARCHAR"> where id=<cfqueryparam value = "#id#" CFSQLType="CF_SQL_INT">
		</cfquery>
		<cflocation url="agent_name_synonym_manager.cfm##aid#id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
