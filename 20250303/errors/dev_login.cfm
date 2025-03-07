
<cfinclude template="/includes/_header.cfm">
<cfoutput>
	<cfheader statuscode="401" statustext="Not authorized">
This is a development server. You may log in or create an account
for testing purposes. You may not access this machine without logging in.
Data available from this machine are for testing purposes only and are not
valid specimen data. Forms on this machine are under constant development; check GitHub for "active development" issues or contact us
for more information.

<p>
	<p>
		<div class="importantNotification">
			Arctos Users: You may <a href="/ChangePassword.cfm?action=lostPass">reset and recover your password</a> if you haven't been here recently.
		</div>
</p>


</p>
<p>
	<a href="http://arctos.database.museum">Go to Arctos</a>
</p>


</cfoutput>

<cfinclude template="/includes/_footer.cfm">