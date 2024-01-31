<!--- putting this here because that's how my dev environment likes it, inline works equally well ----->
<style>
	/* div to hold catnums and header, might not be necessary at all */
	.catnum_outer_flex{
		border:1px solid purple;
	}
	/* container for catnums, which are in divs because we're looping the list */
.innner_catnum_list_flex{
	display: flex;
	flex-wrap: wrap;
	justify-content: space-between;

}

	/* div to hold catnums and header, might not be necessary at all */
	.catnum_outer_grid{
		border:1px solid purple;
	}
	/* container for catnums, which are in divs because we're looping the list */
.innner_catnum_list_grid{
	display: grid;
	/* million ways to do this, this one is maybe easy to read/understand/adjust and efficiency isn't important here */
	grid-template-columns: 1fr 1fr 1fr 1fr;
}


</style>
<!--- raw query --->
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		flat.family,
		flat.scientific_name,
		flat.country,
		flat.state_prov,
		flat.county,
		flat.spec_locality,
		flat.verbatim_date,
		flat.collectors,
		flat.guid_prefix,
		flat.cat_num
	FROM
		flat
		inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
</cfquery>


<!----
	Uncomment to dump out the raw query
	
	<cfdump var="#d#">
---->

<cfquery name="tmp" dbtype="query">
	select spec_locality as rtn from d group by spec_locality
</cfquery>

<cfif tmp.recordcount is 1>
	<cfset spec_locality=tmp.rtn>
<cfelse>
	<cfset spec_locality="">
</cfif>


<cfquery name="tmp" dbtype="query">
	select collectors as rtn from d group by collectors
</cfquery>

<cfif tmp.recordcount is 1>
	<cfset collectors=tmp.rtn>
<cfelse>
	<cfset collectors="">
</cfif>





<!--- just make unique sorted lists?? --->
<cfset tmp=valuelist(d.family)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset family=listSort(tmp,'text')>
<cfelse>
	<cfset family="">
</cfif>

<cfset tmp=valuelist(d.scientific_name)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset scientific_name=listSort(tmp,'text')>
<cfelse>
	<cfset scientific_name="">
</cfif>



<cfset tmp=valuelist(d.country)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset country=listSort(tmp,'text')>
<cfelse>
	<cfset country="">
</cfif>



<cfset tmp=valuelist(d.state_prov)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset state_prov=listSort(tmp,'text')>
<cfelse>
	<cfset state_prov="">
</cfif>

<cfset tmp=valuelist(d.county)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset county=listSort(tmp,'text')>
<cfelse>
	<cfset county="">
</cfif>



<cfset tmp=valuelist(d.verbatim_date)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset verbatim_date=listSort(tmp,'text')>
<cfelse>
	<cfset verbatim_date="">
</cfif>


<cfset tmp=valuelist(d.guid_prefix)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfif listLen(tmp) is 1>
	<cfset guid_prefix=listSort(tmp,'text')>
<cfelse>
	<cfset guid_prefix="">
</cfif>


<cfset tmp=valuelist(d.cat_num)>
<cfset tmp=listRemoveDuplicates(tmp)>
<cfset tmp=listChangeDelims(tmp,', ')>
<cfset cat_num=listSort(tmp,'numeric')>



<cfset q=querynew("
	family,
	scientific_name,
	country,
	state_prov,
	county,
	spec_locality,
	verbatim_date,
	collectors,
	guid_prefix,
	cat_num
")>



<cfset ocnl=cat_num>


<!---- Then I think we will need a limit on the cat numbers that fit on a single label, and have the rest printed on a second label. --->
<cfset numCatNumPerRow=35>


<!--- "loop to" should be as small as possible while still larger than the maximum possible number of 'pages' ---->
<cfloop from="1" to="100" index="lp">
	<cfif len(ocnl) is 0>
		<!---- done bye ---->
		<cfbreak>
	</cfif>
	<cfset thisCat="">
	<cfif listLen(ocnl) lte numCatNumPerRow>
		<!---- grab what's there and zero the list so we break on next loop ---->
		<cfset thisCat=ocnl>
		<cfset ocnl=''>
	<cfelse>
		<cfloop from="1" to="#numCatNumPerRow#" index="i">
			<cfif listLen(ocnl) gte 1>
				<cfset thisCat=listAppend(thisCat, listGetAt(ocnl, 1))>
				<cfset ocnl=listDeleteAt(ocnl, 1)>
			</cfif>
		</cfloop>
	</cfif>
	<!--- add what we just made ---->
	<cfset queryaddrow(q,{
		family=family,
		scientific_name=scientific_name,
		country=country,
		state_prov=state_prov,
		county=county,
		spec_locality=spec_locality,
		verbatim_date=verbatim_date,
		collectors=collectors,
		guid_prefix=guid_prefix,
		cat_num=thisCat
	})>
</cfloop>

<!----
	Uncomment to dump out the assembled query
	
	<cfdump var="#q#">
---->



<div class="wrapper">
	<cfloop query="q">
		<div class="cell">
			<div class="fam">#family#</div>
			<hr>
			<div class="sn">#scientific_name#</div>
			<hr>
			<div class="loc">
				<cfif len(country) gt 0>#country#: </cfif>#state_prov#: #county#; #spec_locality#
			</div>
			<div class="catnum_outer_flex">
				BYU:Herp:
				<div class="innner_catnum_list_flex">
					<cfloop list="#cat_num#" index="i">
						<div>#i#</div>
					</cfloop>
				</div>
			</div>
			<!------ repeat with fixed layout grid ----------->


			<div class="catnum_outer_grid">
				BYU:Herp:
<div class="innner_catnum_list_grid">
	<cfloop list="#cat_num#" index="i">
		<div>#i#</div>
	</cfloop>
</div>
			</div>


			<div class="twocol">
				<div class="crds"></div>
			<div>
			<div class="clrs"> </div>
			<div class="clrs">Coll: #collectors#</div>
			<div class="twocol"></div>
			<div class="twocol">
				<div class="attributes" </div>
			</div>
			<hr>
			<div class="footer">BYU LIFE SCIENCE MUSEUM - HERPETOLOGY</div>
			<hr>
			<div class="twocol">    
				<div class="dt">#verbatim_date#</div>
				<div class="notes">70% Ethanol</div>
			</div>
		</div>
	</cfloop>
</div>



