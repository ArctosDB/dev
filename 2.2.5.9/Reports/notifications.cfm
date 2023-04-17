<cfinclude template="/includes/_header.cfm">
	<cfset title="notifications">
	<script src="/includes/sorttable.js"></script>
	<cfparam name="srch" default="">
	<cfparam name="srch_status" default="">
	<cfparam name="afterdate" default="">
	<cfparam name="beforedate" default="">
	<script>
		$(document).ready(function() {
			// allow shift-click to select multiple rows
		    var $chkboxes = $('input:checkbox');
		    var lastChecked = null;

		    $chkboxes.click(function(e) {
		        if (!lastChecked) {
		            lastChecked = this;
		            return;
		        }
		        if (e.shiftKey) {
		            var start = $chkboxes.index(this);
		            var end = $chkboxes.index(lastChecked);
		            $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
		        }
		        lastChecked = this;
		    });
		});
		function checkAll(){
		    $('input:checkbox').prop('checked', true);
		}
		function checkNone(){
		    $('input:checkbox').prop('checked', false);
		}
		function actionChange(v){
			$("#checked_action").val('');
			var isanythingchecked=false;
			const ids = [];
			$('input:checkbox').each(function () {
	       		var sThisVal = (this.checked ? $(this).val() : "");
	       		if (sThisVal){
	       			ids.push(sThisVal);
	       		}
	  		});
	  		if (ids.length==0){
	  			alert('Check boxes, then make a selection.')
				$("#checked_action").val('');
  				return false;
	  		}
	  		if (v=='delete'){
		  		if(!(confirm('Are you sure you want to delete ' + ids.length + ' notifications? This cannnot be undone.'))){
					return false;
				}
			}
			if (v=='blank'){
				v='';
			}
	  		var idlist=ids.join(',');
	  		$.ajax({
				url: "/component/functions.cfc",
				type: "post",
				dataType: "json",
				data: {
					method:  "setNotificationStatus",
					sts : v,
					nid : idlist,
					returnformat : "json"
				},
				success: function(r) {
					if ((!(r.STATUS)) || r.STATUS!='OK'){
						alert('An eror has occurred. Try reloading the page while holding shift.');
						return false;
					}
 					const ids = r.ID.split(','); 
					var v=r.STS;
					for (let i = 0; i < ids.length; i++) {
						if (v=='important'){
							$("#tr_" + ids[i]).removeClass().addClass('statusImportant');
							$("#notification_status_" + ids[i]).val('important');

						} else if ( v=='read') {
							$("#tr_" + ids[i]).removeClass().addClass('statusRead');
							$("#notification_status_" + ids[i]).val('read');
						} else if ( v=='delete') {
							$("#tr_" + ids[i]).remove();
						} else {
							$("#tr_" + ids[i]).removeClass();
							$("#notification_status_" + ids[i]).val('');
						}
					}
				},
					error: function (xhr, textStatus, errorThrown){
			    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
				}
			});
		}
		function setStatus(id,v){
			if (v=='important'){
				$("#tr_" + id).removeClass().addClass('statusImportant');
			} else if ( v=='read') {
				$("#tr_" + id).removeClass().addClass('statusRead');
			} else if ( v=='delete') {
				if(confirm('Are you sure you want to delete this notification? This cannnot be undone.')){
					// remove the row console.log('well bye');
					$("#tr_" + id).remove();
				}
			} else {
				$("#tr_" + id).removeClass();
			}

			$.ajax({
				url: "/component/functions.cfc",
				type: "GET",
				dataType: "html",
				data: {
					method:  "setNotificationStatus",
					sts : v,
					nid : id,
					returnformat : "json"
				},
				success: function(r) {
					//console.log(r);
				},
					error: function (xhr, textStatus, errorThrown){
			    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
				}
			});
		}
		function clearSearch(){
			$("#srch").val('');
			$("#srch_status").val('');
			$("#afterdate").val('');
			$("#beforedate").val('');
		}
		function updateSharedStatus(id){
			//console.log(id);
			var vid="shared_status_" + id;
			console.log(vid);

			var v=$("#shared_status_" + id).val();
			//console.log(v);
			$.ajax({
				url: "/component/functions.cfc",
				type: "GET",
				dataType: "html",
				data: {
					method:  "setNotificationSharedStatus",
					sts : v,
					nid : id,
					returnformat : "json"
				},
				success: function(r) {

					console.log(r);
					var result=JSON.parse(r);
					console.log(result);


					console.log(r.STATUS);
					if (result.STATUS=='OK'){
						$("#shared_status_" + id).addClass('goodSaveBG').removeClass('goodSaveBG',5000);
					} else {
						alert('An error has occurred, status was not saved.\n' + r);
					}
				},
					error: function (xhr, textStatus, errorThrown){
			    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
				}
			});
		}
	</script>
	<style>
		table { 
			border-collapse: collapse; 
		}
		.statusImportant{
			border: 2px solid red;
		}
		.statusRead{
			border: 1px solid gray;
			font-size: .9em;
			color:gray;
		}
		.notificationContentDiv{
			max-height: 20em;
			max-width: 80em;
			overflow: auto;
		}
		.notificationCCDiv{
			font-size: small;
			max-height: 10em;
			max-width: 20em;
			overflow: auto;

		}
		#inbox > tbody > tr:nth-child(odd) {
  			background-color: #f2f2f2;
		}
	</style>
	<cfoutput>
		<h3>Notifications</h3>
		<p>
			Notifications concerning data to which you have access are summarized here. Notifications are deleted after 90 days, unless marked important or having 'shared.'' A daily email will be attempted if there are unread notifications. The count on the notifications tab may be up to one hour out of date. Add (or remove) agent address type 'notification email' in your agent profile to receive (or stop) email notifications. 
		</p>
		<div style="border:2px solid green;margin:1em;padding: 1em;">
			<form method="get" action="notifications.cfm">
				<table>
					<tr>
						<td align="center">
							<label for="srch">Search Subject, Body, Shared</label>
							<input type="text" name="srch" id="srch" size="80" value="#srch#">
						</td>
						<td align="center">
							<label for="srch_status">Status</label>
							<select name="srch_status" id="srch_status">
								<option value="">anything</option>
								<option <cfif srch_status is "blank"> selected="selected" </cfif> value="blank">[ blank ]</option>
								<option <cfif srch_status is "important"> selected="selected" </cfif> value="important">important</option>
								<option <cfif srch_status is "read"> selected="selected" </cfif> value="read">read</option>
							</select>
						</td>
						<td  align="center"> 
							<label for="afterdate">On/After</label>
							<input type="datetime" name="afterdate" id="afterdate" value="#afterdate#">
						</td>
						<td align="center">
							<label for="beforedate">On/Before</label>
							<input type="datetime" name="beforedate" id="beforedate" value="#beforedate#">
						</td>
						<td align="center">
							<label for="">Search/Filter</label>
							<input type="submit" value="go">
						</td>
						<td align="center">
							<label for="">Clear Search</label>
							<input type="button" value="clear" onclick="clearSearch();">
						</td>
					</tr>
				</table>
			</form>
		</div>
		<cfquery name="user_notification" datasource="uam_god">
			select 
				notification.notification_id,
				notification.subject,
				replace(replace(notification.content,'<html>','[htmltag]'),'<title','[titletag]') as content,
				to_char(notification.generated_date,'yyyy-mm-dd/HH24:MI') as generated_date,
				notification.cc,
				notification.status shared_status,
				user_notification.status user_status
			from 
				notification 
				inner join user_notification on notification.notification_id=user_notification.notification_id
			where
				user_notification.username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
				<cfif len(srch) gt 0>
					and (
						content ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_VARCHAR"> or
						subject ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_VARCHAR"> or
						notification.status ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_VARCHAR"> 
					)
				</cfif>
				<cfif len(srch_status) gt 0>
					<cfif srch_status is "blank">
						and user_notification.status is null
					<cfelse>
						and user_notification.status = <cfqueryparam value="#srch_status#" CFSQLType="CF_SQL_VARCHAR">
					</cfif>
				</cfif>
				<cfif len(afterdate) gt 0>
					and generated_date >= <cfqueryparam value="#afterdate#" CFSQLType="CF_SQL_DATE">
				</cfif>
				<cfif len(beforedate) gt 0>
					and generated_date <= <cfqueryparam value="#beforedate#" CFSQLType="CF_SQL_DATE">
				</cfif>
			group by
				notification.notification_id,
				notification.subject,
				notification.content,
				notification.generated_date,
				notification.cc,
				notification.status,
				user_notification.status
			order by generated_date desc, subject,notification.notification_id
			limit 200
		</cfquery>
		<p>
			Found #user_notification.recordcount# noifications.<cfif user_notification.recordcount is 200> You have more notifications than this form can display at once. You may limit what's displayed by using the search pane at the top of the page.</cfif>
		</p>
		<form name="set_checked" id="set_checked">
			<input type="button" class="lnkBtn" onclick="checkNone()" value="Check None">
			<input type="button" class="lnkBtn" onclick="checkAll()" value="Check All">

			<select name="checked_action" id="checked_action" onchange="actionChange(this.value);">
				<option value="">For all checked records.....</option>
				<option value="read">mark read</option>
				<option value="blank">mark [ blank ]</option>
				<option value="important">mark important</option>
				<option value="delete">delete</option>
			</select>
			<span style="margin-left:20em;">
				<a href="notifications.cfm?getCSV=true"><input type="button" value="get all notifications as CSV"  class="lnkBtn"></a>
			</span>
			<table border class="sortable" id="inbox">
				<tr>
					<th>
						<input type="checkbox" onchange="changeAllCheck(this.value)">
					</th>
					<th>Status</th>
					<th>Date</th>
					<th>Subject</th>
					<th>Content</th>
					<th>Shared</th>
					<th>CC</th>
				</tr>
				<cfloop query="user_notification">
					<cfif user_status is "important">
						<cfset thisClass="statusImportant">
					<cfelseif user_status is "read">
						<cfset thisClass="statusRead">
					<cfelse>
						<cfset thisClass="">
					</cfif>
					<tr id="tr_#notification_id#" class="#thisClass#">
						<td valign="top">
							<input type="checkbox" name="notification_id" value="#notification_id#">
						</td>
						<td valign="top">
							<select name="notification_status" id="notification_status_#notification_id#" onchange="setStatus(#notification_id#,this.value);">
								<option <cfif user_status is ""> selected="selected" </cfif> value=""></option>
								<option <cfif user_status is "important"> selected="selected" </cfif> value="important">important</option>
								<option <cfif user_status is "read"> selected="selected" </cfif> value="read">read</option>
								<!----
								<option <cfif user_status is "unread"> selected="selected" </cfif> value="unread">unread</option>
								---->
								<option value="delete">delete</option>
							</select>
						</td>
						<td valign="top">#generated_date#</td>
						<td valign="top">#encodeforhtml(subject)#</td>
						<td valign="top">
							<div class="notificationContentDiv">
								#content#
							</div>
						</td>
						<td valign="top">
							<div class="sharedStatusDiv">
								<textarea 
									name="shared_status" 
									id="shared_status_#notification_id#" 
									class="addresstextarea">#shared_status#</textarea>
								<br><input type="button" class="savBtn" value="Save" onclick="updateSharedStatus(#notification_id#);">
							</div>
						</td>
						<td valign="top"><div class="notificationCCDiv">#listchangedelims(cc,', ')#</div></td>
					</tr>
				</cfloop>
			</table>
		</form>
		<cfif isdefined("getCSV") and getCSV is "true">
			<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					notification.notification_id,
					notification.subject,
					notification.content,
					to_char(notification.generated_date,'yyyy-mm-dd/HH24:MI') as generated_date,
					notification.cc,
					notification.status shared_status,
					user_notification.status user_status
				from 
					notification 
					inner join user_notification on notification.notification_id=user_notification.notification_id
				where
					user_notification.username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
				group by
					notification.notification_id,
					notification.subject,
					notification.content,
					notification.generated_date,
					notification.cc,
					notification.status,
					user_notification.status
				order by generated_date desc, subject,notification.notification_id
			</cfquery>
			<cfset flds=mine.columnlist>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
			<cfset thisDownloadName="#session.username#_notifications.csv">
			<cffile action = "write"
	    		file = "#Application.webDirectory#/download/#thisDownloadName#"
    			output = "#csv#"
    			addNewLine = "no">
			<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
			<cflocation url="notifications.cfm">

		</cfif>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">