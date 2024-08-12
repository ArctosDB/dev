<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
	<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_id,guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfparam name="typ" default="">
	<cfif len(typ) is 0>
		bad call<cfabort>
	</cfif>
	<cfparam name="frm" default="">
	<cfif len(frm) is 0>
		bad call<cfabort>
	</cfif>
	<script>
		function convertFormToJSON(form) {
			return $(form)
		    .serializeArray()
		    .reduce(function (json, { name, value }) {
		      json[name] = value;
		      return json;
		    }, {});
		}
		function createTemplate(){
			var fid=$("#frm").val();
			//console.log(fid);
			var frmObj=parent.$("#" + fid);
			//console.log(frmObj);
			var jdat=convertFormToJSON(frmObj);
			//console.log('jdat');
			//console.log(jdat);
			const jstr = JSON.stringify(jdat);
			//console.log(jstr);
			$("#newval").val(jstr);
			$("#create_template").submit();

		}
		function use_template(id){
			var fid=$("#frm").val();
			//console.log('hola use_template');
			var sdata=$("#tempdstr_" + id).val();
			//console.log('sdata');
			//console.log(sdata);
			const jobj = JSON.parse(sdata);
			//console.log('jobj');
			//console.log(jobj);
			for (const [key, value] of Object.entries(jobj)) {
				//console.log(key + '---->' + value);
  				parent.$("#" + key).val(value);
			}
			if (fid=='newloan') {
				// if we're filling in a loan template, kick off the next number suggester once we're done
				parent.checkNextNum();
			}
			closeOverlay('collection_template');
		}
		function delete_template(id){
			if (confirm("Permanently delete this template?") == true) {
			  $("#delete_template_" + id).submit();
			}
		}
	</script>

	<cfoutput>
		<cfquery name="getMyCollectionTemplates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				guid_prefix,
				collection_template_id,
				template_type,
				template_name,
				template_data,
				UTCZtoISO8601(created_date) as created_date,
				getPreferredAgentName(created_agent_id) created_agent
			from 
				collection_templates
				inner join collection on collection_templates.collection_id=collection.collection_id
			where 
				template_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#typ#">
			order by
				guid_prefix,
				template_name
		</cfquery>
		<cfif getMyCollectionTemplates.recordcount is 0>
			<h3>No templates found</h3>
		<cfelse>
			<h3>Fill Form: Choose a Template</h3>
			<table border="1">
				<tr>
					<th>Collection</th>
					<th>Template</th>
					<th>Choose</th>
					<cfif listfind(session.roles,'manage_collection')>
						<th>Delete</th>
					</cfif>
					<th>Created</th>
				</tr>
				<cfloop query="#getMyCollectionTemplates#">
					<tr>
						<td>#guid_prefix#</td>
						<td>#template_name#</td>
						<td>
							<textarea style="display: none;" id="tempdstr_#collection_template_id#" >#template_data#</textarea>
							<input type="button" value="use" onclick="use_template('#collection_template_id#');" class="insBtn">
						</td>
						<cfif listfind(session.roles,'manage_collection')>
							<form name="delete_template_#collection_template_id#" id="delete_template_#collection_template_id#" method="post" action="collection_template.cfm">
								<input type="hidden" name="frm" value="#frm#">
								<input type="hidden" name="typ" value="#typ#">
								<input type="hidden" name="collection_template_id" value="#collection_template_id#">
								<input type="hidden" name="action" value="delete_template">
							</form>
							<td>
								<input type="button" value="delete" onclick="delete_template('#collection_template_id#');" class="delBtn">
							</td>
							<td>#created_agent# @ #created_date#</td>
						</cfif>
					</tr>
				</cfloop>
			</table>
		</cfif>
		<cfif listfind(session.roles,'manage_collection')>
			<h3>Save Form: Create Template</h3>
			<form name="create_template" id="create_template" method="post" action="collection_template.cfm">
				<input type="hidden" name="frm" id="frm" value="#frm#">
				<input type="hidden" name="typ" id="typ" value="#typ#">
				<input type="hidden" name="newval" id="newval" value="">
				<input type="hidden" name="action" value="maketemplate">
				To create a new template:
				<ol>
					<li>Fill out the form from which you opened this window. All fields are optional, enter only what you want to save in the template.</li>
					<li>Choose a collection (this controls access to the template).</li>
					<li>Provide a name (must be unique within the collection).</li>
					<li>Click create. The form will refresh, your template is saved and ready for use.</li>
				</ol>
				<label for="collection">Collection</label>
				<select name="collection_id" size="1" id="collection_id" class="reqdClr">
					<option value=""></option>
					<cfloop query="ctcollection">
						<option value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
					</cfloop>
				</select>
				<label for="template_name">Template Name</label>
				<input type="text" name="template_name" size="80" required class="reqdClr">
				<br><input type="button" value="create template" class="insBtn" onclick="createTemplate()">
			</form>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "delete_template">
	<cfoutput>
		<cfquery name="killCollectionTemplates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from collection_templates where collection_template_id=<cfqueryparam value="#collection_template_id#" cfsqltype="cf_sql_int">
		</cfquery>
    	<cflocation url="collection_template.cfm?frm=#frm#&typ=#typ#" addtoken="false">
    </cfoutput>
</cfif>

<cfif action is "maketemplate">
	<cfoutput>
		<cfquery name="createCollectionTemplates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into collection_templates (
				collection_id,
				template_type,
				template_data,
				template_name,
				created_date,
				created_agent_id
			) values (
				<cfqueryparam value="#collection_id#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#typ#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#newval#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#template_name#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#DateConvert('local2Utc',now())#" cfsqltype="cf_sql_timestamp">,
				<cfqueryparam value="#session.MyAgentId#" cfsqltype="cf_sql_int">
    		)
    	</cfquery>
    	<cflocation url="collection_template.cfm?frm=#frm#&typ=#typ#" addtoken="false">
	</cfoutput>
</cfif>