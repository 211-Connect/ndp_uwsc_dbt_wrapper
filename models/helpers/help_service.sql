with service as (
    select
        dbt_service_id,
        tenant_id,
        dbt_organization_id,
        name,
        description,
        fees_description,
        email,
        url
    from {{ ref('service') }}
),

phone_w_multiple_services as (
    select
        dbt_service_id,
        number,
        ROW_NUMBER() OVER (PARTITION BY dbt_service_id ORDER BY number) as rn 
    from {{ ref('phone') }}
    where type = 'Main'
),

phone as (
    select
        dbt_service_id,
        number
    from phone_w_multiple_services
    where rn = 1 -- getting first phone number for each service
),

service_area_agg as (
    select
        dbt_service_id,
        extent
    from {{ ref('service_area') }}
),

taxonomy_agg as (
    select distinct
        dbt_link_id as dbt_service_id,
        array_agg(taxonomy_term.code ORDER BY taxonomy_term.code) as taxonomy_code
    from {{ ref('attribute') }} attribute
    join {{ ref('taxonomy_term') }} as taxonomy_term
    on attribute.dbt_taxonomy_term_id = taxonomy_term.dbt_taxonomy_term_id
    where attribute.link_entity = 'service'
    group by dbt_service_id
),

final as (
    select
        service.dbt_service_id,
        service.tenant_id,
        service.dbt_organization_id,
        service.name,
        service.description,
        service.fees_description,
        service.email,
        service.url,
        phone.number,
        service_area_agg.extent,
        taxonomy_agg.taxonomy_code
    from service
    left join phone on phone.dbt_service_id = service.dbt_service_id
    join service_area_agg on service_area_agg.dbt_service_id = service.dbt_service_id
    join taxonomy_agg on taxonomy_agg.dbt_service_id = service.dbt_service_id
)

select * from final