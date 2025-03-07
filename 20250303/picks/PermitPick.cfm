<cfinclude template="../includes/_includeHeader.cfm">
<cfif action is "nothing">

	<cfset title = "Permit Pick">
	<!---- copy-pasta from Permit.cfm, keep these synced up ---->

	<cfquery name="ctPermitType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select permit_type from ctpermit_type order by permit_type
	</cfquery>
	<cfquery name="ctPermitRegulation" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select permit_regulation from ctpermit_regulation order by permit_regulation
	</cfquery>
	<cfquery name="ctPermitAgentRole" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select permit_agent_role from ctpermit_agent_role order by permit_agent_role
	</cfquery>
	<cfquery name="ctuse_condition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select use_condition from ctuse_condition order by use_condition
	</cfquery>

	<!--------------------------------------------------------------------------->
	<script>
		function resetForm(){
			$("#permit_num").val('');
			$("#permit_type").val('');
			$("#permit_regulation").val('');
			$("#IssuedByAgent").val('');
			$("#IssuedToAgent").val('');
			$("#anyAgent").val('');
			$("#anyAgentRole").val('');
			$("#IssuedAfter").val('');
			$("#IssuedBefore").val('');
			$("#ExpiresAfter").val('');
			$("#ExpiresBefore").val('');
			$("#permit_remarks").val('');
			$("#ContactAgent").val('');	
		} 	
	</script>
	<cfset title="permit search results">
	<style>
		.noExpDate {border: 8px solid orange;}
		.expired {border: 4px solid gray;}
		.sixmos {border: 4px solid #f4cb42;}
		.onemo {border: 4px solid red;}
		.eventually {border: 4px solid green;}
		.btnholderflexy{
			display: flex;
			gap: 2em;
			flex-wrap: wrap;
		}
		.oneagent{
			white-space: nowrap;
		}
	</style>
	<cfoutput>
		<h2>Find Permits</h2>
		Permits are any documentation authorizing activity

		<form name="findPermit" action="PermitPick.cfm" method="post">

			<input type="hidden" name="transaction_id" value="#transaction_id#">
			<input type="hidden" name="callbackfunction" value="#callbackfunction#">
			
			<div class="btnholderflexy">
				<input type="hidden" name="action" value="nothing">
				<div class="abutton">
					<label for="permit_num">
						Permit Identifier/Number
						<span class="infoLink" onclick="var e=document.getElementById('permit_num');e.value='='+e.value;">exact</span>
					</label>
					<cfparam name="permit_num" default="">
					<input type="text" name="permit_num" id="permit_num" value="#permit_num#">
				</div>
				<div class="abutton">

					<label for="permit_type">Permit Type</label>
					<cfparam name="permit_type" default="">
					<cfset x=permit_type>
					<select name="permit_type" id="permit_type" size="1">
						<option value=""></option>
						<cfloop query="ctPermitType">
							<option <cfif x is ctPermitType.permit_type> selected="selected" </cfif> value = "#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
						</cfloop>
					</select>
				</div>
				<div class="abutton">
					<cfparam name="permit_regulation" default="">
					<cfset x=permit_regulation>

					<label for="permit_regulation">Permit Regulation</label>
					<select name="permit_regulation" id="permit_regulation" size="1">
						<option value=""></option>
						<cfloop query="ctPermitRegulation">
							<option <cfif x is ctPermitRegulation.permit_regulation> selected="selected" </cfif> value = "#ctPermitRegulation.permit_regulation#">#ctPermitRegulation.permit_regulation#</option>
						</cfloop>
					</select>
				</div>
				<div class="abutton">
					<cfparam name="use_condition" default="">
					<cfset x=use_condition>

					<label for="use_condition">Use Condition</label>
					<select name="use_condition" id="use_condition" size="1">
						<option value=""></option>
						<cfloop query="ctuse_condition">
							<option <cfif x is ctuse_condition.use_condition> selected="selected" </cfif> value = "#ctuse_condition.use_condition#">#ctuse_condition.use_condition#</option>
						</cfloop>
					</select>
				</div>
				<div class="abutton">

					<cfparam name="IssuedByAgent" default="">
					<label for="IssuedByAgent">Issued By</label>
					<input type="text" name="IssuedByAgent" id="IssuedByAgent" value="#IssuedByAgent#">
				</div>
				<div class="abutton">

					<cfparam name="IssuedToAgent" default="">
					<label for="IssuedToAgent">Issued To</label>
					<input type="text" name="IssuedToAgent" id="IssuedToAgent" value="#IssuedToAgent#">
				</div>
				<div class="abutton">
					<cfparam name="ContactAgent" default="">
					<label for="ContactAgent">Contact</label>
					<input type="text" name="ContactAgent" id="ContactAgent" value="#ContactAgent#">
				</div>
				<div class="abutton">

					<cfparam name="anyAgent" default="">
					<label for="anyAgent">Any Agent</label>
					<input type="text" name="anyAgent" id="anyAgent"  value="#anyAgent#">
				</div>
				<div class="abutton">

					<cfparam name="anyAgentRole" default="">
					<cfset x=anyAgentRole>
					<label for="anyAgentRole">Any Agent Role</label>
					<select name="anyAgentRole" id="anyAgentRole" size="1">
						<option value=""></option>
						<cfloop query="ctPermitAgentRole">
							<option <cfif x is ctPermitAgentRole.permit_agent_role> selected="selected" </cfif> value = "#ctPermitAgentRole.permit_agent_role#">#ctPermitAgentRole.permit_agent_role#</option>
						</cfloop>
					</select>
				</div>
				<div class="abutton">

					<cfparam name="IssuedAfter" default="">
					<label for="IssuedAfter">Issued On/After Date</label>
					<input type="datetime" name="IssuedAfter" id="IssuedAfter"  value="#IssuedAfter#">
				</div>
				<div class="abutton">

					<cfparam name="IssuedBefore" default="">
					<label for="IssuedBefore">Issued On/Before Date</label>
					<input type="datetime" name="IssuedBefore" id="IssuedBefore" value="#IssuedBefore#">
				</div>
				<div class="abutton">
					<cfparam name="ExpiresAfter" default="">
					<label for="ExpiresAfter">Expires On/After Date</label>
					<input type="datetime" name="ExpiresAfter" id="ExpiresAfter" value="#ExpiresAfter#">
				</div>
				<div class="abutton">
					<cfparam name="ExpiresBefore" default="">
					<label for="ExpiresBefore">Expires On/Before Date</label>
					<input type="datetime" name="ExpiresBefore" id="ExpiresBefore" value="#ExpiresBefore#">
				</div>
				<div class="abutton">

					<cfparam name="permit_remarks" default="">
					<label for="permit_remarks">Remarks</label>
					<input type="text" name="permit_remarks" id="permit_remarks" value="#permit_remarks#">
				</div>
			</div>
			<div class="btnholderflexy">
				<div>
					<input type="submit" value="Search" class="schBtn">
				</div>
				<div>
					<input type="button" value="Clear Form" class="clrBtn" onclick="resetForm()">
				</div>
			</div>
		</form>

		<cfset tabls="permit">
		<cfset tabls=tabls & " left outer join permit_trans on permit.permit_id=permit_trans.permit_id ">
		<cfset tabls=tabls & " left outer join trans on permit_trans.transaction_id=trans.transaction_id ">
		<cfset tabls=tabls & " left outer join collection on trans.collection_id=collection.collection_id ">
		<cfset tabls=tabls & " left outer join loan on trans.transaction_id=loan.transaction_id ">
		<cfset tabls=tabls & " left outer join accn on trans.transaction_id=accn.transaction_id ">
		<cfset tabls=tabls & " left outer join borrow on trans.transaction_id=borrow.transaction_id ">
		<cfset tabls=tabls & " left outer join permit_agent on permit.permit_id=permit_agent.permit_id ">
		<cfset tabls=tabls & " left outer join agent on permit_agent.agent_id=agent.agent_id ">
		
		<cfset tbljoin="">
		<cfset whr="">
		<cfset qp=[]>
		<cfif isdefined("IssuedByAgent") and len(IssuedByAgent) gt 0>
			<cfset tabls=tabls & " inner join permit_agent permit_agent_IBA on permit.permit_id=permit_agent_IBA.permit_id ">
			<cfset tabls=tabls & " inner join agent_name IssuedByAgentName on permit_agent_IBA.agent_id=IssuedByAgentName.agent_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_agent_IBA.agent_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v='issued by'>
			<cfset arrayappend(qp,thisrow)>

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="IssuedByAgentName.agent_name">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#IssuedByAgent#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("IssuedToAgent") and len(IssuedToAgent) gt 0>
			<cfset tabls=tabls & " inner join permit_agent permit_agent_ITA on permit.permit_id=permit_agent_ITA.permit_id ">
			<cfset tabls=tabls & " inner join agent_name IssuedToAgentName on permit_agent_ITA.agent_id=IssuedToAgentName.agent_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_agent_ITA.agent_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v='issued to'>
			<cfset arrayappend(qp,thisrow)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="IssuedToAgentName.agent_name">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#IssuedToAgent#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("ContactAgent") and len(ContactAgent) gt 0>
			<cfset tabls=tabls & " inner join permit_agent permit_agent_CA on permit.permit_id=permit_agent_CA.permit_id ">
			<cfset tabls=tabls & " inner join agent_name ContactAgentName on permit_agent_CA.agent_id=ContactAgentName.agent_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_agent_CA.agent_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v='contact'>
			<cfset arrayappend(qp,thisrow)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="ContactAgentName.agent_name">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#ContactAgent#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>	
		<cfif isdefined("anyAgent") and len(anyAgent) gt 0>
			<cfset tabls=tabls & " inner join permit_agent permit_agent_AA on permit.permit_id=permit_agent_AA.permit_id ">
			<cfset tabls=tabls & " inner join agent_name AnyAgentName on permit_agent_AA.agent_id=AnyAgentName.agent_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="AnyAgentName.agent_name">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#anyAgent#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("anyAgentRole") and len(anyAgentRole) gt 0>
			<cfif not tabls contains "agent_name AnyAgentName">
				<cfset tabls=tabls & " inner join permit_agent permit_agent_AA on permit.permit_id=permit_agent_AA.permit_id ">
				<cfset tabls=tabls & " inner join agent_name AnyAgentName on permit_agent_AA.agent_id=AnyAgentName.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_agent_AA.agent_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#anyAgentRole#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("IssuedAfter") and len(IssuedAfter) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.t="permit.issued_date">
			<cfset thisrow.o=">=">
			<cfset thisrow.v='#IssuedAfter#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("IssuedBefore") and len(IssuedBefore) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.t="permit.issued_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.v='#IssuedBefore#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("ExpiresAfter") and len(ExpiresAfter) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.t="permit.exp_date">
			<cfset thisrow.o=">=">
			<cfset thisrow.v='#ExpiresAfter#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("ExpiresBefore") and len(ExpiresBefore) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.t="permit.exp_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.v='#ExpiresBefore#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("permit_num") and len(permit_num) gt 0>
			<cfif left(permit_num,1) is "=">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="permit.permit_num">
				<cfset thisrow.o="=">
				<cfset thisrow.v='#ucase(mid(permit_num,2,len(permit_num)-1))#'>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="permit.permit_num">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='%#permit_Num#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("use_condition") and len(use_condition) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit.use_condition">
			<cfset thisrow.o="=">
			<cfset thisrow.v=use_condition>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("permit_type") and len(permit_type) gt 0>
			<cfset tabls=tabls & " inner join permit_type on permit.permit_id=permit_type.permit_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_type.permit_type">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#permit_type#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("permit_regulation") and len(permit_regulation) gt 0>
			<cfif not tabls contains " permit_type ">
				<cfset tabls=tabls & " inner join permit_type on permit.permit_id=permit_type.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit_type.permit_regulation">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#permit_regulation#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("permit_remarks") and len(permit_remarks) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="permit.permit_remarks">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#permit_remarks#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("permit_id") and len(permit_id) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="permit.permit_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=permit_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfset qal=arraylen(qp)>
		<cfif qal lt 1>
			<cfabort>
		</cfif>
		<cfquery name="raw_permit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				permit.permit_id,
				permit.issued_Date,
				permit.exp_Date,
				permit.permit_Num,
				permit.permit_remarks,
				permit.use_condition,
				agent.agent_id,
				agent.preferred_agent_name,
				permit_agent.agent_role,
				getPermitTypeReg(permit.permit_id) permit_Type,
				trans.transaction_id,
				trans.transaction_type,
				collection.guid_prefix,
				loan.loan_number,
				accn.accn_number,
				borrow.borrow_number
			from
				#tabls#
			where 1=1
			<cfif qal gt 0> and </cfif>
			<cfloop from="1" to="#qal#" index="i">
				#qp[i].t#
				#qp[i].o#
				<cfif qp[i].d is "isnull">
					is null
				<cfelseif qp[i].d is "notnull">
					is not null
				<cfelse>
					<cfif #qp[i].o# is "in">(</cfif>
					<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
					<cfif #qp[i].o# is "in">)</cfif>
				</cfif>
				<cfif i lt qal> and </cfif>
			</cfloop>
			limit 5000
		</cfquery>


		<cfif raw_permit.recordcount is 1000>
			<div class="importantNotification">
				Results truncated, try a more specific search.
			</div>
		</cfif>
		<cfquery name="matchPermit" dbtype="query">
			select
				permit_id,
				issued_Date,
				exp_Date,
				permit_Num,
				permit_remarks,
				permit_Type,
				use_condition
			from 
				raw_permit
			group by 
				permit_id,
				issued_Date,
				exp_Date,
				permit_Num,
				permit_remarks,
				permit_Type,
				use_condition
			order by 
				exp_Date,
				permit_Num
		</cfquery>

		<script src="/includes/sorttable.js"></script>
		<cfset i=1>
		<table border id="t" class="sortable">
			<tr>
				<th>Permit Number</th>
				<th>Permit Type/Regulation</th>
				<th>Use Condition</th>
				<th>Issued To</th>
				<th>Issued By</th>
				<th>Contact</th>
				<th>Issued Date</th>
				<th>Expires Date</th>
				<th>Expires Days</th>
				<th>Remarks</th>
				<th>Trans</th>
			</tr>
			<cfloop query="matchPermit">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<td>
						#permit_Num# <a href="Permit.cfm?action=editPermit&permit_id=#permit_id#"><input type="button" class="lnkBtn" value="edit"></a>

						<cfset jpd="Permit ID #permit_Num# (#permit_Type#)">
						<cfset jpd=jpd & " issued to #IssuedToAgent# by #IssuedByAgent#">
						<cfset jpd=jpd & "on #dateformat(issued_date,'yyyy-mm-dd')#, expires #dateformat(exp_date,'yyyy-mm-dd')#">
						<cfif len(permit_remarks) gt 0>
							<cfset jpd=jpd & " Remarks: #permit_remarks#">
						 </cfif>
						 <cfset jpd=replace(jpd,"'","`","all")>
						 <cfset jpd=replace(jpd,'"',"`","all")>

						<form action="PermitPick.cfm" method="post" name="save">
							<input type="hidden" value="#transaction_id#" name="transaction_id">
							<input type="hidden" value="#callbackfunction#" name="callbackfunction">
							<input type="hidden" value="#jpd#" name="jpd">
							<input type="hidden" name="permit_id" value="#permit_id#">
							<input type="hidden" name="Action" value="addThisOne">
							<input type="submit"  class="picBtn" value="Choose this permit">
						</form>
					</td>
					<td>
						#permit_type#
					</td>
					<td>#use_condition#</td>
					<td>
						<cfquery name="ita" dbtype="query">
							select 
								agent_id,preferred_agent_name
							from
								raw_permit
							where
								permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int"> and
								agent_role=<cfqueryparam value="issued to" cfsqltype="cf_sql_varchar">
							group by agent_id,preferred_agent_name
							order by preferred_agent_name
						</cfquery>
						<cfloop query="ita">
							<div class="oneagent">
								<a href="/agent/#agent_id#" class="external">#preferred_agent_name#</a>
							</div>
						</cfloop>
					</td>
					<td>
						<cfquery name="itb" dbtype="query">
							select 
								agent_id,preferred_agent_name
							from
								raw_permit
							where
								permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int"> and
								agent_role=<cfqueryparam value="issued by" cfsqltype="cf_sql_varchar">
							group by agent_id,preferred_agent_name
							order by preferred_agent_name
						</cfquery>
						<cfloop query="itb">
							<div class="oneagent">
								<a href="/agent/#agent_id#" class="external">#preferred_agent_name#</a>
							</div>
						</cfloop>
					</td>
					<td>
						<cfquery name="ctct" dbtype="query">
							select 
								agent_id,preferred_agent_name
							from
								raw_permit
							where
								permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int"> and
								agent_role=<cfqueryparam value="contact" cfsqltype="cf_sql_varchar">
							group by agent_id,preferred_agent_name
							order by preferred_agent_name
						</cfquery>
						<cfloop query="ctct">
							<div class="oneagent">
								<a href="/agent/#agent_id#" class="external">#preferred_agent_name#</a>
							</div>
						</cfloop>
					</td>
					<td>#dateformat(issued_Date,"yyyy-mm-dd")#</td>
					<td>#dateformat(exp_Date,"yyyy-mm-dd")# </td>
					<cfset dte="">
					<cfif len(exp_Date) gt 0>
						<cfset dte=datediff("d",now(),exp_Date)>
					</cfif>
					<cfif len(dte) is 0>
						<cfset dtec="noExpDate">
					<cfelseif dte lt 0>
						<cfset dtec="expired">
					<cfelseif dte gt 0 and dte lte 30>
						<cfset dtec="onemo">
					<cfelseif dte gt 30 and dte lte 180>
						<cfset dtec="sixmos">
					<cfelse>
						<cfset dtec="eventually">
					</cfif>
					<td>
						<div class="#dtec#">#dte#</div>
					</td>
					<td>#permit_remarks#</td>
					<td>
						<cfquery name="pt" dbtype="query">
							select
								transaction_id,
								transaction_type,
								guid_prefix,
								loan_number,
								accn_number,
								borrow_number
							from
								raw_permit
							where
								transaction_id is not null and 
								permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
							group by
								transaction_id,
								transaction_type,
								guid_prefix,
								loan_number,
								accn_number,
								borrow_number
							order by
								transaction_type,
								guid_prefix
						</cfquery>
						<cfif pt.recordcount is 0>
							This permit is not used.
						<cfelse>
							<div><a href="/transactionSearch.cfm?action=srch&permit_id=#permit_id#">All&nbsp;Transactions</a></div>
							<cfloop query="pt">
								<div style="white-space: nowrap;">
									<cfif transaction_type is 'accn'>
										Accession <a href="/accn.cfm?action=edit&transaction_id=#transaction_id#">#guid_prefix# #accn_number#</a>
									<cfelseif transaction_type is 'loan'>
										Loan <a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a>
									<cfelseif transaction_type is 'borrow'>
										Borrow <a href="/borrow.cfm?action=edit&transaction_id=#transaction_id#">#guid_prefix# #borrow_number#</a>
									</cfif>
								</div>
							</cfloop>
						</cfif>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action is "AddThisOne">
	<cfoutput>
		<cfif not (len(transaction_id) gt 0 and len(permit_id) gt 0 and len(callbackfunction) gt 0)>
			something bad happened <cfabort>
		</cfif>
		<cfquery name="addPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO permit_trans (
				permit_id, 
				transaction_id
			) VALUES (
				<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">, 
				<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
			)
		</cfquery>
		<script>
			parent.#callbackfunction#('#permit_id#','#jpd#');
			//parent.$(".ui-dialog-titlebar-close").trigger('click');
			closeOverlay('PermitPick');
		</script>
		Added permit #permit_id# to transaction #transaction_id#.
	</cfoutput>
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">