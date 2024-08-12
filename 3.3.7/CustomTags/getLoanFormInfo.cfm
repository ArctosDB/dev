<!----

this may be wholly redundant with /internal now???

----------->
<cfoutput>
	<!----
		over-ride the default of getting addresses only for active operators on this form
	---->
<cfset transaction_id=caller.transaction_id>
<cfquery name="caller.getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
      SELECT
		trans_date,
		concattransagent(trans.transaction_id, 'authorized by') authAgentName,
		concattransagent(trans.transaction_id, 'received by')   recAgentName,
		concattransagent(trans.transaction_id, 'outside contact')   outside_contact_name,
		concattransagent(trans.transaction_id, 'inside contact')   inside_contact_name,
		getAgentNameType(outside_contact.agent_id,'job title') outside_contact_title,
		getAgentNameType(inside_contact.agent_id,'job title') inside_contact_title,
		get_address(inside_contact.agent_id,'correspondence',0) inside_address,
		get_address(outside_contact.agent_id,'correspondence',0) outside_address,
		get_address(inside_contact.agent_id,'email',0) inside_email_address,
		get_address(outside_contact.agent_id,'email',0) outside_email_address,
		loan.return_due_date,
		trans.nature_of_material,
		trans.trans_remarks,
		loan.loan_instructions,
		loan.loan_description,
		loan.loan_type,
		loan.loan_number,
		loan.loan_status,
		shipment.shipped_date,
		case when  concattransagent(trans.transaction_id, 'received by') !=  concattransagent(trans.transaction_id, 'outside contact')  then
		concat('Attn: ',concattransagent(trans.transaction_id, 'outside contact') , '<br>', ship_to_addr.attribute_value)
		else
		ship_to_addr.attribute_value
		end  shipped_to_address,
		ship_from_addr.attribute_value  shipped_from_address,
		getPreferredAgentName(shipment.PACKED_BY_AGENT_ID) processed_by_name,
		getPreferredAgentName(project_sponsor.PROJECT_AGENT_ID) project_sponsor_name,
		PROJECT_AGENT_REMARKS acknowledgement
FROM
	loan
	inner join trans on loan.transaction_id = trans.transaction_id
	left outer join shipment on loan.transaction_id = shipment.transaction_id
	left outer join agent_attribute ship_to_addr on shipment.SHIPPED_TO_ADDR_ID = ship_to_addr.attribute_id
	left outer join agent_attribute ship_from_addr on shipment.SHIPPED_FROM_ADDR_ID = ship_from_addr.attribute_id
	left outer join trans_agent inside_contact on trans.transaction_id = inside_contact.transaction_id and inside_contact.trans_agent_role='in-house contact'
	left outer join trans_agent outside_contact on trans.transaction_id = outside_contact.transaction_id and outside_contact.trans_agent_role='outside contact'
	left outer join project_trans on trans.transaction_id = project_trans.transaction_id
	left outer join project_agent project_sponsor on project_trans.project_id =	project_sponsor.project_id and project_sponsor.project_agent_role='Sponsor'
WHERE
	loan.transaction_id=<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
group by
	trans_date,
	authAgentName,
	recAgentName,
	outside_contact_name,
	inside_contact_name,
	outside_contact_title,
	inside_contact_title,
	inside_address,
	outside_address,
	inside_email_address,
	outside_email_address,
	loan.return_due_date,
	trans.nature_of_material,
	trans.trans_remarks,
	loan.loan_instructions,
	loan.loan_description,
	loan.loan_type,
	loan.loan_number,
	loan.loan_status,
	shipment.shipped_date,
	shipped_to_address,
	shipped_from_address,
	processed_by_name,
	project_sponsor_name,
	acknowledgement
</cfquery>
</cfoutput>