<cfif not isdefined("container_id")>
	<cfabort><!--- need an ID to do anything --->
</cfif>
<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	SELECT
		flat.collection_object_id,
		container.container_id,
		container_type,
		label,
		description,
		container_remarks,
		container.barcode,
		part_name,
		guid,
		scientific_name,
		concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		container.last_date,
		container.WIDTH,
		container.HEIGHT,
		container.length,
		container.INSTITUTION_ACRONYM,
		container.NUMBER_ROWS,
		NUMBER_COLUMNS,
		ORIENTATION,
		POSITIONS_HOLD_CONTAINER_TYPE
	FROM
		container
		left outer join coll_obj_cont_hist on container.container_id = coll_obj_cont_hist.container_id
		left outer join specimen_part on coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id
		left outer join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
		WHERE container.container_id=#container_id#
</cfquery>


<h2>Container Details</h2>
<cfoutput>
	<div>
		<div>Container Type: #detail.container_type#</div>

		<cfif len(detail.barcode) gt 0>
			<div>Barcode: #detail.barcode#</div>
		</cfif>
		<cfif detail.barcode neq detail.label>
			<div style="color:red;">Label: #detail.label#</div>
		<cfelse>
			<div>Label: #detail.label#</div>
		</cfif>
		<cfif len(detail.description) gt 0>
			<div>Description: #detail.description#</div>
		</cfif>
		<cfif len(detail.container_remarks) gt 0>
			<div>Remarks: #detail.container_remarks#</div>
		</cfif>
		<cfif len(detail.last_date) gt 0>
			<div>LastDate: #dateformat(detail.last_date,"yyyy-mm-dd")#T#timeformat(detail.last_date,"hh:mm:ss")#</div>
		</cfif>
		<cfif len(detail.WIDTH) gt 0 OR len(detail.HEIGHT) gt 0 OR len(detail.length) gt 0>
		  <div>Dimensions (W x H x D): #detail.WIDTH# x #detail.HEIGHT# x #detail.length# CM</div>
		</cfif>

		<cfif len(detail.INSTITUTION_ACRONYM) gt 0>
		  <div>Institution: #detail.INSTITUTION_ACRONYM#</div>
		</cfif>
		<cfif len(detail.POSITIONS_HOLD_CONTAINER_TYPE) gt 0>
		  <div>Position Layout: #detail.NUMBER_ROWS# rows, #detail.NUMBER_COLUMNS# columns, #detail.ORIENTATION#, holds #detail.POSITIONS_HOLD_CONTAINER_TYPE#</div>
		</cfif>
		<cfif len(detail.part_name) gt 0>
			<div>
				Part: <a href="/guid/#detail.guid#" target="_blank" class="external">#detail.guid#</a>
				<em>#detail.scientific_name#</em> #detail.part_name#
				<cfif len(detail.CustomID) gt 0>
					(#session.CustomOtherIdentifier#: #detail.CustomID#)
				</cfif>
			</div>
		</cfif>
		<div>
			<a href="EditContainer.cfm?container_id=#container_id#" class="external" target="_blank">Edit this container</a>
		</div>
		<div>
			<a href="allContainerLeafNodes.cfm?container_id=#container_id#" class="external" target="_blank">
				See all collection objects in this container
			</a>
		</div>
		<div>
			<a href="/info/container_contents.cfm?container_id=#container_id#" class="external" target="_blank">
				Container Contents
			</a><a href="/info/container_contents.cfm?container_id=#container_id#&csvOnly=true" class="external" target="_blank">
				(CSV only)
			</a>
		</div>
		<div>
			<a href="/containerPositions.cfm?container_id=#container_id#" class="external" target="_blank">Positions</a>
		</div>
		<div>
			<a href="/findEmptyFBP.cfm?container_id=#container_id#" class="external" target="_blank">Empty Positions</a>
		</div>
		<div>
			<input type="button" class="lnkBtn" onclick="openOverlay('/info/ContHistory.cfm?container_id=#container_id#','Container History');" value="History">
		</div>
		<cfquery name="posn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			WITH RECURSIVE subordinates AS (
			   SELECT
			      container_id,
			      getLastContainerEnvironment(CONTAINER_ID) lastenv,
			      parent_container_id,
			      label,
			      container_type,
			      DESCRIPTION,
			      last_date,
			      barcode,
			      CONTAINER_REMARKS,
			      0 lvl
			   FROM
			      container
			   WHERE
			      container_id=<cfqueryparam CFSQLType="cf_sql_int" value="#container_id#">
			   UNION
			      SELECT
			         e.container_id,
			         getLastContainerEnvironment(e.CONTAINER_ID) lastenv,
			         e.parent_container_id,
			         e.label,
			        e.container_type,
			        e.DESCRIPTION,
			        e.last_date,
			        e.barcode,
			        e.CONTAINER_REMARKS,
			         s.lvl +1
			      FROM
			         container e
			      INNER JOIN subordinates s ON s.parent_container_id  = e.container_id
			) SELECT
			   *
			FROM
			   subordinates
			   order by lvl desc
			   limit 10
		</cfquery>
		<div>
			Location:
			<cfset indent=0>
			<cfloop query="posn">
				<cfset indent=indent+.5>
				<div style="margin-left: #indent#em; border:1px lightgray dotted;">
					<span class="likeLink" onclick="checkHandler(#container_id#)">#label#</span>
					<div style="margin-left:.4em;font-size:smaller;">
						<div>Container Type: #CONTAINER_TYPE#</div>
						<cfif len(barcode) gt 0>
							<cfif barcode neq label>
								<div style="color:red;">Barcode: #barcode#</div>
							<cfelse>
								<div>Barcode: #barcode#</div>
							</cfif>
						</cfif>
						<cfif len(lastenv) gt 0>
							<div>Last Envo: #lastenv#</div>
						</cfif>
					</div>
				</div>
			</cfloop>
		</div>
	</div>
</cfoutput>