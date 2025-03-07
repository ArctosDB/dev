<cfset title="Explore Arctos">
<cfinclude template="/includes/_header.cfm">

<cfquery name="links" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
			select * from browse order by random() limit 25
</cfquery>
<cfset hasAdm=false>
<style>
	.outercontainer {
		display: flex;
		flex-wrap: wrap;
  		align-items: center;
	}
	.oneitem{
		border:1px solid black; 
		margin:2em; 
		padding:2em;
		border-radius: 25px;
		background-color: var(--arctoslightblue);
		line-height: 1.5;
	}

</style>
<cfoutput>
	<div class="outercontainer">
		<div class="oneitem">
			<a href="/search.cfm?month=#datePart('m',now())#&day=#datePart('d',now())#">On This Day...</a>
		</div>
		<cfloop query="links">
			<div class="oneitem">
				<a href="#link#">#display#</a>
			</div>
		</cfloop>
	</div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
