<cfinclude template="/includes/alwaysInclude.cfm">
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<script>
		$(document).ready(function() {
			$(document).on('click','#menu_toggle',function(){
		    	$("#nav_menu_content").toggle();
		    });
			var phlp=$("#thisPagePageHelp").val();
			//console.log(phlp);
			if (phlp!=null && phlp.length>0){
				var thisPgHlp='<a target="_blank" class="external" href="' + phlp + '">Page Help</a>';
				//console.log(thisPgHlp);
				$("#pageHelpLi").html(thisPgHlp).show();
			} else {
				$("#pageHelpLi").html('').hide();
			}
			$(document).on('click','#closeannouncement',function(){			
				$.ajax({
					url: "/component/functions.cfc",
					type: "POST",
					dataType: "json",
					data: {
						method:  "dismiss_announcement",
						returnformat : "json"
					}
				});	
				$("#arctos_header_announcement").remove();
			});
			$(document).on('click','#btn_agree_terms',function(){			
				$.ajax({
					url: "/component/functions.cfc",
					type: "POST",
					dataType: "json",
					data: {
						method:  "agree_terms",
						returnformat : "json"
					},
					success: function(r) {
						location.reload();
					}
				});	
			});	
		});
	</script>
</head>
<body>
	<div id="the_whole_header">
		<div id="nav_menu">
			<div id="arctos_logo">
				<a href="/"><img id="arctos_logo" src="/images/arctosandwords.png" alt="Arctos" border="0"></a>
			</div>
			<div id="nav_menu_hamburger">
				<span id="menu_toggle">&#9776;</span>
			</div>
			<div id="nav_menu_content">
				<div class="nav_menu_item hdr_dropdown">
					<div class="drop_menu_label">
						<div class="drop_menu_label_txt">
							<a target="_top" href="/search.cfm">Search</a> <i class="fa fa-caret-down"></i>
						</div>
						<div class="drop_list nav_menu_drop">
							<ul>
								<li><a target="_top" href="/agent.cfm">Agents</a></li>
								<li><a target="_top" href="/search.cfm">Catalog&nbsp;Records</a></li>
				                <li><a target="_top" href="/info/ctDocumentation.cfm">Code&nbsp;Tables</a></li>
								<li><a target="_top" href="/home.cfm">Collections</a></li>
				                <li><a target="_top" href="/MediaSearch.cfm">Media&nbsp;&&nbsp;Documents</a></li>
				                <li><a target="_top" href="/place.cfm">Places&nbsp;&&nbsp;Events</a></li>
								<li><a target="_top" href="/SpecimenUsage.cfm">Publications&nbsp;&&nbsp;Projects</a></li>
								<li><a target="_top" href="/random.cfm">Surprise&nbsp;Me!</a></li>
								<li><a target="_top" href="/taxonomy.cfm">Taxonomy</a></li>
								<li><a target="_top" href="/info/api.cfm">API</a></li>
							</ul>
						</div>
					</div>
				</div>
				<div class="nav_menu_item">
					<a href="/directory.cfm">Tools Directory</a>
				</div>
				<div class="nav_menu_item hdr_dropdown">
					<div class="drop_menu_label">
						<div class="drop_menu_label_txt">
							Join <i class="fa fa-caret-down"></i>
						</div>
						<div class="drop_list nav_menu_drop">
							<ul>
								<li>
									<a class="external" href="https://arctosdb.org/what-is-arctos/">What Arctos Values & Delivers</a>
								</li>
								<li>
									<a href="https://docs.google.com/forms/d/e/1FAIpQLSec0BuRKDGDjqxT1fRI31GbZc0TORLK6DoLjZReQfnl5iIyDA/viewform" target="_blank" class="external">
										Prospective Collection Request
									</a>
								</li>
								<li>
									<a target="_top" href="/info/mentor.cfm">Find a Mentor</a></li>
									<li><a class="external" href="https://handbook.arctosdb.org/how_to/new-collection.html##existing-institutions">Existing Institutions - New Portal Request</a>
								</li>
							</ul>
						</div>
					</div>
				</div>
				<div class="nav_menu_item hdr_dropdown">
					<div class="drop_menu_label">
						<div class="drop_menu_label_txt">
							Help <i class="fa fa-caret-down"></i>
						</div>
						<div class="drop_list nav_menu_drop rightdrop">
							<ul>
								<li><a href="https://arctosdb.org/acknowledgment-of-harmful-content" class="external">Acknowledgment of Harmful Content</a></li>
								<li><a target="_blank" class="external" href="http://arctosdb.org/">About</a></li>
								<li><a target="_blank" class="external" href="http://handbook.arctosdb.org/">Help</a></li>
								<li><a target="_blank" class="external" href="https://arctosdb.org/learn/webinars/">Webinars</a></li>
								<li><a target="_blank" class="external" href="https://arctosdb.org/learn/tutorial-blitz/">Tutorials</a></li>
								<li id="pageHelpLi" style="display: none;"></li>
							</ul>
						</div>
					</div>
				</div>
				<cfif isdefined("session.username") and len(session.username) gt 0>
					<div class="nav_menu_item hdr_dropdown">
						<div class="drop_menu_label">
							<div class="drop_menu_label_txt">
								<cfoutput>#session.username#</cfoutput> 
								<span id="sessExpMinNO" title="Minutes until session expiration."></span>
								<i class="fa fa-caret-down"></i>
							</div>
							<div class="drop_list nav_menu_drop rightdrop">
								<ul>
									<cfif listfindnocase(session.roles,'coldfusion_user')>
										<li><a target="_top" href="/Reports/notifications.cfm">Notifications</a></li>
										<li><a target="_top" href="/tools/async.cfm">Async Requests</a></li>
									</cfif>
									<li><a target="_top" href="/myArctos.cfm">Profile</a></li>
									<li><a target="_top" href="/saveSearch.cfm?action=manage">Saved Searches</a></li>
									<!----
									<li><a href="#" onclick="openLogin('signOut');">Sign Out</a></li>
									---->
									<li><div id="signoutbuttonitem">
										<a href="#" 
											onclick="openOverlay('/form/loginformguts.cfm?action=signOut','Log in, log out, create account, or recover password.');"
										>Sign Out</a>
										</div>
									</li>
									<li class="hdrNoclickTxt"><span id="sessExpMin"></span></li>
									<li class="hdrNoclickTxt">Last login: <cfoutput>#dateformat(session.last_login, "yyyy-mm-dd")#<input type="hidden" id="slcd"></cfoutput></li>
									<cfif isdefined("Application.version") and application.version is "test">
										<li class="hdrNoclickTxt"><cfoutput>#request.node_name# (TEST)</cfoutput></li>
									</cfif>
								</ul>
							</div>
						</div>
					</div>
				<cfelse>
					<div class="nav_menu_item">
						<!----
						<a href="#" onclick="openLogin();">Log In or Create Account</a>
						----->
						<a href="#" onclick="openOverlay('/form/loginformguts.cfm','Log in, log out, create account, or recover password.');">Log In or Create Account</a>
					</div>
				</cfif>
			</div><!---/nav_menu_content---->
		</div><!----/nav_menu---->
		<cfquery name="g_a_t" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select announcement_text from cf_global_settings where announcement_expires>=current_date
		</cfquery>
		<cfparam name="session.dismiss_announcement" default="false">
		<cfif len(g_a_t.announcement_text) gt 0 and session.dismiss_announcement is false>
			<div id="arctos_header_announcement">
				<div class="arctos_announcement_text">
					<cfoutput>#g_a_t.announcement_text#</cfoutput>
					<span id="closeannouncement">&times;</span>
				</div>
			</div>
		</cfif>
	</div><!---- the_whole_header ---->
	<cfset headerwasincluded=true>
	<cfinclude template="/includes/_headerChecks.cfm">

	<cfif isdefined("session.force_password_change")>
		<cfif session.force_password_change is "true">
			<p>
				<div class="importantNotification">
					You must change your password to use Arctos.
				</div>
			</p>
			<cfif GetTemplatePath() does not contain "/ChangePassword.cfm">
				<cflocation url="/ChangePassword.cfm" addtoken="false">
			</cfif>
		</cfif>
	</cfif>