<cfinclude template = "includes/_header.cfm">
<script>
	$(document).ready(function() {
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$("input[type='date'], input[type='datetime']" ).datepicker();
	});
</script>
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
<cfif action is "nothing">
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
		<h2>Permits / Any Documentation Authorizing Activity</h2>
		Permits are any documentation authorizing activity

		<p>
			<a href="Permit.cfm?action=newPermit"><input type="button" class="insBtn" value="create permit"></a>
		</p>
		<h4>Find to manage</h4>

		<form name="findPermit" action="Permit.cfm" method="post">
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
				to_char(permit.issued_Date,'YYYY-MM-DD') issued_Date,
				to_char(permit.exp_Date,'YYYY-MM-DD') exp_Date,				
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
					<td>#permit_Num# <a href="Permit.cfm?action=editPermit&permit_id=#permit_id#"><input type="button" class="lnkBtn" value="edit"></a></td>
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
					<td>#issued_Date#</td>
					<td>#exp_Date# </td>
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
<!--------------------------------------------------------------------------->
<cfif action is "newPermit">
	<cfset title="create permit">
	<h2>Create Permit</h2>
	<cfoutput>
		<form name="newPermit" action="Permit.cfm" method="post">
			<input type="hidden" name="action" value="createPermit">
			<p>The Basics</p>
			<label for="permit_num" class="helpLink" id="_permit_num">Permit Identifier/Number</label>
		  	<input type="text" name="permit_num" id="permit_num" class="reqdClr" required >

				<label for="issued_date" class="helpLink" id="_issued_date">Issued Date</label>
			<input type="datetime" id="issued_date" name="issued_date" >

			<label for="exp_date" class="helpLink" id="_exp_date">Expiration Date</label>
		  	<input type="datetime" id="exp_date" name="exp_date" >

			<label for="permit_remarks">Remarks</label>
		  	<textarea name="permit_remarks" class="largetextarea"></textarea>

			<div style="font-size:small;padding:1em;margin:1em;">
				Create and edit to add more types and regulations. Code table is
				<a target="_blank" href="/info/ctDocumentation.cfm?table=CTPERMIT_TYPE">CTPERMIT_TYPE</a>.
			</div>

			<label for="permit_type">Permit Type</label>
			<select name="permit_type" id="permit_type" class="reqdClr" required size="1">
				<option value=""></option>
				<cfloop query="ctPermitType">
					<option value="#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
				</cfloop>
			</select>

			<label for="use_condition">Use Condition</label>
			<select name="use_condition" id="use_condition" size="1">
				<option value=""></option>
				<cfloop query="ctuse_condition">
					<option value="#ctuse_condition.use_condition#">#ctuse_condition.use_condition#</option>
				</cfloop>
			</select>
			<label for="use_condition_summary">Use Condition Summary</label>
		  	<textarea name="use_condition_summary" class="largetextarea"></textarea>



			<div style="font-size:small;padding:1em;margin:1em;">
				Save and edit to add more Agents
				Code table is
				<a target="_blank" href="/info/ctDocumentation.cfm?table=CTPERMIT_AGENT_ROLE">CTPERMIT_AGENT_ROLE</a>
			</div>
			<label for="issued_by">Issued By</label>
			<input type="hidden" id="issued_by_agent_id" name="issued_by_agent_id">
			<input
				type="text"
				name="issued_by"
				id="issued_by"
				class="minput reqdClr"
				onchange="pickAgentModal('issued_by_agent_id',this.id,this.value); return false;"
				onKeyPress="return noenter(event);"
				placeholder="Issued By Agent"
				required>
			<label for="issued_to">Issued To</label>
			<input type="hidden" id="issued_to_agent_id" name="issued_to_agent_id">
			<input
				type="text"
				name="issued_to"
				id="issued_to"
				class="minput reqdClr"
				onchange="pickAgentModal('issued_to_agent_id',this.id,this.value); return false;"
				onKeyPress="return noenter(event);"
				placeholder="Issued To Agent"
				required>
			<p>
				<input type="submit" value="Create Permit" class="savBtn">
			</p>
		</form>
	</cfoutput>
</cfif>
<cfif action is "renewClone">
	<cfoutput>
		<cftransaction>
			<!--- grab next permit_id --->
			<cfquery name="pid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_permit_id') pid
			</cfquery>
			<!--- get existing info --->
			<cfquery name="old_permit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from permit where permit_id=#permit_id#
			</cfquery>
			<cfquery name="old_permit_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from permit_type where permit_id=#permit_id#
			</cfquery>
			<cfquery name="old_permit_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from permit_agent where permit_id=#permit_id#
			</cfquery>
			<!--- create a permit --->
			<cfset opm='Renewal of <a href="/Permit.cfm?Action=editPermit&permit_id=#old_permit.permit_id#">#old_permit.permit_id#</a>. (#old_permit.permit_remarks#)'>

			<cfquery name="new_permit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO permit (
			 		PERMIT_ID,
			 		ISSUED_DATE,
					EXP_DATE,
					PERMIT_NUM,
					PERMIT_REMARKS,
					use_condition,
					use_condition_summary
				) VALUES (
					<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
					<cfqueryparam CFSQLType="cf_sql_date" value="#old_permit.issued_date#" null="#Not Len(Trim(old_permit.issued_date))#">,
					<cfqueryparam CFSQLType="cf_sql_date" value="#old_permit.EXP_DATE#" null="#Not Len(Trim(old_permit.EXP_DATE))#">,
					<cfqueryparam value='#old_permit.PERMIT_NUM#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='#opm#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#old_permit.use_condition#" null="#Not Len(Trim(old_permit.use_condition))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#old_permit.use_condition_summary#" null="#Not Len(Trim(old_permit.use_condition_summary))#">
				)
			</cfquery>
			<!--- bring over old type(s) --->
			<cfloop query="old_permit_type">
				<cfquery name="newPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into permit_type (
						permit_type_id,
						permit_id,
						permit_type,
						PERMIT_REGULATION
					) values (
						nextval('sq_permit_type_id'),
						<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#old_permit_type.permit_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(old_permit_type.permit_type))#">,
						<cfqueryparam value = "#old_permit_type.PERMIT_REGULATION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(old_permit_type.PERMIT_REGULATION))#">
					)
				</cfquery>
			</cfloop>

			<!--- bring over old agent(s) --->
			<cfloop query="old_permit_agent">
				<cfquery name="newPermitBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into permit_agent (
						permit_agent_id,
						permit_id,
						agent_id,
						agent_role
					) values (
						nextval('sq_permit_agent_id'),
						#pid.pid#,
						#old_permit_agent.agent_id#,
						'#old_permit_agent.AGENT_ROLE#'
					)
				</cfquery>
			</cfloop>
			<!--- now add a link to the old permit --->
			<cfquery name="linkold" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update permit set permit_remarks=trim(
					'Renewed as <a href="/Permit.cfm?Action=editPermit&permit_id=#pid.pid#">#pid.pid#</a>. #old_permit.permit_remarks#')
					where permit_id=#old_permit.permit_id#
			</cfquery>
		</cftransaction>
		<cflocation url="Permit.cfm?Action=editPermit&permit_id=#pid.pid#" addtoken="false">

	</cfoutput>
</cfif>

<!--------------------------------------------------------------------------------------------------->
<cfif action is "editPermit">
	<cfset title="edit permit">
	<script>
		$(document).ready(function() {
			$('form').submit(function () {
				var hasPermitType=false;
				var hasIssuedTo=false;
				var hasIssuedBy=false;
				var theProbs=[];
				$("select[id^='permit_type_']").each(function(e){
					if ($(this).val().length>0){
						hasPermitType=true;
					}
				});
				$("input[id^='permit_agent_id_']").each(function(e){
					if ($(this).val().length>0){
						var bareID=this.id.replace('permit_agent_id_','');
						var matchRole='permit_agent_role_' + bareID;
						var theRole=$("#" + matchRole).val();
						if (theRole=='issued to'){
							hasIssuedTo=true;
						} else if (theRole=='issued by') {
							hasIssuedBy=true;
						}
					}
				});
				if (hasPermitType==false){
					theProbs.push('Provide at least one permit type.');
				}
				if (hasIssuedTo==false){
					theProbs.push('Provide at least one agent in role `issued to`.');
				}
				if (hasIssuedBy==false){
					theProbs.push('Provide at least one agent in role `issued by`.');
				}
				if (theProbs.length > 0){
					alert(theProbs.join("\n"));
					return false;
				}
			});
		});
		function renewThisPermit(){
			document.location='Permit.cfm?action=renewClone&permit_id=' + $("#permit_id").val();
		}
	</script>
	<cfoutput>
		<cfif not isdefined("permit_id") OR len(permit_id) is 0>
			Something bad happened. You didn't pass this form a permit_id. Go back and try again.<cfabort>
		</cfif>
		<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				permit.permit_id,
				issued_Date,
				exp_Date,
				permit_Num,
				permit_remarks,
				use_condition,
				use_condition_summary
			from
				permit
			where
				permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cfif permitInfo.recordcount lt 1>
			<div class="importantNotification">
				Permit not found.
			</div>
			<cfabort>
		</cfif>
		<table border width="100%">
			<tr>
				<td width="50%"  valign="top">
					<form name="editPermit" id="editPermit" action="Permit.cfm" method="post">
						<input type="hidden" name="action" value="saveChanges">
						<input type="hidden" name="permit_id" id="permit_id" value="#permit_id#">

						<p>The Basics</p>

						<label for="permit_num" class="helpLink" id="_permit_num">Permit Identifier/Number</label>
					  	<input type="text" name="permit_num" id="permit_num" class="reqdClr" required value="#permitInfo.permit_Num#">

						<label for="issued_date" class="helpLink" id="_issued_date">Issued Date</label>
						<input type="datetime" id="issued_date" name="issued_date" value="#dateformat(permitInfo.issued_Date,"yyyy-mm-dd")#">

					  	<label for="exp_date" class="helpLink" id="_exp_date">Expiration Date</label>
					  	<input type="datetime" id="exp_date" name="exp_date" value="#dateformat(permitInfo.exp_Date,"yyyy-mm-dd")#">

						<label for="permit_remarks" class="helpLink" id="_permit_remarks">Remarks</label>
					  	<textarea name="permit_remarks" class="hugetextarea">#permitInfo.permit_remarks#</textarea>
					  	<label for="remarks_as_HTML">Remarks as HTML</label>
					  	<div style="padding:1em;margin:1em;border:1px solid black;">
							#permitInfo.permit_remarks#
						</div>
						<p>
							Type & Regulation
							<div style="font-size:small;padding:1em;margin:1em;">
								At least one permit type is required.
								Choose TYPE and/or REGULATION, paired or not. Remove both to delete.
								Code tables are
								<a target="_blank" href="/info/ctDocumentation.cfm?table=CTPERMIT_TYPE">CTPERMIT_TYPE</a> and
								<a target="_blank" href="/info/ctDocumentation.cfm?table=CTPERMIT_REGULATION">CTPERMIT_REGULATION</a>
							</div>
						</p>

						<cfquery name="permitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select * from permit_type where permit_id=#permit_id#
						</cfquery>
						<table border>
							<tr>
								<th>Status</th>
								<th>Permit Type</th>
								<th>Regulation</th>
							</tr>
							<cfloop query="permitType">
								<tr>
									<td>Existing</td>
									<td>
										<select id="permit_type_#permit_type_id#" name="permit_type_#permit_type_id#" size="1">
											<option value=""></option>
											<cfloop query="ctPermitType">
												<option <cfif #ctPermitType.permit_type# is "#permitType.permit_type#"> selected </cfif>value = "#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
											</cfloop>
										</select>
									</td>
									<td>

										<select name="permit_regulation_#permit_type_id#" size="1">
											<option value=""></option>
											<cfloop query="ctPermitRegulation">
												<option <cfif #ctPermitRegulation.permit_regulation# is "#permitType.permit_regulation#"> selected </cfif>
												value = "#ctPermitRegulation.permit_regulation#">#ctPermitRegulation.permit_regulation#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</cfloop>
							<cfloop from="1" to="5" index="i">
								<tr class="newRec">
									<td>New (save to add more)</td>
									<td>
										<select id="permit_type_new#i#" name="permit_type_new#i#" size="1">
											<option value=""></option>
											<cfloop query="ctPermitType">
												<option value="#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
											</cfloop>
										</select>
									</td>
									<td>
										<select name="permit_regulation_new#i#" size="1">
											<option value=""></option>
											<cfloop query="ctPermitRegulation">
												<option value = "#ctPermitRegulation.permit_regulation#">#ctPermitRegulation.permit_regulation#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</cfloop>
						</table>

						<p>
							Use Condition
							<div style="font-size:small;padding:1em;margin:1em;">
								Concise summary of extra conditions imposed by this permit
							</div>
						</p>

						<label for="use_condition">Use Condition</label>
						<select name="use_condition" size="1">
							<option value=""></option>
							<cfloop query="ctuse_condition">
								<option value = "#ctuse_condition.use_condition#" <cfif permitInfo.use_condition is ctuse_condition.use_condition> selected="selected" </cfif> >#ctuse_condition.use_condition#</option>
							</cfloop>
						</select>

						<label for="use_condition_summary" class="helpLink" id="_use_condition_summary">Use Condition Summary</label>
					  	<textarea name="use_condition_summary" class="hugetextarea">#permitInfo.use_condition_summary#</textarea>


						<p>
							Agents
							<div style="font-size:small;padding:1em;margin:1em;">
								At least one "issued to" and "issued by" agent is required.
								Provide both an agent and role to create. Choose role DELETE to remove.
								Code table is
								<a target="_blank" href="/info/ctDocumentation.cfm?table=CTPERMIT_AGENT_ROLE">CTPERMIT_AGENT_ROLE</a>
							</div>
						</p>
						<cfquery name="permitAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select permit_agent_id,	permit_id,	agent_id,	agent_role, getPreferredAgentName(agent_id) as name from permit_agent where permit_id=#permit_id#
						</cfquery>
						<table border>
							<tr>
								<th>Status</th>
								<th>Agent</th>
								<th>Role</th>
							</tr>
							<cfloop query="permitAgent">
								<tr>
									<td>Existing</td>
									<td>
										<input type="hidden" id="permit_agent_id_#permit_agent_id#" name="permit_agent_id_#permit_agent_id#" value="#agent_id#">
										<input
											type="text"
											name="permit_agent_name_#permit_agent_id#"
											id="permit_agent_name_#permit_agent_id#"
											value="#name#"
											class="minput"
											onchange="pickAgentModal('permit_agent_id_#permit_agent_id#',this.id,this.value); return false;"
											onKeyPress="return noenter(event);"
											placeholder="agent">
									</td>
									<td>
										<select id="permit_agent_role_#permit_agent_id#" name="permit_agent_role_#permit_agent_id#" size="1">
											<option value="DELETE">DELETE</option>
											<cfloop query="ctPermitAgentRole">
												<option <cfif permitAgent.agent_role is ctPermitAgentRole.permit_agent_role> selected="selected" </cfif> value = "#ctPermitAgentRole.permit_agent_role#">#ctPermitAgentRole.permit_agent_role#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</cfloop>
							<cfloop from="1" to="5" index="i">
								<tr class="newRec">
									<td>New</td>
									<td>
										<input type="hidden" id="permit_agent_id_new#i#" name="permit_agent_id_new#i#">
										<input
											type="text"
											name="permit_agent_name_new#i#"
											id="permit_agent_name_new#i#"
											class="minput"
											onchange="pickAgentModal('permit_agent_id_new#i#',this.id,this.value); return false;"
											onKeyPress="return noenter(event);"
											placeholder="agent">
									</td>
									<td>
										<select id="permit_agent_role_new#i#" name="permit_agent_role_new#i#" size="1">
											<option value=""></option>
											<cfloop query="ctPermitAgentRole">
												<option value = "#ctPermitAgentRole.permit_agent_role#">#ctPermitAgentRole.permit_agent_role#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</cfloop>
						</table>
						<p>
							<input type="submit" value="Save changes" class="savBtn">
						</p>
						<p>
							<input type="button" value="Delete" class="delBtn"
						   		onCLick="document.location='Permit.cfm?permit_id=#permit_id#&action=deletePermit';">
						</p>
						<hr>
						<p>
							Renewals
							<div style="font-size:small;padding:1em;margin:1em;">
								Clicking this will:
								<ul>
									<li>Clone this permit as a new permit</li>
									<li>Add a link to this permit from the new permit</li>
									<li>Add a link to the new permit from this permit</li>
								</ul>

								Only SAVED information will be considered; save this first if you've made changes.
								<p>
									Links will work from the "Remarks as HTML" section.
								</p>
								<p>
									You will be redirected to the new permit; edit as appropriate.
								</p>
							</div>
						</p>
						<input type="button" value="Create a Renewal" class="insBtn" onclick="renewThisPermit()">
					</form>
				</td>
				<script>
					jQuery(document).ready(function(){
						$("##issued_date").datepicker();
						$("##exp_date").datepicker();
			            $("##mediaUpClickThis").click(function(){
						    addMedia('permit_id','#permit_id#');
						});
						getMedia('permit','#permit_id#','pMedia','2','1');
					});
				</script>
				<td width="50%" valign="top">
					<h3>Permit Media</h3>
					<cfif listcontainsnocase(session.roles, "manage_media")>
						<a class="likeLink" id="mediaUpClickThis">Attach/Upload Media</a>
					</cfif>
					<div id="pMedia"></div>
					<hr>
					<h3>Permit Transactions</h3>
					<cfquery name="p_trans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select 
							permit_trans.transaction_id,
							collection.guid_prefix,
							trans.transaction_type,
							accn.accn_number as trans_id
						 from 
						 	permit_trans
						 	inner join trans on permit_trans.transaction_id=trans.transaction_id
						 	inner join collection on trans.collection_id=collection.collection_id
						 	inner join accn on trans.transaction_id=accn.transaction_id
					 	 where 
					 	 	permit_trans.permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
					 	 union
					 	 select 
							permit_trans.transaction_id,
							collection.guid_prefix,
							trans.transaction_type,
							loan.loan_number as trans_id
						 from 
						 	permit_trans
						 	inner join trans on permit_trans.transaction_id=trans.transaction_id
						 	inner join collection on trans.collection_id=collection.collection_id
						 	inner join loan on trans.transaction_id=loan.transaction_id
					 	 where 
					 	 	permit_trans.permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
					 	 union
					 	 select 
							permit_trans.transaction_id,
							collection.guid_prefix,
							trans.transaction_type,
							borrow.borrow_number as trans_id
						 from 
						 	permit_trans
						 	inner join trans on permit_trans.transaction_id=trans.transaction_id
						 	inner join collection on trans.collection_id=collection.collection_id
						 	inner join borrow on trans.transaction_id=borrow.transaction_id
					 	 where 
					 	 	permit_trans.permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif p_trans.recordcount gt 0>
						<ul>
							<cfloop query="p_trans">
								<li>
									<cfif transaction_type is 'accn'>
										Accession <a href="/accn.cfm?action=edit&transaction_id=#transaction_id#">#guid_prefix# #trans_id#</a>
									<cfelseif transaction_type is 'loan'>
										Loan <a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #trans_id#</a>
									<cfelseif transaction_type is 'borrow'>
										Borrow <a href="/borrow.cfm?action=edit&transaction_id=#transaction_id#">#guid_prefix# #trans_id#</a>
									</cfif>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</td>
			</tr>
		</table>
</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------->
<cfif action is "saveChanges">
	<cfoutput>
		<cftransaction>
			<cfquery name="updatePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					permit
				SET
					ISSUED_DATE = <cfqueryparam value = "#ISSUED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(ISSUED_DATE))#">,
					EXP_DATE = <cfqueryparam value = "#EXP_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(EXP_DATE))#">,
					PERMIT_NUM = <cfqueryparam value = "#PERMIT_NUM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PERMIT_NUM))#">,
					PERMIT_REMARKS = <cfqueryparam value = "#PERMIT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PERMIT_REMARKS))#">,
					use_condition = <cfqueryparam value = "#use_condition#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(use_condition))#">,
					use_condition_summary = <cfqueryparam value = "#use_condition_summary#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(use_condition_summary))#">
				where
					permit_id=<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<CFLOOP index="thisfield" list="#FORM.FIELDNAMES#">
				<cfif left(thisfield,12) is 'permit_type_'>
					<br>permit type....
					<cfset thisPermitTypeId=listlast(thisField,"_")>
					<br>thisPermitTypeId: #thisPermitTypeId#
					<cfset thisPermitType=evaluate("permit_type_" & thisPermitTypeId)>
					<br>thisPermitType: #thisPermitType#
					<cfset thisPermitReg=evaluate("permit_regulation_" & thisPermitTypeId)>
					<br>thisPermitReg: #thisPermitReg#
					<cfif left(thisPermitTypeId,3) is "new" and (len(thisPermitType) gt 0 or len(thisPermitReg) gt 0)>
						<cfquery name="ipt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into permit_type (
								permit_id,
								permit_type,
								permit_regulation
							) values (
								<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">,
								<cfqueryparam value = "#thisPermitType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPermitType))#">,
								<cfqueryparam value = "#thisPermitReg#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPermitReg))#">
							)
						</cfquery>
					<cfelseif left(thisPermitTypeId,3) is not "new" and (len(thisPermitType) gt 0 or len(thisPermitReg) gt 0)>
						<cfquery name="upt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update permit_type set
								permit_type=<cfqueryparam value = "#thisPermitType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPermitType))#">,
								permit_regulation=<cfqueryparam value = "#thisPermitReg#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPermitReg))#">
							where
								permit_type_id=<cfqueryparam value="#thisPermitTypeId#" cfsqltype="cf_sql_int">
						</cfquery>
					<cfelseif left(thisPermitTypeId,3) is not "new" and len(thisPermitType) is 0 and len(thisPermitReg) is 0>
						<cfquery name="dpt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from permit_type
							where
								permit_type_id=<cfqueryparam value="#thisPermitTypeId#" cfsqltype="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
				<cfif left(thisfield,16) is 'permit_agent_id_'>
					<cfset thisPermitAgentId=listlast(thisField,"_")>
					<cfset thisPermitAgent=evaluate("permit_agent_id_" & thisPermitAgentId)>
					<cfset thisPermitAgentRole=evaluate("permit_agent_role_" & thisPermitAgentId)>
					<cfif left(thisPermitAgentId,3) is "new" and len(thisPermitAgent) gt 0 and len(thisPermitAgentRole) gt 0>
						<cfquery name="ipag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into permit_agent (
								permit_id,
								agent_id,
								agent_role
							) values (
								<cfqueryparam value="#permit_id#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#thisPermitAgent#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#thisPermitAgentRole#" cfsqltype="cf_sql_varchar">
							)
						</cfquery>
					<cfelseif left(thisPermitAgentId,3) is not "new">
						<cfif thisPermitAgentRole is "DELETE">
							<cfquery name="dpag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from permit_agent where permit_agent_id=<cfqueryparam value="#thisPermitTypeId#" cfsqltype="cf_sql_int">
							</cfquery>
						<cfelse>
							<cfquery name="dpag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update 
									permit_agent 
								set 
									agent_id=<cfqueryparam value="#thisPermitAgent#" cfsqltype="cf_sql_int">,
									agent_role=<cfqueryparam value="#thisPermitAgentRole#" cfsqltype="cf_sql_varchar">
								where  
									permit_agent_id=<cfqueryparam value="#thisPermitAgentId#" cfsqltype="cf_sql_int">
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			</CFLOOP>
		</cftransaction>
		<cflocation url="Permit.cfm?Action=editPermit&permit_id=#permit_id#" addtoken="false">
	</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<cfif action is "createPermit">
	<cfoutput>
		<cfquery name="nextPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_permit_id') nextPermit
		</cfquery>
		<cftransaction>
			<cfquery name="newPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO permit (
			 		PERMIT_ID,
			 		ISSUED_DATE,
					EXP_DATE,
					PERMIT_NUM,
					PERMIT_REMARKS
				) VALUES (
					#nextPermit.nextPermit#,
					<cfqueryparam value = "#ISSUED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(ISSUED_DATE))#">,
					<cfqueryparam value = "#EXP_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(EXP_DATE))#">,
					<cfqueryparam value = "#PERMIT_NUM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PERMIT_NUM))#">,
					<cfqueryparam value = "#permit_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(permit_remarks))#">
				)
			</cfquery>
			<cfquery name="newPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into permit_type (
					permit_type_id,
					permit_id,
					permit_type
				) values (
					nextval('sq_permit_type_id'),
					#nextPermit.nextPermit#,
					'#permit_type#'
				)
			</cfquery>
			<cfquery name="newPermitBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into permit_agent (
					permit_agent_id,
					permit_id,
					agent_id,
					agent_role
				) values (
					nextval('sq_permit_agent_id'),
					#nextPermit.nextPermit#,
					#issued_by_agent_id#,
					'issued by'
				)
			</cfquery>
			<cfquery name="newPermitTo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into permit_agent (
					permit_agent_id,
					permit_id,
					agent_id,
					agent_role
				) values (
					nextval('sq_permit_agent_id'),
					#nextPermit.nextPermit#,
					#issued_to_agent_id#,
					'issued to'
				)
			</cfquery>
		</cftransaction>
		<cflocation url="Permit.cfm?Action=editPermit&permit_id=#nextPermit.nextPermit#" addtoken="false">
  </cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<cfif action is "deletePermit">
<cfoutput>
	<cftransaction>
		<cfquery name="deletePermitA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from permit_agent WHERE permit_id = #permit_id#
		</cfquery>
		<cfquery name="deletePermitt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from permit_type WHERE permit_id = #permit_id#
		</cfquery>
		<cfquery name="deletePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			DELETE FROM permit WHERE permit_id = #permit_id#
		</cfquery>
	</cftransaction>
	<cflocation url="Permit.cfm" addtoken="false">
  </cfoutput>
</cfif>
<cfinclude template = "includes/_footer.cfm">