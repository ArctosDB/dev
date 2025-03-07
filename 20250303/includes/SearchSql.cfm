<!----
	IMPORTANTE!

	This is the old code

	Keeping it around so things will keep working

	The code is now in specimenSearchQueryCode.cfm

	Pass off the expected table

---->

<cfset cacheTbleName=session.flatTableName>
<cfset qryUserName=session.dbuser>
<cfset qryUserPwd=decrypt(session.epw,session.sessionKey)>


<cfinclude template="/includes/specimenSearchQueryCode__param.cfm">
