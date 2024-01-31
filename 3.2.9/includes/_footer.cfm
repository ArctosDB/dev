<div id="arctosfooter">
	<div id="footerharmfulcontentdiv">
		<a href="https://arctosdb.org/acknowledgment-of-harmful-content" class="external">Acknowledgment of Harmful Content</a>
	</div>
	<div id="footerdonatediv">
		<a href="https://give.communityin.org/arctos-friends" class="external">Donate</a>
	</div>
	<div id="bussupt">
		<a class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">
			Report a bug or request support
		</a>
	</div>
	<div id="altcontact">
		<a class="external" href="https://arctosdb.org/contacts/">Alternate Contacts</a>
	</div>
	<div id="cistmnt">
		<a href="https://arctosdb.org" class="external">Arctos Consortium</a>
		is a fiscally sponsored project of 
		<a href="https://www.communityin.org/" class="external">Community Initiatives</a>, a US 501(c)(3) nonprofit organization.
	</div>
	<div id="footerlogo">
		<a href="/"><img id="arctosfooterlogo" src="/images/ArctosBluegl.svg" alt="Arctos" border="0" height="50px;"></a>
	</div>
</div>
<cfif isdefined("Application.version") and application.version is "test">
	<div id="google_translate_element"></div>
</cfif>
<script type="text/javascript" src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script> 
<script>
window.ga=window.ga||function(){(ga.q=ga.q||[]).push(arguments)};ga.l=+new Date;
ga('create', '<cfoutput>#Application.Google_uacct#</cfoutput>', 'auto');
ga('send', 'pageview');
function googleTranslateElementInit(){new google.translate.TranslateElement({pageLanguage: 'en'}, 'google_translate_element');}
</script>
<script async src='https://www.google-analytics.com/analytics.js'></script>
<cfif not isdefined("title")>
	<cfset title = "Database Access">
</cfif>
<cftry>
	<cfhtmlhead text='<title>#title#</title>'>
	<cfcatch></cfcatch>
</cftry>
</body>
</html>