<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,6,0)#">
	select
		<!---- formatted date ---->
		TO_CHAR(NOW() :: DATE, 'Mon dd, yyyy') as prtdate, 
		flat.cat_num,
		<!---- text-overflow isn't supported at the moment to attempt to "pre-ellipse" 
		case when length(flat.scientific_name) > 28 
			then concat(substring(flat.scientific_name, 1, 25), '...')
			else flat.scientific_name 
		end as scientific_name,
		---->
		flat.scientific_name,
		<!---- pre-formap locality-including-geography information ---->
		concat_ws(', ',
		    flat.spec_locality,
  		    replace(flat.county,' County',' Co.'),
		    flat.state_prov,
		    case when flat.country='United States' then null else flat.country end
		) as locstr,
		<!---- manipulate a cached attribute ---->
		case when flat.sex='female' then 'F' when flat.sex='male' then 'M' when flat.sex='female ?' then 'F?' when flat.sex='male ?' then 'M?' when flat.sex='unknown' then 'U' else flat.sex end sex,
		case 
			when cn.n is not null then cn.n 
			when pn.n is not null then pn.n 
			when pl.n is not null then pl.n 
			else null 
		end as collectornumber,
		flat.verbatim_date as coll_date,
		<!---- call a function to format agents ---->
		getlabelname(flat.collection_object_id) as labels_agent_name,
		getMvzMammParts(flat.collection_object_id) as parts
	FROM
		flat
		inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
		<!---- join filteredd and aggregated identifiers ----->
		left outer join (
		    select collection_object_id, string_agg(display_value,', ') n from coll_obj_other_id_num where other_id_type='collector number' group by collection_object_id
		) cn on flat.collection_object_id=cn.collection_object_id
		left outer join (
		    select collection_object_id, string_agg(display_value,', ') n from coll_obj_other_id_num where other_id_type='preparator number' group by collection_object_id
		) pn on flat.collection_object_id=pn.collection_object_id
		left outer join (
		    select collection_object_id, string_agg(display_value,', ') n from coll_obj_other_id_num where issued_by_agent_id=21347703 group by collection_object_id
		) pl on flat.collection_object_id=pl.collection_object_id
	order by flat.scientific_name,flat.cat_num::numeric
</cfquery>
<!---- CSS could also be stored separately, I keep it inline because I copy and paste from my editor ---->
<style>
	<!----- this is a container for a single label ----->
	.cell {
		padding: 2px;
		width: 42mm;
		max-width:42mm;
		height: 33mm;
		page-break-inside: avoid;
		font-family: Ariel, sans-serif;
		font-size: 11px;
		overflow: hidden;
	}
	<!-------- try to prevent page breaking inside the table by nesting it in this div ---->
	.onePage{
		page-break-inside: avoid;
	}
	<!---- force a page break ---->
	.pageBreak{
		page-break-after: always;
	}
	<!---- make table borders skinny, we're using them for layout (like some kind of savage...) --->
	table {
		border-collapse: collapse;
	}
	<!---- CSS2.1 selectors are very limited, just give our "content TD" a class and set "cut here" borders with it ---->
	<!---- this gets processed inside of cfoutput tags, so we have to escape the hash. CSS in the CSS block is handled differently ---->
	.one_item_td{
		border: 1px dashed ##d3d3d3;
	}
	.header {
		text-align: center;
		letter-spacing: 1px;
		font-size: 0.8em;
	}

	<!-----
	this was for ellipsis approach
	.sn {
		font-style: italic;
		text-align: center;
		white-space: nowrap;
		overflow: hidden;
	}
	----->
	.sn {
		font-style: italic;
		text-align: center;
	}

	.cn {
		white-space: nowrap;
	}
	.sex {
		text-align:center;
		font-size:9px;
	}
	<!---- I would not mix setting font size by points and ems ---->
	.origno {
		font-size: 8pt;
		text-align: right;
	}
	<!---- I would not mix setting font size by points and ems ---->
	.dt {
		font-size: 0.8em;
	}

	<!----- indent wrapped text ---->
	.loc {
		height: 0.55in;
		font-size: 7pt;
		text-indent : -10px ;
		margin-left :  10px ;
	}

	.coll {
		font-size: 0.8em;
		text-align: right;
	}

	.parts {
		font-size: 0.8em;
		overflow: hidden;
		text-align: center;
		bottom: 0;
	}

</style>

<!--- set the layout, these need to work as multiple of class cell ---->
<cfset rowsPerPage=5>
<cfset columnsPerPage=6>

<!---- precalc, don't change these ---->
<cfset itemsPerPage=rowsPerPage * columnsPerPage>
<cfset numberOfPages=ceiling(d.recordcount / itemsPerPage)>
<cfset tblItemCt=0>
<cfset colItmCt=0>


<cfloop from="1" to="#d.recordcount#" index="i">
	<!---- grab a record; we'll need to reference this scope when we use things ---->
	<cfset r=d.getRow(i)>
	<cfif tblItemCt is 0>
		<!---- start a new table ---->
		<div class="onePage">
		<table class="layout_table">
	</cfif>
	<cfif colItmCt is 0>
		<!---- start a row --->
		<tr>
	</cfif>
	<!--- one item's table cell---->
	<td class="one_item_td">
		<!---- one item's div cell - this is the content, and the only thing that should usually change down here ---->
		<div class="cell">
			<div class="header"><u>UNIVERSITY OF CALIFORNIA</u></div>
			<table width="100%">
				<tr>
					<td><div class="cn">MVZ #r.cat_num#</div></td>
					<td><div class="sex">#r.sex#</div></td>
					<td><div class="origno">#r.collectornumber#</div></td>
				</tr>
			</table>
			<div class="sn">#r.scientific_name#</div>
			<div class="loc">#r.locstr#</div>
			<table width="100%">
				<tr>
					<td><div class="dt">#r.coll_date#</div></td>
					<td><div class="coll">#r.labels_agent_name#</div></td>
				</tr>
			</table>
			<div class="parts">#r.parts#</div>
		</div>
		<!---- END:: one item's div cell - this is the content, and the only thing that should usually change down here ---->
	</td>
	<cfset tblItemCt=tblItemCt+1>
	<cfset colItmCt=colItmCt+1>

	<cfif colItmCt is columnsPerPage or i is d.recordcount>
		<cfset colItmCt=0>
		</tr>
	</cfif>
	<cfif tblItemCt is itemsPerPage  or i is d.recordcount>
		<cfset tblItemCt=0>
		</table>
		</div><!---- stop onePage--->
		<!---- when paging, NOT when running out of data ---->
		<cfif tblItemCt is itemsPerPage>
			<div class="pageBreak"></div>
		</cfif>		
	</cfif>
</cfloop>