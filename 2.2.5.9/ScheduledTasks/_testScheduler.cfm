<cfmail to="dustymc@gmail.com,arctoslogs@mail.com" subject="scheduler test" from="scheduler_tester@#Application.fromEmail#" type="html">

<p>
now
</p>

<cfdump var=#now()#>
<p>
	Request
</p>
<cfdump var=#request#>


<p>
	Session
</p>
<cfdump var=#session#>


<p></p>
</cfmail>
