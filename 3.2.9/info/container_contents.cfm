<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="container contents">
<cfparam name="getCSV" default="false">
<cfparam name="csvOnly" default="false">
<cfif csvOnly is true>
	<cfset getCSV=true>
</cfif>
<cfoutput>
	<cfset recLimit=20000>
	<p>
		Note: This form will return a maximum of #recLimit# records.
	</p>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,10,0)#">
		select
			c1.barcode bc1,
			c1.label lbl1,
			c1.container_type ct1,
			c1.container_id cid1,
			c2.barcode bc2,
			c2.label lbl2,
			c2.container_type ct2,
			c2.container_id cid2,
			c3.barcode bc3,
			c3.label lbl3,
			c3.container_type ct3,
			c3.container_id cid3,
			c4.barcode bc4,
			c4.label lbl4,
			c4.container_type ct4,
			c4.container_id cid4,
			c5.barcode bc5,
			c5.label lbl5,
			c5.container_type ct5,
			c5.container_id cid5,
			c6.barcode bc6,
			c6.label lbl6,
			c6.container_type ct6,
			c6.container_id cid6,
			c7.barcode bc7,
			c7.label lbl7,
			c7.container_type ct7,
			c7.container_id cid7
		from
			container c1
			left outer join container c2 on c1.container_id = c2.parent_container_id
			left outer join container c3 on c2.container_id = c3.parent_container_id
			left outer join container c4 on c3.container_id = c4.parent_container_id
			left outer join container c5 on c4.container_id = c5.parent_container_id
			left outer join container c6 on c5.container_id = c6.parent_container_id
			left outer join container c7 on c6.container_id = c7.parent_container_id
			where c1.container_id=<cfqueryparam CFSQLType="cf_sql_int" value="#container_id#">
		limit #recLimit#
	</cfquery>
	<cfif csvOnly is false>
		<cfquery name="root" dbtype="query" maxrows="1">
			select ct1,bc1,lbl1 from raw 
		</cfquery>
		<h3>Container Contents</h3>
		<br>Root (C1) container type: #root.ct1#
		<br>Root (C1) container barcode: #root.bc1#
		<br>Root (C1) container label: #root.lbl1#

		<cfquery name="lvl" dbtype="query">
			select 1 as level, ct1 as container_type,count(*) c,count(distinct(cid1)) uc from raw where cid1 is not null group by ct1
			union
			select 2 as level, ct2 as container_type,count(*) c,count(distinct(cid2)) uc from raw where cid2 is not null group by ct2
			union
			select 3 as level, ct3 as container_type,count(*) c,count(distinct(cid3)) uc from raw where cid3 is not null group by ct3
			union
			select 4 as level, ct4 as container_type,count(*) c,count(distinct(cid4)) uc from raw where cid4 is not null group by ct4
			union
			select 5 as level, ct5 as container_type,count(*) c,count(distinct(cid5)) uc from raw where cid5 is not null group by ct5
			union
			select 6 as level, ct6 as container_type,count(*) c,count(distinct(cid7)) uc from raw where cid6 is not null group by ct6
			union
			select 7 as level, ct7 as container_type,count(*) c,count(distinct(cid7)) uc from raw where cid7 is not null group by ct7
		</cfquery>
		<cfquery name="lvl_ord" dbtype="query">
			select * from lvl order by level, container_type
		</cfquery>

		<h4>Summary</h4>
		<div>Count is count of rows at level, Unique is count of unique containers at level.
		<table border>
			<tr>
				<th>Level</th>
				<th>ContainerType</th>
				<th>Count</th>
				<th>Unique</th>
			</tr>
			<cfloop query="lvl_ord">
				<tr>
					<td>#level#</td>
					<td>#container_type#</td>
					<td>#c#</td>
					<td>#uc#</td>
				</tr>
			</cfloop>
		</table>

		<br><a href="container_contents.cfm?getCSV=true&container_id=#container_id#"><input type="button" class="lnkBtn" value="CSV"></a>
		<p>NOTE: This form caches for up to 10 minutes and may be slightly out of date.</p>
		
		<table class="sortable" id="ctrtbl" border>
			<tr>
				<th>BC1</th>
				<th>LBL1</th>
				<th>T1</th>
				<th>CID1</th>
				<th>BC2</th>
				<th>LBL2</th>
				<th>T2</th>
				<th>CID2</th>
				<th>BC3</th>
				<th>LBL3</th>
				<th>T3</th>
				<th>CID3</th>
				<th>BC4</th>
				<th>LBL4</th>
				<th>T4</th>
				<th>CID4</th>
				<th>BC5</th>
				<th>LBL5</th>
				<th>T5</th>
				<th>CID5</th>
				<th>BC6</th>
				<th>LBL6</th>
				<th>T6</th>
				<th>CID6</th>
				<th>BC7</th>
				<th>LBL7</th>
				<th>T7</th>
				<th>CID7</th>
			</tr>
			<cfloop query="raw">
				<tr>
					<td>#bc1#</td>
					<td>#lbl1#</td>
					<td>#ct1#</td>
					<td><a href="/findContainer.cfm?container_id=#cid1#" class="external">#cid1#</a></td>
					<td>#bc2#</td>
					<td>#lbl2#</td>
					<td>#ct2#</td>
					<td>
						<cfif len(cid2) gt 0>
							<a href="/findContainer.cfm?container_id=#cid2#" class="external">#cid2#</a>
						</cfif>
					</td>
					<td>#bc3#</td>
					<td>#lbl3#</td>
					<td>#ct3#</td>
					<td>
						<cfif len(cid3) gt 0>
							<a href="/findContainer.cfm?container_id=#cid3#" class="external">#cid3#</a>
						</cfif>
					</td>
					<td>#bc4#</td>
					<td>#lbl4#</td>
					<td>#ct4#</td>
					<td>
						<cfif len(cid4) gt 0>
							<a href="/findContainer.cfm?container_id=#cid4#" class="external">#cid4#</a>
						</cfif>
					</td>
					<td>#bc5#</td>
					<td>#lbl5#</td>
					<td>#ct5#</td>
					<td>
						<cfif len(cid5) gt 0>
							<a href="/findContainer.cfm?container_id=#cid5#" class="external">#cid5#</a>
						</cfif>
					</td>
					<td>#bc6#</td>
					<td>#lbl6#</td>
					<td>#ct6#</td>
					<td>
						<cfif len(cid6) gt 0>
							<a href="/findContainer.cfm?container_id=#cid6#" class="external">#cid6#</a>
						</cfif>
					</td>
					<td>#bc7#</td>
					<td>#lbl7#</td>
					<td>#ct7#</td>
					<td>
						<cfif len(cid7) gt 0>
							<a href="/findContainer.cfm?container_id=#cid7#" class="external">#cid7#</a>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>

	<cfif getCSV is "true">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=raw.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/container_contents_download.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=container_contents_download.csv" addtoken="false">
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">