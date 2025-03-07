<!----
    https://github.com/ArctosDB/arctos/issues/8493#issuecomment-2628323770
    SQL sanitized, errors corrected, unused fields removed, no use case check

    Unable to complete request for malformed identifiers, pulling JSON for sorting in CFML

    More changes: https://github.com/ArctosDB/arctos/issues/8358#issuecomment-2683140144
        * if sampled_from_obj_id is not null then the part has a parent
        * dropped limit to 500 to accommodate cost incurred by container joins; results untested, could not locate loan with these data

---->
select 
    flat.guid, 
    flat.scientific_name, 
    case 
        when trim(flat.sex)='male' then 'male'
        when trim(flat.sex)='female' then 'female'
        else '?'
    end sex, 
    specimen_part.part_name as part,
    specimen_part.condition part_condition, 
    specimen_part.sampled_from_obj_id,
    concat_ws('. ', higher_geog, spec_locality) as locality, 
    loan.loan_number, 
    trans.trans_date,
    flat.identifiers::text identifiers,
    flat.verbatim_date,
    flat.identifiers,
    p1.barcode as part_barcode,
    p2.barcode as parent_barcode
from 
    loan_item
    inner join loan on loan.transaction_id = loan_item.transaction_id
    inner join trans on loan.transaction_id = trans.transaction_id 
    inner join specimen_part on loan_item.part_id = specimen_part.collection_object_id
    inner join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
    left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
    left outer join container pc on coll_obj_cont_hist.container_id=pc.container_id
    left outer join container p1 on pc.parent_container_id=p1.container_id
    left outer join container p2 on p1.parent_container_id=p2.container_id
WHERE 
    loan_item.transaction_id=<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
ORDER BY
    cat_num::int
limit 500




select 
    flat.guid, 
    flat.scientific_name, 
    p1.barcode as part_barcode,
    p2.barcode as parent_barcode
from 
    loan_item
    inner join loan on loan.transaction_id = loan_item.transaction_id
    inner join trans on loan.transaction_id = trans.transaction_id 
    inner join specimen_part on loan_item.part_id = specimen_part.collection_object_id
    inner join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
    left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
    left outer join container pc on coll_obj_cont_hist.container_id=pc.container_id
    left outer join container p1 on pc.parent_container_id=p1.container_id
    left outer join container p2 on p1.parent_container_id=p2.container_id
WHERE 
    loan_item.transaction_id=21136012
ORDER BY
    cat_num::int
limit 500



select 
    flat.guid, 
    flat.scientific_name, 
    p1.barcode as part_barcode,
    p2.barcode as parent_barcode,
    specimen_part.part_name as part,
    specimen_part.collection_object_id,
    coll_obj_cont_hist.collection_object_id, 
    p1.container_id,
    pc.container_id pcid
from 
    loan_item
    inner join loan on loan.transaction_id = loan_item.transaction_id
    inner join trans on loan.transaction_id = trans.transaction_id 
    inner join specimen_part on loan_item.part_id = specimen_part.collection_object_id
    inner join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
    left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
    left outer join container pc on coll_obj_cont_hist.container_id=pc.container_id
    left outer join container p1 on pc.parent_container_id=p1.container_id
    left outer join container p2 on p1.container_id=p2.parent_container_id
WHERE 
    loan_item.transaction_id=21136012--<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
ORDER BY
    cat_num::int
limit 500
