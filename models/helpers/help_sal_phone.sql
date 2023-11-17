/*
This model creates a special list of phone numbers that are grouped by service_at_location_id and then prioritized. Necessary to identify the primary phone number for each service_at_location.
*/
with sal as (
	select * from {{ ref('service_at_location') }}
),

-- Get all of the service phones...
sp as (
	select distinct
		sal.dbt_service_at_location_id,
        p.tenant_id,
		dbt_phone_id,
	    p.dbt_service_id,
	    null as dbt_location_id,
	    number,
	    extension,
	    type,
	    p.description
	from {{ ref('phone') }} p
	inner join sal on sal.dbt_service_id = p.dbt_service_id
        where sal.dbt_service_id is not null
),

-- and all of the location phones...
lp as (
	select distinct
		sal.dbt_service_at_location_id,
        p.tenant_id,
		dbt_phone_id,
	    null as dbt_service_id,
	    p.dbt_location_id,
	    number,
	    extension,
	    type,
	    p.description
	from {{ ref('phone') }} p
	inner join sal on sal.dbt_location_id = p.dbt_location_id
	    where sal.dbt_location_id is not null
),

-- combine them at the service_at_location level...
salp as (
	select * from sp
	union all
	select * from lp
),

-- and prioritize them by criteria provided by Lindsay Paulsen.
final as (
	select
		tenant_id,
		dbt_phone_id,
        dbt_service_id,
        dbt_location_id,
		dbt_service_at_location_id,
        number,
        extension,
        type,
        description,
		row_number () over (
			partition by dbt_service_at_location_id
				order by
					dbt_service_id,
					type != 'Hotline',
					type != 'Main',
					type != 'Toll-Free'
		) - 1 as priority
	from salp
	    where type != 'Fax'
	order by dbt_service_at_location_id
)

select * from final