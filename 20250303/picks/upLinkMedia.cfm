<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
<script type='text/javascript' language="javascript" src='/includes/dropzone.js'></script>
<link rel="stylesheet" href="/includes/dropzone.css" />

<script>
	jQuery(document).ready(function() {
		$("#c_made_date").datepicker();
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$(document).on('submit', '#nm', function(e){
	       $("#sbmtbd").html('<img src="/images/indicator.gif">');
	       $('#nm_sbmt').hide();
	    });
		Dropzone.options.mydz = {
			maxFiles: 1,
			init: function () {
				this.on("success", function (file,result) {
					//console.log(result);
					if (result.STATUSCODE=='200'){
						makeSaveForm(result);
					} else {
						try {
	   						var msg=result.MSG.replace(/\\n/g,'\n');
							alert('ERROR: ' + msg);
							this.removeAllFiles();
						} catch(err) {
						    alert('UNEXPECTED ERROR: ' + r);
							this.removeAllFiles();
						}
					}
				});
				this.on("maxfilesexceeded", function(file){
					this.removeFile(file);
				});
  			}
		};
	});

	function clearCreator(){
		$("#created_agent_id").val('');
		$("#creator").val('');
	}
	function clearDate(){
		$("#made_date").val('');
	}

	function resetDZ(){
		$("#uploadmediaform").show();
		$("#uploadtitle").html('');
		 Dropzone.forElement("#mydz").removeAllFiles();
		$("#newMediaUpBack").html('');
	}
	function makeSaveForm(result){
		var h='File Uploaded: Fill in this form and and click the "create" button to finish, or';
		h+=' <span class="likeLink" onclick="resetDZ();">click here to start over</span>';
	  	$("#uploadtitle").html(h);
	  	$("#uploadmediaform").hide();
	  	// prefetch these to avoid 'undefined' when there's not relationship/we're just loading
	  	var kvl;
	  	var ktp;
	  	if ($("#kval").length){
	  		kvl=$("#kval").val();
	  	}
	  	if ($("#ktype").length){
	  		ktp=$("#ktype").val();
	  	}
	  	var h='<form name="nm" id="nm" method="post" action="upLinkMedia.cfm">';
	  	h+='<input type="hidden" name="ktype"  value="' + ktp + '">';
	  	h+='<input type="hidden" name="kval"  value="' + kvl + '">';
	  	h+='<input type="hidden" name="action"  value="createNewMedia">';
	  	h+='<label for="media_uri">Media URI</label>';
	  	h+='<input type="text" name="media_uri" class="reqdClr" id="media_uri" size="80" value="' + result.MEDIA_URI + '">';
	  	h+='<a href="' + result.MEDIA_URI + '" target="_blank" class="external">open</a>';
	  	h+='<label for="preview_uri">Preview URI</label>';
	  	h+='<input type="text" name="preview_uri" id="preview_uri" size="80" value="' + result.PREVIEW_URI + '">';
	  	h+='<a href="' + result.PREVIEW_URI + '" target="_blank" class="external">open</a>';
	  	if (kvl.length){
		  	h+='<label for="media_relationship">Media Relationship</label>';
		  	h+='<select name="media_relationship" id="media_relationship" class="reqdClr"></select>';
	 	}
	  	h+='<label for="media_license_id">License</label>';
	  	h+='<select name="media_license_id" id="media_license_id"></select>';

	  	h+='<label for="media_terms_id">Terms</label>';
	  	h+='<select name="media_terms_id" id="media_terms_id"></select>';

		h+='<label for="mime_type">MIME Type</label>';
	    h+='<select name="mime_type" id="mime_type" class="reqdClr"></select>';
		h+='<label for="media_type">Media Type</label>';
	    h+='<select name="media_type" id="media_type" class="reqdClr"></select>';
	    h+='<label for="creator">Created By</label>';
	    h+='<input type="hidden" name="created_agent_id" id="created_agent_id">';
	    h+='<input type="text" name="creator" id="creator"';
		h+='onchange="pickAgentModal(\'created_agent_id\',this.id,this.value); return false;"';
		h+='onKeyPress="return noenter(event);" placeholder="pick creator" class="minput">';
		h+='<span class="infoLink" onclick="clearCreator();">clear</span>';
		h+='<label for="description">Description</label>';
	    h+='<input type="text" name="description" id="description" size="80">';
		h+='<label for="made_date">Made Date</label>';
	    h+='<input type="text" name="made_date" id="made_date">';
		h+='<span class="infoLink" onclick="clearDate();">clear</span>';
		h+='<label for="MD5_checksum">MD5 checksum</label>';
	    h+='<input type="text" name="MD5_checksum" id="MD5_checksum" size="80" value="' + result.MD5 + '">';
		h+='<img style="display:none" id="nm_sbmt" src="/images/indicator.gif"><div id="sbmtbd"><input type="submit" class="insBtn" id="nm_sbmt" value="create media"></div>';
		h+='</form>';
		$("#newMediaUpBack").html(h);
		$('#ctmedia_license').find('option').clone().appendTo('#media_license_id');

		$('#ctcollection_terms').find('option').clone().appendTo('#media_terms_id');
		$('#ctmime_type').find('option').clone().appendTo('#mime_type');
		$('#ctmedia_type').find('option').clone().appendTo('#media_type');
		$('#ctmedia_relationship').find('option').clone().appendTo('#media_relationship');
		$("#made_date").datepicker();
		$("#mime_type").val(result.MIME_TYPE);
		$("#media_type").val(result.MEDIA_TYPE);
		$("#created_agent_id").val($("#myAgentID").val());
		$("#creator").val($("#username").val());
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
	}
</script>

<cfoutput>
	<cfif ktype is "collecting_event_id">
		<cfset tbl='collecting_event'>
	<cfelseif ktype is "collection_object_id">
		<cfset tbl='cataloged_item'>
	<cfelseif ktype is "borrow_id">
		<cfset tbl='borrow'>
	<cfelseif ktype is "accn_id">
		<cfset tbl='accn'>
	<cfelseif ktype is "loan_id">
		<cfset tbl='loan'>
	<cfelseif ktype is "permit_id">
		<cfset tbl='permit'>
	<cfelseif ktype is "agent_id">
		<cfset tbl='agent'>
	<cfelseif ktype is "publication_id">
		<cfset tbl='publication'>
	<cfelseif ktype is "project_id">
		<cfset tbl='project'>
	<cfelse>
		<!--- allow upload without relationships; see code below before changing this ---->
		<cfset tbl=''>
		<cfset kval=''>
		<!--- these are normally in the form that's not included when we do this, so.... --->
		<input type="hidden" id="ktype" name="ktype" value="#ktype#">
		<input type="hidden" id="kval" name="kval" value="#kval#">
	</cfif>

	<cfquery name="ctmedia_license" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctmedia_license order by DISPLAY
	</cfquery>
	<cfquery name="ctcollection_terms" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_terms_id,display media_terms from ctcollection_terms order by display
	</cfquery>
	<cfquery name="ctmime_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctmime_type order by mime_type
	</cfquery>
	<cfquery name="ctmedia_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="CTMEDIA_LABEL" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from CTMEDIA_LABEL order by MEDIA_LABEL
	</cfquery>




	<!--- only get appropriate relationships

	 cachedwithin="#createtimespan(0,0,60,0)#"

	  ---->
	<cfquery name="ctmedia_relationship" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctmedia_relationship where media_relationship like
		'% #tbl#'
		order by media_relationship
	</cfquery>
	<div style="display:none">
		<!--- easy way to get stuff for new media - just clone from here ---->
		<select name="ctmedia_type" id="ctmedia_type">
			<option></option>
			<cfloop query="ctmedia_type">
				<option value="#media_type#">#media_type#</option>
			</cfloop>
		</select>
		<select name="ctmedia_license" id="ctmedia_license">
			<option></option>
			<cfloop query="ctmedia_license">
				<option value="#MEDIA_LICENSE_ID#">#DISPLAY#</option>
			</cfloop>
		</select>
		<select name="ctcollection_terms" id="ctcollection_terms">
			<option></option>
			<cfloop query="ctcollection_terms">
				<option value="#collection_terms_id#">#media_terms#</option>
			</cfloop>
		</select>


		<select name="ctmime_type" id="ctmime_type">
			<option></option>
			<cfloop query="ctmime_type">
				<option value="#mime_type#">#mime_type#</option>
			</cfloop>
		</select>
		<select name="ctmedia_relationship" id="ctmedia_relationship">
			<cfloop query="ctmedia_relationship">
				<option value="#media_relationship#">#media_relationship#</option>
			</cfloop>
		</select>
		<input type="hidden" id="myAgentID" value="#session.myAgentID#">
		<input type="hidden" id="username" value="#session.username#">
	</div>
	<div class="grpDiv">
		<div id="uploadtitle">Option 1: Upload Media</div>
				<!--- keep this as we're testing the S3 upload

				<div id="uploadmediaform">
					<form id="mydz" action="/component/utilities.cfc?method=loadFile&returnFormat=json" class="dropzone needsclick dz-clickable">
						<div class="dz-message needsclick">
							Drop ONE file here or click to upload.
						</div>
					</form>
				</div>
				--->
				<div id="uploadmediaform">
					<form id="mydz" action="/component/utilities.cfc?method=loadFileS3&returnFormat=json" class="dropzone needsclick dz-clickable">
						<div class="dz-message needsclick">
							Drop ONE file here or click to upload (s3).
						</div>
						<!----
						<select name="nothumb" id="nothumb">
							<option value="false">generate a thumbnail if possible</option>
							<option value="true">DO NOT generate a thumbnail</option>
						</select>
						---->
					</form>
				</div>

		<!----
			<form id="form1" enctype="multipart/form-data" method="post" action="">
				<div class="drop-files-container">
				<label for="fileToUpload">Select a File to Upload (click or drag a file onto the browse button)</label>
				<input type="file" name="fileToUpload" id="fileToUpload" onchange="fileSelected();"/>
				</div>
				<div id="fileName"></div>
				<div id="fileSize"></div>
				<div id="fileType"></div>
				<div class="row">
				<input type="button" onclick="uploadFile()" value="Upload" id="btnUpload">
				<div id="progressThingee" style="display:none;"><img src="/images/indicator.gif"></div>
				</div>
				<div id="progressNumber"></div>
			</form>
			---->
		</div>
		<div id="newMediaUpBack"></div>
	</div>

	<div class="grpDiv">
			Option 2: Create Media from URL.
			<form id="picklink" method="post" action="upLinkMedia.cfm">
				<input type="hidden" name="action" value="createFromURLpicked">
				<input type="hidden" id="ktype" name="ktype" value="#ktype#">
				<input type="hidden" id="kval" name="kval" value="#kval#">
				<label for="">URL</label>
				<input type="text" class="reqdClr" name="c_media_URL" id="c_media_URL" size="60">
				<label for="">Preview URL</label>
				<input type="text" name="c_preview_URL" id="c_preview_URL" size="60">
				<label for="c_media_type">Media Type</label>
				<select name="c_media_type" id="c_media_type" class="reqdClr">
					<option></option>
					<cfloop query="ctmedia_type">
						<option value="#media_type#">#media_type#</option>
					</cfloop>
				</select>

				<label for="c_mime_type">Mime Type</label>
				<select name="c_mime_type" id="c_mime_type" class="reqdClr">
					<option></option>
					<cfloop query="ctmime_type">
						<option value="#mime_type#">#mime_type#</option>
					</cfloop>
				</select>


				<label for="c_license">License</label>
				<select name="c_license" id="c_license">
					<option></option>
					<cfloop query="ctmedia_license">
						<option value="#MEDIA_LICENSE_ID#">#DISPLAY#</option>
					</cfloop>
				</select>

				<label for="c_terms">Terms</label>
				<select name="c_terms" id="c_terms">
					<option></option>
					<cfloop query="ctcollection_terms">
						<option value="#collection_terms_id#">#media_terms#</option>
					</cfloop>
				</select>




				<label for="c_media_relationship">Relationship</label>
				<select name="c_media_relationship" id="c_media_relationship">
					<cfloop query="ctmedia_relationship">
						<option value="#media_relationship#">#media_relationship#</option>
					</cfloop>
				</select>




				<label for="c_created_by">Created By Agent</label>
				<input type="hidden" name="c_created_by_aid" id="c_created_by_aid" value="">
				<input type="text" name="c_created_by" id="c_created_by" value=""
					onchange="pickAgentModal('c_created_by_aid',this.id,this.value); return false;"
					onKeyPress="return noenter(event);" placeholder="pick Creator" class="minput">


				<label for="c_description">Description</label>
				<input type="text" size="60" id="c_description" name="c_description">


				<label for="c_made_date">Made Date</label>
				<input type="text" size="40" id="c_made_date" name="c_made_date">


				<br><input type="submit" class="insBtn" value="Create Media">
			</form>
		</div>



	<cfif len(kval) gt 0>
		<!--- don't include this with the 'just upload' option --->
		<div class="grpDiv">
			Option 3: Link to existing Arctos Media.
			<span class="likeLink" onclick="findMedia('p_media_uri','p_media_id');">Click here to pick</span> or enter Media ID and save.
			<form id="picklink" method="post" action="upLinkMedia.cfm">
				<input type="hidden" name="action" value="linkpicked">
				<input type="hidden" id="ktype" name="ktype" value="#ktype#">
				<input type="hidden" id="kval" name="kval" value="#kval#">
				<label for="">Media ID</label>
				<input type="number" class="reqdClr" name="p_media_id" id="p_media_id">
				<label for="p_media_uri">Picked MediaURI</label>
				<input type="text" size="80" name="p_media_uri" id="p_media_uri" class="readClr">
				<label for="media_relationship">Relationship</label>
				<select name="media_relationship" id="media_relationship">
				<cfloop query="ctmedia_relationship">
					<option value="#media_relationship#">#media_relationship#</option>
				</cfloop>
			</select>
				<br><input type="submit" class="insBtn" value="link to picked media">
			</form>
		</div>
	</cfif>
	<cfif len(tbl) gt 0>
		Existing Media for this object
		<cfquery name="smed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct
				media_flat.media_id,
				media_flat.MEDIA_URI,
				media_flat.MIME_TYPE,
				media_flat.MEDIA_TYPE,
				media_flat.PREVIEW_URI,
				media_flat.MEDIA_URI,
				media_flat.thumbnail,
				media_flat.license,
				media_flat.terms,
				media_flat.relationships,
				media_flat.labels
			from
				media_relations
				inner join media_flat on media_relations.media_id=media_flat.media_id
			where
				media_relations.media_relationship like <cfqueryparam value="% #tbl#" cfsqltype="cf_sql_varchar"> and
				media_relations.related_primary_key=<cfqueryparam value="#kval#" cfsqltype="cf_sql_int">
			order by
				media_id
		</cfquery>
		<style>
			.tbl{
				display: table;
				width:80%;
				border:1px solid black;
				margin:1em;
				padding:1em;}
			.tr{display: table-row;}
			.td-left{
				display: table-cell;
				width:30%;
				vertical-align: middle;
			}
			.td-right{
				display: table-cell;
				width:68%;
				vertical-align: middle;
				padding:0 0 0 1em;
			}
			.grpDiv {
				padding:1em;
				margin:1em;
				border:1px solid black;
			}
		</style>
		<cfloop query="smed">
			<div class="tbl">
				<div class="tr">
					<div class="td-left">
						<a target="_blank" href="#MEDIA_URI#"><img src="#thumbnail#" style="max-width:150px;max-height:150px;"></a>
						<a target="_blank" href="/media.cfm?action=edit&media_id=#media_id#">Edit Media</a>
						<cfif len(license) gt 0>
							#license#
						</cfif>
						<cfif len(terms) gt 0>
							<br>#terms#
						</cfif>
					</div>
					<div class="td-right">
						<div style="font-size:small">
							<cfif isJSON(relationships)>
					            <cfset trels=deSerializeJSON(relationships)>
					        <cfelse>
					            <cfset trels="">
					        </cfif>
				
							<cfif IsArray(trels)>
								<cfloop from="1" to='#arrayLen(trels)#' index="ix">
									<br>#trels[ix]["rln"]# <a class="external" href="#trels[ix]["lnk"]#">#trels[ix]["dsp"]#</a>
								</cfloop>
							</cfif>
							<cfif isJSON(labels)>
					            <cfset tlbls=deSerializeJSON(labels)>
					        <cfelse>
					            <cfset tlbls="">
					        </cfif>

							<cfif IsArray(tlbls)>
								<cfloop from="1" to='#arrayLen(tlbls)#' index="ix">
									<br>#tlbls[ix]["l"]#: #tlbls[ix]["lv"]#
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>
			</div>
		</cfloop>
	<cfelse>
			<div class="importantNotification">
				You are creating Media with no relationships. You will need to Edit Media and add relationships
				after uploading. This process may be easier from the data object (agent, specimen, etc.) to which
				you are adding Media. File an Issue if that is not currently an option.
			</div>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "linkpicked">
	<cfoutput>
		<cfquery name="linkpicked" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into media_relations (
				MEDIA_ID,
				MEDIA_RELATIONSHIP,
				CREATED_BY_AGENT_ID,
				RELATED_PRIMARY_KEY
			) values (
				#p_media_id#,
				'#media_relationship#',
				#session.myAgentId#,
				#kval#
			)
		</cfquery>
		<cflocation url="upLinkMedia.cfm?kval=#kval#&ktype=#ktype#" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "createNewMedia">
	<cfoutput>
		<cftransaction>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_media_id') mid
			</cfquery>
			<cfquery name="newmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into media (
					MEDIA_ID,
					MEDIA_URI,
					MIME_TYPE,
					MEDIA_TYPE,
					PREVIEW_URI,
					MEDIA_LICENSE_ID,
					media_terms_id
				) values (
					<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int" null="#Not Len(Trim(mid.mid))#">,
					<cfqueryparam value="#media_uri#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(media_uri))#">,
					<cfqueryparam value="#mime_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(mime_type))#">,
					<cfqueryparam value="#MEDIA_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(MEDIA_TYPE))#">,
					<cfqueryparam value="#PREVIEW_URI#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PREVIEW_URI))#">,
					<cfqueryparam value="#media_license_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(media_license_id))#">,
					<cfqueryparam value="#media_terms_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(media_terms_id))#">
				)
			</cfquery>
			<!--- allow a just-make-media option --->
			<cfif len(kval) gt 0>
				<cfquery name="linkpicked" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_relations (
						MEDIA_ID,
						MEDIA_RELATIONSHIP,
						CREATED_BY_AGENT_ID,
						RELATED_PRIMARY_KEY
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#media_relationship#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#kval#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(created_agent_id) gt 0>
				<cfquery name="created_agent_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_relations (
						MEDIA_ID,
						MEDIA_RELATIONSHIP,
						CREATED_BY_AGENT_ID,
						RELATED_PRIMARY_KEY
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="created by agent" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#created_agent_id#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(description) gt 0>
				<cfquery name="description" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_labels (
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="description" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#description#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(MD5_checksum) gt 0>
				<cfquery name="MD5_checksum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_labels (
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="MD5 checksum" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#MD5_checksum#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(made_date) gt 0>
				<cfquery name="made_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_labels (
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="made date" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#made_date#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
		</cftransaction>
		<cfif len(kval) is 0>
			Media ID #mid.mid# created. <a target="_parent" href="/media.cfm?action=edit&media_id=#mid.mid#">Click here to edit Media</a>
		<cfelse>
			<cflocation url="upLinkMedia.cfm?ktype=#ktype#&kval=#kval#&" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>




<cfif action is "createFromURLpicked">
	<cfoutput>
		<!----
			see:
				https://github.com/ArctosDB/arctos/issues/3307
				https://github.com/ArctosDB/arctos/issues/3052

			isValid('url',''' is hopelessly broken

			we also need to handle URIs

			just take anything, I guess??

		<cfif not isvalid('URL',c_media_URL)>
			Not a valid URL<cfabort>
		</cfif>
		<cfif len(c_preview_URL) gt 0 and not isvalid('URL',c_preview_URL)>
			Not a valid preview URL<cfabort>
		</cfif>
		---->

		<cftransaction>
			<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_media_id') mid
			</cfquery>
			<cfquery name="newmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into media (
					MEDIA_ID,
					MEDIA_URI,
					MIME_TYPE,
					MEDIA_TYPE,
					PREVIEW_URI,
					MEDIA_LICENSE_ID,
					media_terms_id
				) values (
					<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#c_media_URL#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_media_URL))#">,
					<cfqueryparam value="#c_mime_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_mime_type))#">,
					<cfqueryparam value="#c_media_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_media_type))#">,
					<cfqueryparam value="#c_preview_URL#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_preview_URL))#">,
					<cfqueryparam value="#c_license#" CFSQLType="cf_sql_int" null="#Not Len(Trim(c_license))#">,
					<cfqueryparam value="#c_terms#" CFSQLType="cf_sql_int" null="#Not Len(Trim(c_terms))#">
				)
			</cfquery>
			<!--- allow a just-make-media option --->
			<cfif len(kval) gt 0>
				<cfquery name="linkpicked" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_relations (
						MEDIA_ID,
						MEDIA_RELATIONSHIP,
						CREATED_BY_AGENT_ID,
						RELATED_PRIMARY_KEY
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#c_media_relationship#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_media_relationship))#">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#kval#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(c_created_by_aid) gt 0>
				<cfquery name="created_agent_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_relations (
						MEDIA_ID,
						MEDIA_RELATIONSHIP,
						CREATED_BY_AGENT_ID,
						RELATED_PRIMARY_KEY
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="created by agent" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#c_created_by_aid#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(c_description) gt 0>
				<cfquery name="description" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_labels (
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="description" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#c_description#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfif len(c_made_date) gt 0>
				<cfquery name="made_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_labels (
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						<cfqueryparam value="#mid.mid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="made date" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#c_made_date#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
		</cftransaction>

		<cfif len(kval) is 0>
			Media ID #mid.mid# created. <a target="_parent" href="/media.cfm?action=edit&media_id=#mid.mid#">Click here to edit Media</a>
		<cfelse>
			<cflocation url="upLinkMedia.cfm?ktype=#ktype#&kval=#kval#&" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>

<cfinclude template="/includes/_pickFooter.cfm">