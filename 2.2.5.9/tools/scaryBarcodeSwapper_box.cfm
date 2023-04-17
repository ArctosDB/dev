Deprecated, use Barcode Swapper
<cfabort> 
<!----



drop table cf_temp_scaryswapper;


drop table cf_temp_scaryswapper;

CREATE TABLE cf_temp_scaryswapper (
	position  NUMBER NOT NULL,
	donor_barcode VARCHAR2(60) not null,
	receiving_label VARCHAR2(60) not null,
	box_barcode VARCHAR2(60) not null,
	donor_id number,
	tube_id number,
	position_id number,
	box_id number,
	status VARCHAR2(255)
);

create or replace public synonym cf_temp_scaryswapper for cf_temp_scaryswapper;
grant all on cf_temp_scaryswapper to manage_container;
---->

<cfinclude template="/includes/_header.cfm">


<cfset title="Scary Barcode Swapper">


<cfif action is "makeTemplate">
	<cfset thecolumns="position,donor_barcode,receiving_label,box_barcode">
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/scaryswapper.csv"
	    output = "#thecolumns#"
	    addNewLine = "no">
	<cflocation url="/download.cfm?file=scaryswapper.csv" addtoken="false">
</cfif>
<cfif action is "nothing">
	<p>
		Replace barcodes on all cryovials in positions in a freezer box.
	</p>
	<p>
		You should be very sure of what this form does before proceeding.
	</p>
	<table>
		<tr>
			<th>Column</th>
			<th>Wutsitdo?</th>
		</tr>
		<tr>
			<td>box_barcode</td>
			<td>Barcode of the freezer box which contains positions which contains cryovials with labels {receiving_label}</td>
		</tr>
		<tr>
			<td>position</td>
			<td>Position between {box_barcode} and  {receiving_label}.</td>
		</tr>
		<tr>
			<td>receiving_label</td>
			<td>Label of the cryovial which needs a barcode.</td>
		</tr>
		<tr>
			<td>donor_barcode</td>
			<td>Barcode of an unused %label container which will be assigned to {receiving_label}'s container. The original container will be deleted.</td>
		</tr>
	</table>
	<label for="atts">Upload CSV</label>
	<form name="atts" method="post" enctype="multipart/form-data" action="scaryBarcodeSwapper_box.cfm">
		<input type="hidden" name="action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>
</cfif>
<cfif action is "getFile">
<cfoutput>
	<cfquery name="flush" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_scaryswapper
	</cfquery>
	<cfinvoke component="/component/utilities" method="uploadToTable">
    	<cfinvokeargument name="tblname" value="cf_temp_scaryswapper">
	</cfinvoke>
	<cflocation url="scaryBarcodeSwapper_box.cfm?action=verify" addtoken="false">
</cfoutput>
</cfif>
<cfif action is "verify">
	<cfquery name="bx" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set box_id=(
			select container_id from container where container.container_type='freezer box' and container.barcode=cf_temp_scaryswapper.box_barcode
			)
	</cfquery>
	<cfquery name="bxv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='box_not_found' where box_id is null
	</cfquery>
<cfquery name="dnr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	  update cf_temp_scaryswapper set donor_id=(
	      select container_id from container where
	      container.barcode=cf_temp_scaryswapper.donor_barcode and
	      container.container_type like '% label' and
	      container.PARENT_CONTAINER_ID=0 and
	      not exists (select PARENT_CONTAINER_ID from container npc where container.PARENT_CONTAINER_ID=npc.container_id)
	    ) where status is null
	</cfquery>
	<!---- this didn't perform for above


		update cf_temp_scaryswapper set donor_id=(
			select container_id from container where container.barcode=cf_temp_scaryswapper.donor_barcode and
			container.container_type like '% label' and
			container.PARENT_CONTAINER_ID=0 and
			container.container_id not in (select PARENT_CONTAINER_ID from container)
		) where status is null


	---->


	<cfquery name="dnrv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='donor_not_found' where status is null and donor_id is null
	</cfquery>
	<cfquery name="dnrvd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='donor_duplicate' where status is null and donor_id in (
			select donor_id from cf_temp_scaryswapper group by donor_id  having count(*) > 1
		)
	</cfquery>


	<cfquery name="posn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set position_id=(
			select container_id from container where
				container.container_type='position' and
				container.LABEL=cf_temp_scaryswapper.position::text and
				container.parent_container_id=cf_temp_scaryswapper.box_id
			)
	</cfquery>
	<cfquery name="posnv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='position_not_found' where status is null and position_id is null
	</cfquery>



	<cfquery name="tb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set tube_id=(
			select container_id from container where
				container.container_type='cryovial' and
				container.LABEL=cf_temp_scaryswapper.receiving_label and
				container.parent_container_id=cf_temp_scaryswapper.position_id
			)
	</cfquery>
	<cfquery name="posnv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='tube_not_found' where status is null and tube_id is null
	</cfquery>
	<cfquery name="dnrvd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_scaryswapper set status='tube_duplicate' where status is null and tube_id in (
			select tube_id from cf_temp_scaryswapper group by tube_id  having count(*) > 1
		)
	</cfquery>

	<!--- what the everloving hell lucee chokes on "position" as a column header?!???!!!????????????????? ---->
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			position  as posn,
 donor_barcode,
 receiving_label,
 box_barcode ,
 donor_id     ,
 tube_id       ,
 position_id    ,
 box_id          ,
 status
		 from cf_temp_scaryswapper
	</cfquery>
	<cfquery name="ds" dbtype="query">
		select count(*) as c from d where status is not null
	</cfquery>
	<cfif ds.c gt 0>
		<p>
			fail; check data and reload
		</p>
	<cfelse>
		<p>
			Pass: Check everything one more time then <a href="scaryBarcodeSwapper_box.cfm?action=doit">click here to make the swaps</a>
		</p>
	</cfif>
	<cfoutput>
	<table border>
		<tr>
			<th>box_barcode</th>
			<th>position</th>
			<th>receiving_label</th>
			<th>donor_barcode</th>
			<th>status</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td>
					#box_barcode#
					<a target="_blank" href="/findContainer.cfm?container_id=#box_id#">[tree]</a>
					<a  target="_blank" href="/EditContainer.cfm?container_id=#box_id#">[edit]</a>
				</td>
				<td>
					#posn#
					<a  target="_blank" href="/findContainer.cfm?container_id=#position_id#">[tree]</a>
					<a  target="_blank" href="/EditContainer.cfm?container_id=#position_id#">[edit]</a>
				</td>
				<td>
					#receiving_label#
					<a  target="_blank" href="/findContainer.cfm?container_id=#tube_id#">[tree]</a>
					<a target="_blank"  href="/EditContainer.cfm?container_id=#tube_id#">[edit]</a>
				</td>
				<td>
					#donor_barcode#
					<a  target="_blank" href="/findContainer.cfm?container_id=#donor_id#">[tree]</a>
					<a  target="_blank" href="/EditContainer.cfm?container_id=#donor_id#">[edit]</a>
				</td>
				<td>#status#</td>
			</tr>
		</cfloop>
	</table>
	</cfoutput>
</cfif>
<cfif action is "doit">
	<cfoutput>

		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_scaryswapper
		</cfquery>
		<cfquery name="ds" dbtype="query">
			select count(*) c from d where status is not null
		</cfquery>
		<cfif ds.c gt 0>
			<p>
				fail; check data and reload
			</p>
			<cfabort>
		</cfif>
		<cftransaction>
			<cfloop query="d">
				<cfquery name="ddnr" datasource="uam_god">
					delete from container where container_id=#d.donor_id#
				</cfquery>
				<cfquery name="abc" datasource="uam_god">
					update container set barcode='#d.donor_barcode#' where container_id=#d.tube_id#
				</cfquery>
			</cfloop>
		</cftransaction>
		<p>
			Spiffy, all done.
		</p>
	</cfoutput>
</cfif>
