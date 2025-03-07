<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<style>
		#agent_attr_outer {
			
		}
		.one_agent_attr{
			margin:.3em;
			display: flex;
			flex-wrap: wrap;
			padding:.2em;
			justify-content: space-between;
		}
		.one_attr_item{
			padding:.3em;
			background-color: inherit;
		}
	
		<!---- https://github.com/ArctosDB/arctos/issues/7352#issuecomment-1950227769 - it's not, it's this, because reasons I guess....
	teresa + michelle call no stripe
		tr:nth-child(even) {
			background-color: var(--arctoslightblue);
		}

	tr:nth-child(odd) {
			background-color: #EDF1F9;
		}
		---->
	

		.c_d_div{
			font-size: smaller;
			border: 1px solid black;
			font-weight: bold;
			padding:.2em;
		}

		.public_term {
			border:1px solid green;
		}
		.private_term {
			border:1px solid red;
		}
		.tbl_typ_lbl{
			text-align: center;
			width: 100%;
			background-color: var(--arctosdarkblue);
			color: white;
		}

		.tbl_typ_lbl_create{
			text-align: center;
			width: 100%;
			background-color: #D6F5F2;
		}



		.the_type_pick {
			width: 10em;
		}
		.metaflex{
			display: flex;
			flex-wrap: wrap;
	  		align-items: center;
			 justify-content: space-between;
		}
		.agentMeta{

			margin-left: 2em;
			font-size: smaller;
		}
		.titleFlex {
			display: flex;
			flex-wrap: wrap;
			 justify-content: space-between;
	  		align-items: center;
		}
		.agent_name{
			font-weight: bold;
			font-size: 2em;
		}

		.topjunkflex{
			display: flex;
			flex-wrap: wrap;
			 justify-content: space-between;
	  		align-items: center;
			align-items:flex-end; 
		}

		.shippingtextarea {
			width:30em;
			height:5em;
			margin:0.3em;

		}

		.profiletextarea{
			width:30em;
			height:15em;
			margin:0.3em;

		}

        #pMedia{
        	
        }
        #turd_reports{
        	
        }

        #dqdiv{
        	max-height: 20em;
        	overflow: auto;
        }

        #csdiv{
        	max-height: 20em;
        	overflow: auto;
        }
        #dqtitle{
        	font-weight: bold;
        }
        .editAgentTR{

        }


		.markdownControls{
			border: 1px solid black;
			background-color: lightgrey;
			padding:0em 1em 0em 1em;
			display: flex;
			flex-wrap: wrap;
			justify-content:space-evenly;
		}

		.mdToolBtn{
			cursor: pointer;
			border: 4px solid black;
			padding:.1em;
			margin:.1em;
			border-style: groove;
			border-radius: 5px;
		}



		.mdToolBtn:hover {
			text-decoration: underline;
			color: #CC0000;
			border-color: #85170f;
		}






	</style>
	<script>
		function mditalics(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '*' + sel + '*';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdbold(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '**' + sel + '**';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdh1(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '\n\n' + '# ' + sel + '\n\n';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdh2(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '\n\n' + '## ' + sel + '\n\n';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdh3(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '\n\n' + '### ' + sel + '\n\n';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdh4(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			if (sel.length>0){
				var replace = '\n\n' + '#### ' + sel + '\n\n';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function mdlink(e){
			var textarea = document.getElementById(e);
			var len = textarea.value.length;
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			var sel = textarea.value.substring(start, end);
			let txt = prompt("Enter the clickable text",sel);
			let lnk = prompt("Enter the link or URL");

			if (sel.length>0){
				var replace = '[' + txt + '](' + lnk + ')';
				textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
			}
		}
		function create_attribute(aid){
			var vocab_stash=$("#vocab_stash").val();
			vocab_stash=JSON.parse(vocab_stash);
			var source_type=$("#attribute_type_" + aid).val()
			var thisVocab='';
			vocab_stash.forEach(function (item, index) {
	  			if (item.attribute_type==source_type){
	  				thisVocab=item.vocabulary;
	  			}
			});

			// remove here, simplifies adding below and we can handle the inefficiencies

			$("#create_div_" + aid).removeClass();
			$("#relagent_div_" + aid).removeClass();
			$("#detdate_div_" + aid).removeClass();
			$("#detagnt_div_" + aid).removeClass();
			$("#create_meth_div_" + aid).removeClass();

		
			if (thisVocab.length > 0){
				var vary=thisVocab.split(',');
				var theObj='<select name="attribute_value_' + aid + '" id="attribute_value_' + aid + '">';
				vary.forEach(function (item, index) {
					theObj+='<option value="' + item + '">' + item + '</option>';
				});
				theObj+='</select>';
				$("#create_div_" + aid).html(theObj);
			} else {
				console.log('elsing for source_type: ' + source_type);
				console.log('aid: ' + aid);

				//undo any readonlying for relationships
				$("#attribute_value_" + aid).removeClass().prop("readonly", false);

				var category=$('#attribute_type_' + aid + ' :selected').parent().attr('label');
				console.log('category: ' + category);
				if ( source_type=='shipping' || source_type=='correspondence' || source_type=='formatted JSON' ){
					var theClass='shippingtextarea';
				} else if ( source_type=='remarks' || source_type=='curatorial remarks' || source_type=='profile' ){
					var theClass='profiletextarea';
				} else {
					var theClass='mediumtextarea';
				}

				var theObj='<textarea class="' + theClass + '" name="attribute_value_' + aid + '" id="attribute_value_' + aid + '"></textarea>';
				if (theClass=='profiletextarea'){
					theObj+='<div>Save and edit to access markdown helper tools.</div>';
				}
				$("#create_div_" + aid).html(theObj);
				$("#create_div_" + aid).addClass('highlightst');
				// relationships DO NOT require value, so remove it and add in agents
				if (category=='relationship'){
					$("#create_div_" + aid).removeClass();
					$("#relagent_div_" + aid).addClass('highlightst');

					$("#attribute_value_" + aid).val('').addClass('readClr').prop("readonly", true);

					// dups require more metadata
					if (source_type=='bad duplicate of'){
						$("#detdate_div_" + aid).addClass('highlightst');
						$("#detagnt_div_" + aid).addClass('highlightst');
						$("#create_meth_div_" + aid).addClass('highlightst');
					}					
				}
			}
		}

		$(document).ready(function() {
			$(".reqdClr:visible").each(function(e){
			    $(this).prop('required',true);
			});
			$("#mediaUpClickThis").click(function(){
			    addMedia('agent_id',$("#agent_id").val());
			});
			getMedia('agent',$("#agent_id").val(),'pMedia','2','1');

			$.get( "/info/agent_turd.cfm?agent_id=" + $("#agent_id").val(), function( guts ) {
				$("#turd_reports").html(guts);
			});
			
			// have to keep this here - it's not called from ajax.js on injected forms
			$("input[type='date'], input[type='datetime']" ).datepicker();
		});
	</script>
	<!------------------------------------------------------------------------------------------------------------->
	<cfif not isdefined("agent_id") OR agent_id lt 0 >
		<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				agent.agent_id,
				agent.preferred_agent_name,
				agent.agent_type,
				agent.created_by_agent_id agent_created_agent_id,
				getPreferredAgentName(agent.created_by_agent_id) agent_created_agent,
				to_char(agent.created_date,'YYYY-MM-DD') agent_created_date,
				agent_attribute.attribute_id,
				agent_attribute.attribute_type,
				agent_attribute.attribute_value,
				agent_attribute.begin_date,
				agent_attribute.end_date,
				agent_attribute.related_agent_id,
				getPreferredAgentName(agent_attribute.related_agent_id) related_agent,
				agent_attribute.determined_date,
				agent_attribute.attribute_determiner_id,
				getPreferredAgentName(agent_attribute.attribute_determiner_id) attribute_determiner,
				agent_attribute.attribute_method,
				agent_attribute.attribute_remark,
				agent_attribute.created_by_agent_id,
				getPreferredAgentName(agent_attribute.created_by_agent_id) created_by,
				agent_attribute.created_timestamp,
				agent_attribute.deprecated_by_agent_id,
				getPreferredAgentName(agent_attribute.deprecated_by_agent_id) deprecated_by,
				agent_attribute.deprecated_timestamp,
				agent_attribute.deprecation_type
			from 
				agent
				left outer join agent_attribute on agent.agent_id=agent_attribute.agent_id
			where 
				agent.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<cfquery name="agent" dbtype="query">
			select 
				agent_id,
				preferred_agent_name,
				agent_type,
				agent_created_agent_id,
				agent_created_agent,
				agent_created_date
			from raw group by 
				agent_id,
				preferred_agent_name,
				agent_type,
				agent_created_agent_id,
				agent_created_agent,
				agent_created_date
		</cfquery>
		<cfif agent.recordcount neq 1>
			nope<cfabort>
		</cfif>


		<cfset title='Edit #agent.preferred_agent_name#'>


		<cfquery name="ctAgent_Type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select agent_type from ctagent_type order by agent_type
		</cfquery>
		<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type,public,purpose,vocabulary from ctagent_attribute_type
		</cfquery>

		<cfquery name="a_w_v" dbtype="query">
			select attribute_type,vocabulary from ctagent_attribute_type_raw where vocabulary is not null
		</cfquery>
		<cfset ja_w_v=serializeJSON(a_w_v,'struct')>
		<input type="hidden" id="vocab_stash" value="#EncodeForHTML(canonicalize(ja_w_v,true,true))#">
		
		<cfquery name="activitySummary" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				guid_prefix,
				min(began_date) earliest,
				max(ended_date) latest,
				count(*) numSpecs
			from
				collector
				inner join cataloged_item on collector.collection_object_id=cataloged_item.collection_object_id
				inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
				inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
				inner join collection on cataloged_item.collection_id=collection.collection_id 
			where
				collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			group by
				guid_prefix
			order by
				numSpecs desc,
				guid_prefix
		</cfquery>

		<cfquery name="reciprelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					agent.agent_id,
					agent.preferred_agent_name,
					attribute_type,
					attribute_value,
					begin_date,
					end_date,
					related_agent_id,
					getPreferredAgentName(agent_attribute.related_agent_id) related_agent,
					determined_date,
					attribute_determiner_id,
					getPreferredAgentName(agent_attribute.attribute_determiner_id) attribute_determiner,				
					attribute_method,
					attribute_remark,
					agent_attribute.created_by_agent_id,
					getPreferredAgentName(agent_attribute.created_by_agent_id) created_by,
					agent_attribute.created_timestamp
				from
					agent
					inner join agent_attribute on agent.agent_id=agent_attribute.agent_id
				where
					deprecation_type is null and
					agent_attribute.related_agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
			</cfquery>

			<!---- moving this to table
			<cfif reciprelns.recordcount gt 0>
				<div>
					<div>
						Incoming Relationships
					</div>
					<div>
						<cfloop query="reciprelns">
							<div>
								From #preferred_agent_name#: #attribute_type# 
								<a class="external" href="/agent/#agent_id#">info</a>
								|
								<a href="edit_agent.cfm?agent_id=#agent_id#" class="external">edit</a>
							</div>
						</cfloop>
					</div>
				</div>
			</cfif>
			---->



		<cfquery name="no_edit_attr_type" dbtype="query">
			select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="history" cfsqltype="cf_sql_varchar">
		</cfquery>

		<!----------- exclude things we don't really want edited from this too---->
		<cfquery name="cats" dbtype="query">
			select purpose from ctagent_attribute_type_raw 
			where  attribute_type not in ( <cfqueryparam value="#valuelist(no_edit_attr_type.attribute_type)#" cfsqltype="cf_sql_varchar" list="true"> )
			group by purpose order by purpose
		</cfquery>

		<cfquery name="agent_attribute_deprecated" dbtype="query">
			select
				attribute_id
			from 
				raw 
			where
				attribute_id is not null and 
				deprecation_type is not null
				<!----------- exclude things we don't really want edited ---->
				and attribute_type not in ( <cfqueryparam value="#valuelist(no_edit_attr_type.attribute_type)#" cfsqltype="cf_sql_varchar" list="true"> )
			group by
				attribute_id
		</cfquery>

		<cfquery name="current_status" dbtype="query">
			select
				attribute_id,
				attribute_type,
				attribute_value
			from 
				raw 
			where
				deprecation_type is null and
				attribute_type in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> )
			group by
				attribute_id,
				attribute_type,
				attribute_value
		</cfquery>

		<div class="titleFlex">
			<div class="agent_name">
				#agent.preferred_agent_name#
				<cfif current_status.recordcount is 0>
					<i class="fas fa-circle-question" style="color:##A36A00;" title="verification status: no information"></i>
				<cfelse>
					<cfloop query="current_status">
						<cfif attribute_value is "verified">
							<i class="fas fa-star" style="color:gold;" title="verification status: verified"></i>
						<cfelseif attribute_value is "accepted">
							<i class="fas fa-check" style="color:green;" title="verification status: accepted"></i>
						<cfelseif attribute_value is "unverified">
							<i class="fas fa-exclamation-triangle" style="color:##ff8300;" title="verification status: unverified"></i>
						<cfelseif attribute_value is "flagged">
							<i class="fa-solid fa-flag" style="color: ##FF5F15;" title="Flagged: Proceed with caution!"></i>
						<cfelseif attribute_value is "duplicate">
							<span style="font-size: xx-large; color: red;" title="Bad Duplicate run away!"><i class="fas fa-trash"></i></span>
						</cfif>
					</cfloop>
				</cfif>
			</div>
			<div class="agentMeta">
				AgentID #agent.agent_id# 
				<cfif len(agent.agent_created_agent_id) gt 0 and agent.agent_created_agent_id neq 0>
					created by <a href="/agent/#agent.agent_created_agent_id#" class="external">#agent.agent_created_agent#</a> on #agent.agent_created_date#
				</cfif>
			</div>
			<div>
				<cfif listcontainsnocase(session.roles,"manage_transactions")>
					<cfquery name="rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select count(*) || ' ' || agent_rank agent_rank from agent_rank where agent_id=#agent_id# group by agent_rank
					</cfquery>
					<br>
					<cfif rank.recordcount gt 0>
						Previous Ranking: #valuelist(rank.agent_rank,"; ")#
					</cfif>
					<input type="button" class="lnkBtn" onclick="rankAgent('#agent.agent_id#');" value="Rank">
				</cfif>
			</div>

			<div style="border:2px dashed red;padding:.2em;margin:.2em;font-weight:bold;">
				<span class="helpLink" data-helplink="agent">Read the documentation</span>

				and view the  <a href="/agent/#agent_id#?deets=true" target="_blank">full Agent Activity Report</a>
				before changing anything.  Or return to <a href="/agent/#agent_id#" target="_blank">Summary Report</a>.
			</div>
		</div>
		<hr>	
		<div class="topjunkflex">
			<div id="dqdiv"><!----- agent check div ---->
				<div id="dqtitle">
					Data Quality Alerts
				</div>
				<cfset sobj=[=]>
				<cfset sobj["agent_type"]=agent.agent_type>
				<cfset sobj["agent_id"]=agent.agent_id>
				<cfset sobj["preferred_agent_name"]=agent.preferred_agent_name>
				<cfset sobj["created_by_agent_id"]=agent.agent_created_agent_id>
				<cfset attribute_id_list="">
				<cfset attribute_id=1>
				<cfquery name="all_atts" dbtype="query">
					select
						attribute_id,
						attribute_type,
						attribute_value,
						begin_date,
						end_date,
						related_agent_id,
						related_agent,
						determined_date,
						attribute_determiner_id,
						attribute_determiner,
						attribute_method,
						attribute_remark,
						created_by_agent_id,
						created_by,
						created_timestamp,
						deprecated_by_agent_id,
						deprecated_by,
						deprecated_timestamp,
						deprecation_type
					from 
						raw 
					where
						attribute_id is not null and 
						deprecation_type is null
					group by
						attribute_id,
						attribute_type,
						attribute_value,
						begin_date,
						end_date,
						related_agent_id,
						related_agent,
						determined_date,
						attribute_determiner_id,
						attribute_determiner,
						attribute_method,
						attribute_remark,
						created_by_agent_id,
						created_by,
						created_timestamp,
						deprecated_by_agent_id,
						deprecated_by,
						deprecated_timestamp,
						deprecation_type
				</cfquery>
				<cfloop query="all_atts">
					<cfset sobj["attribute_type_#attribute_id#"]=attribute_type>
					<cfset sobj["attribute_value_#attribute_id#"]=attribute_value>
					<cfset sobj["begin_date_#attribute_id#"]=begin_date>
					<cfset sobj["end_date_#attribute_id#"]=end_date>
					<cfset sobj["related_agent_id_#attribute_id#"]=related_agent_id>
					<cfset sobj["related_agent_#attribute_id#"]=related_agent>
					<cfset sobj["determined_date_#attribute_id#"]=determined_date>
					<cfset sobj["attribute_determiner_id_#attribute_id#"]=attribute_determiner_id>
					<cfset sobj["attribute_method_#attribute_id#"]=attribute_method>
					<cfset sobj["attribute_remark_#attribute_id#"]=attribute_remark>
					<cfset sobj["created_by_agent_id_#attribute_id#"]=deprecated_by_agent_id>
					<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
				</cfloop>
				<cfset sobj["attribute_id_list"]=attribute_id_list>
				<cfset sobj=serializeJSON(sobj)>
				<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
				<cfinvoke component="/component/api/agent" method="check_agent" returnvariable="x">
					<cfinvokeargument name="api_key" value="#api_key#">
					<cfinvokeargument name="usr" value="#session.dbuser#">
					<cfinvokeargument name="pwd" value="#session.epw#">
					<cfinvokeargument name="pk" value="#session.sessionKey#">
					<cfinvokeargument name="data" value="#sobj#">
				</cfinvoke>
				<cfif isdefined("x.message") and x.message is "success">
					<cfset thisProbs=x.problems>
					<cfif arraylen(thisProbs) gt 0>
						<p>
							Possible Duplicates:
						</p>
						<table border="1">
							<tr>
								<th>Agent</th>
								<th>Agent Type</th>
								<th>WhatsUp</th>
							</tr>
							<cfloop array="#thisProbs#" index="i">
								<tr>
									<td>
										<cfif len(i["AGENT_ID"]) gt 0>
											<a href="/agent/#i["AGENT_ID"]#" class="external">#i["PREFERRED_AGENT_NAME"]#</a>
											<a href="/edit_agent.cfm?agent_id=#i["AGENT_ID"]#" class="external"><input type="button" class="lnkBtn" value="edit"></a>
										<cfelseif len(i["PREFERRED_AGENT_NAME"]) gt 0>
											#i["PREFERRED_AGENT_NAME"]#
										</cfif>
									</td>
									<td>#i["AGENT_TYPE"]#</td>
									<td>#i["SUBJECT"]#</td>
								</tr>
							</cfloop>
						</table>
					</cfif>
				<cfelse>
					checkfail
					<cfdump var="#x#">
				</cfif>
				<div id="turd_reports"></div><!----- TURD div ---->
			</div><!----- agent check div ---->
			<div id="csdiv"><!----- collecting summary div ---->
				<div>
					Collecting Summary
				</div>
				<table border>
					<tr>
						<th>Collection</th>
						<th>Earliest Date</th>
						<th>Latest Date</th>
						<th>NumberRecords</th>
					</tr>
					<cfloop query="activitySummary">
						<tr>
							<td>#guid_prefix#</td>
							<td>#earliest#</td>
							<td>#latest#</td>
							<td>#numSpecs#</td>
						</tr>
					</cfloop>
				</table>
			</div><!----- collecting summary div ---->
			<div><!----- media div ---->
				<div>
					Media
				</div>
				<cfif listcontainsnocase(session.roles, "manage_media")>
					<a class="likeLink" id="mediaUpClickThis">Attach/Upload Media</a>
				</cfif>
				<div id="pMedia"></div>
			</div><!----- media div ---->
		</div>
		<hr>
		<cfset numNewRows=3>
		<form name="edit_agent_attribute" method="post" action="edit_agent.cfm">
			<input type="hidden" name="action" value="edit_agent_attribute">
			<input type="hidden" name="agent_id" id="agent_id" value="#agent_id#">
			<input type="hidden" name="numNewRows" value="#numNewRows#">
			<cfset current_ids="">
			
			<div class="metaflex">
				<div>
					<input type="submit" value="save" class="savBtn">
				</div>
				<div>
					<label for="preferred_agent_name">Preferred Name</label>
					<input type="text" value="#encodeforhtml(agent.preferred_agent_name)#" name="preferred_agent_name" id="preferred_agent_name" class="reqdClr minput">
				</div>
				<div>
					<label for="agent_type">Agent Type</label>
					<select name="agent_type" id="agent_type" class="reqdClr">
						<cfloop query="ctAgent_Type">
							<option  <cfif ctAgent_Type.agent_type is agent.agent_type> selected="selected" </cfif>
								value="#ctAgent_Type.agent_type#">#ctAgent_Type.agent_type#</option>
						</cfloop>
					</select>
					<span class="infoLink" onclick="getCtDoc('ctagent_type','agent_type');">Define</span>
				</div>
				<div>
					<cfif agent_attribute_deprecated.recordcount gt 0>
						<a href="/info/all_agent_attribute.cfm?agent_id=#agent_id#" class="external">view change log</a>
					</cfif>
				</div>
				<div>
					<input type="button" class="lnkBtn" onclick="getCtDoc('ctagent_attribute_type');" value="Attribute Code Table">
				</div>
			</div>
			<table border="1">
				<tr class="tbl_typ_lbl_create">
					<td>Create Attribute</td>
					<td>attribute value</td>
					<td>begin date</td>
					<td>end date</td>
					<td>related agent</td>
					<td>determined</td>
					<td>determiner</td>
					<td>method</td>
					<td>remark</td>
					<td>Meta</td>
				</tr>
				<cfloop from="1" to="#numNewRows#" index="i">
					<cfset attribute_id="new_#i#">
					<tr class="newRec">
						<td>
							<select name="attribute_type_#attribute_id#" id="attribute_type_#attribute_id#" onchange="create_attribute('#attribute_id#');" class="the_type_pick">
								<option>select to create</option>
								<cfloop query="cats">
									<cfquery name="thisVals" dbtype="query">
										select attribute_type, public from ctagent_attribute_type_raw where 
											purpose=<cfqueryparam value="#purpose#" cfsqltype="cf_sql_varchar"> and
											attribute_type != 'login'
										order by attribute_type
									</cfquery>
									<optgroup label="#purpose#">
										<cfloop query="thisVals">
											<option value="#attribute_type#">
												#attribute_type#
												<cfif attribute_type is "status" and current_status.recordcount gt 0>
													**already exists**
												</cfif>
											</option>
										</cfloop>
									</optgroup>
								</cfloop>
							</select>
						</td>
						<td>
							<div id="create_div_#attribute_id#">
								<textarea class="mediumtextarea" name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#" placeholder="attribute value"></textarea>
							</div>
						</td>
						<td>
							<input type="datetime" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="8" placeholder="begin">
						</td>
						<td>
							<input type="datetime" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="8" placeholder="end">
						</td>
						<td>
							<div id="relagent_div_#attribute_id#">
								<input type="hidden" id="related_agent_id_#attribute_id#" name="related_agent_id_#attribute_id#" value="">
								<input type="text" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
									onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
									onkeypress="return noenter(event);" placeholder="type+tab: related agent" class="pickInput">
							</div>
						</td>
						<td>
							<div id="detdate_div_#attribute_id#">
								<input type="datetime" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="8" value="" placeholder="date determined">
							</div>
						</td>
						<td>
							<div id="detagnt_div_#attribute_id#">
								<input type="hidden" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#" placeholder="determiner">
								<input type="text" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
									onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
									onkeypress="return noenter(event);" value="" placeholder="type+tab: determiner" class="pickInput">
							</div>
						</td>
						<td>
							<div id="create_meth_div_#attribute_id#">
								<textarea class="smalltextarea" name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#"  placeholder="method"></textarea>
							</div>
						</td>
						<td>
							<textarea class="smalltextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#" placeholder="remark"></textarea>
						</td>
						<td></td>
					</tr>
				</cfloop>
				<tr>
					<td colspan="10" >
						<div class="tbl_typ_lbl">
							Manage Existing Attributes
						</div>
					</td>
				</tr>
				<cfloop query="cats">
					<cfquery name="this_cat_types" dbtype="query">
						select attribute_type,vocabulary from ctagent_attribute_type_raw where purpose=<cfqueryparam value="#purpose#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfquery name="this_cat" dbtype="query">
						select
							attribute_id,
							attribute_type,
							attribute_value,
							begin_date,
							end_date,
							related_agent_id,
							related_agent,
							determined_date,
							attribute_determiner_id,
							attribute_determiner,
							attribute_method,
							attribute_remark,
							created_by_agent_id,
							created_by,
							created_timestamp,
							deprecated_by_agent_id,
							deprecated_by,
							deprecated_timestamp,
							deprecation_type
						from 
							raw 
						where
							attribute_id is not null and 
							deprecation_type is null and
							attribute_type in ( <cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valuelist(this_cat_types.attribute_type)#"> )
						group by
							attribute_id,
							attribute_type,
							attribute_value,
							begin_date,
							end_date,
							related_agent_id,
							related_agent,
							determined_date,
							attribute_determiner_id,
							attribute_determiner,
							attribute_method,
							attribute_remark,
							created_by_agent_id,
							created_by,
							created_timestamp,
							deprecated_by_agent_id,
							deprecated_by,
							deprecated_timestamp,
							deprecation_type
						order by
							attribute_type
					</cfquery>
					<!--------
					<tr>
						<td colspan="10" >
							<div class="tbl_typ_lbl">
								<cfif this_cat.recordcount gt 0>
									Manage #purpose# attributes
								<cfelse>
									No #purpose# attributes :(
								</cfif>
							</div>
						</td>
					</tr>
					---------->
					<tr class="tbl_typ_lbl">
						<td>#purpose#</td>
						<td>attribute value</td>
						<td>begin date</td>
						<td>end date</td>
						<td>related agent</td>
						<td>determined</td>
						<td>determiner</td>
						<td>method</td>
						<td>remark</td>
						<td>Meta</td>
					</tr>
					
					<cfloop query="this_cat">
						<cfset current_ids=listappend(current_ids,attribute_id)>
						<cfquery name="is_pp" dbtype="query">
							select public,vocabulary from ctagent_attribute_type_raw where attribute_type=<cfqueryparam value="#attribute_type#" cfsqltype="cf_sql_varchar">
						</cfquery>
						<tr>
							<td>
								<select name="attribute_type_#attribute_id#" class="the_type_pick">
									<cfif attribute_type neq "login">
										<option value="DELETE">DELETE</option>
									</cfif>
									<option selected = "selected" value="#attribute_type#">#attribute_type#</option>
									<!---- do not allow change type, too complicated just delete and re-add
									<cfloop query="ctagent_attribute_type">
										<option <cfif this_cat.attribute_type is ctagent_attribute_type.attribute_type> selected = "selected" </cfif> value="#attribute_type#">#attribute_type#</option>
									</cfloop>
									---->
								</select>
								<cfif is_pp.public>
									<i class="fa fa-users" title="public information"></i>
								<cfelse>
									<i class="fa fa-user-secret" aria-hidden="true" title="private information"></i>
								</cfif>
							</td>
							<td>
								<cfif len(is_pp.vocabulary) gt 0>
									<select name="attribute_value_#attribute_id#">
										<cfloop list="#is_pp.vocabulary#" index="i">
											<option <cfif attribute_value is i> selected = "selected" </cfif> value="#i#">#i#</option>
										</cfloop>
									</select>
								<cfelseif purpose is "relationship">
									<input type="hidden" name="attribute_value_#attribute_id#" if="attribute_value_#attribute_id#" value="#encodeforhtml(attribute_value)#">
									<a href="/agent/#related_agent_id#" class="external">#related_agent#</a>
								<cfelseif attribute_type is "login">
									<input type="hidden" name="attribute_value_#attribute_id#" if="attribute_value_#attribute_id#" value="#encodeforhtml(attribute_value)#">
									<a href="/AdminUsers.cfm?action=edit&username=#attribute_value#" class="external">#attribute_value#</a>
								<cfelse>
									<cfif attribute_type is "shipping" or attribute_type is "correspondence" or attribute_type is "formatted JSON">
										<cfset thisCls="shippingtextarea">
									<cfelseif attribute_type is "profile" or attribute_type is "remarks" or attribute_type is "curatorial remarks">
										<cfset thisCls="profiletextarea">
									<cfelse>
										<cfset thisCls="mediumtextarea">
									</cfif>
									<textarea class="#thisCls#" name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#">#attribute_value#</textarea>
									<cfif thisCls is "profiletextarea">
										<div class="markdownControls">
											<span class="mdToolBtn" onclick="mditalics('attribute_value_#attribute_id#');" title="ITALICIZE selected text">
												<i class="fa-solid fa-italic"></i>
											</span>
											<span class="mdToolBtn" onclick="mdbold('attribute_value_#attribute_id#');" title="BOLD selected text">
												<i class="fa-solid fa-bold"></i>
											</span>
											<span class="mdToolBtn" onclick="mdh1('attribute_value_#attribute_id#');" title="H1 selected text">
												H1
											</span>
											<span class="mdToolBtn" onclick="mdh2('attribute_value_#attribute_id#');" title="H2 selected text">
												H2
											</span>
											<span class="mdToolBtn" onclick="mdh3('attribute_value_#attribute_id#');" title="H3 selected text">
												H3
											</span>
											<span class="mdToolBtn" onclick="mdh4('attribute_value_#attribute_id#');" title="H4 selected text">
												H4
											</span>
											<span class="mdToolBtn" onclick="mdlink('attribute_value_#attribute_id#');" title="LINK selected text">
												<i class="fa-solid fa-link"></i>
											</span>
											<span class="helpLink" data-helplink="markdown_tools" title="Wats all this then?">
												<i class="fas fa-info"></i>
											</span>
										</div>
									</cfif>
									<cfif left(attribute_value,4) is 'http'>
										<a href="#attribute_value#" class="external"></a>
									</cfif>
								</cfif>
							</td>
							<td>
								<input type="datetime" value="#begin_date#" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="8" placeholder="begin" 		<cfif attribute_type is "login"> class="readClr" readonly </cfif> >
							</td>
							<td>
								<input type="datetime" value="#end_date#" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="8" placeholder="end">
							</td>
							<td>
								<input type="hidden" name="related_agent_id_#attribute_id#" id="related_agent_id_#attribute_id#" value="#related_agent_id#">
								<input type="text" value="#related_agent#" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
									onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
									onkeypress="return noenter(event);" placeholder="type+tab: related agent" 
									<cfif attribute_type is "login"> class="readClr" readonly <cfelse> class="pickInput" </cfif> >
								<cfif len(related_agent_id) gt 0>
									<a href="/agent/#related_agent_id#" class="external"></a>
								</cfif>
							</td>
							<td>
								<input type="datetime" value="#determined_date#" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="8" placeholder="date determined" <cfif attribute_type is "login"> class="readClr" readonly </cfif> >
							</td>
							<td>
								<input type="hidden" value="#attribute_determiner_id#" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#">
								<input type="text" value="#attribute_determiner#" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
									onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
									onkeypress="return noenter(event);" placeholder="type+tab: determiner" 
									<cfif attribute_type is "login"> class="readClr" readonly <cfelse> class="pickInput" </cfif> >
								<cfif len(attribute_determiner_id) gt 0>
									<a href="/agent/#attribute_determiner_id#" class="external"></a>
								</cfif>
							</td>
							<td>
								<textarea name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#" placeholder="method" <cfif attribute_type is "login"> class="smalltextarea readClr" readonly <cfelse> class="smalltextarea" </cfif> >#attribute_method#</textarea>
							</td>
							<td>
								<textarea class="smalltextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#" placeholder="remark">#attribute_remark#</textarea>
							</td>
							<td>
								<cfif len(created_by) gt 0 and created_by_agent_id neq 0>
									<div class="c_d_div">
										Created by <a href="/agent/#created_by_agent_id#" class="external">#created_by#</a> @ #created_timestamp#
									</div>
								</cfif>
							</td>
						</tr>
					</cfloop>
					<cfif purpose is 'relationship'>
						<cfloop query="reciprelns">
							<tr>
								<td>FROM: #attribute_type#</td>
								<td>( <a class="external" href="/agent/#agent_id#">#preferred_agent_name#</a> )</td>
								<td>#begin_date#</td>
								<td>#end_date#</td>
								<td>
									<a href="edit_agent.cfm?agent_id=#agent_id#" class="external">edit</a> #preferred_agent_name# 
								</td>
								<td>#determined_date#</td>
								<td>
									<cfif len(attribute_determiner) gt 0>
										#attribute_determiner# | <a class="external" href="/agent/#attribute_determiner_id#">info</a> | <a href="edit_agent.cfm?agent_id=#attribute_determiner_id#" class="external">edit</a></td>
									</cfif>
								<td>#attribute_method#</td>
								<td>#attribute_remark#</td>
								<td>
									<cfif len(reciprelns.created_by) gt 0 and reciprelns.created_by_agent_id neq 0>
										<div class="c_d_div">
											Created by <a href="/agent/#reciprelns.created_by_agent_id#" class="external">#reciprelns.created_by#</a> @ #reciprelns.created_timestamp#
										</div>
									</cfif>
								</td>
							</tr>
						</cfloop>
					</cfif>
				</cfloop>
			</table>
			<input type="hidden" name="current_ids" value="#current_ids#">
			<input type="submit" value="save" class="savBtn">
		</form>
		<cfinclude template="includes/_footer.cfm">
	</cfoutput>
</cfif>

<cfif action is "edit_agent_attribute">
	<cfoutput>
		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
		<cfset sobj=serializeJSON(form)>
		<cfinvoke component="/component/api/tools" method="manage_agent_attribute" returnvariable="x">
			<cfinvokeargument name="api_key" value="#api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="attrs" value="#sobj#">
		</cfinvoke>
		<cfif structkeyexists(x,"message") and x.message is 'success'>
			<cflocation url="edit_agent.cfm?agent_id=#agent_id#" addtoken="false">
		<cfelse>
			<cfset htdet="">
			<cfif structKeyExists(x, "dump")>
				<cfif structKeyExists(x.dump, "Message")>
					<cfset htdet=htdet & "<div>Message: " & SanitizeHtml(x.dump.Message) & "</div>">
				</cfif>
				<cfif structKeyExists(x.dump, "Sql")>
					<cfset htdet=htdet & "<div>SQL: " & SanitizeHtml(x.dump.Sql) & "</div>">
				</cfif>
			</cfif>
			<cfthrow message="#x.message#" detail="#htdet#" extendedInfo="#SanitizeHtml(serialize(x))#">
		</cfif>
	</cfoutput>
</cfif>