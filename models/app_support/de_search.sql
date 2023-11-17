with sal as (
    select
        dbt_service_at_location_id,
        tenant_id,
        dbt_service_id,
        dbt_location_id
    from {{ ref('service_at_location') }}
),

services as (
    select
        dbt_service_id,
        dbt_organization_id,
        name,
        description,
        email,
        fees_description,
        url,
        number,
        extent,
        taxonomy_code
    from {{ ref('help_service') }}
),

locations as (
    select
        dbt_location_id,
        name,
        latitude,
        longitude,
        address_1,
        city,
        state_province,
        postal_code,
        country,
        number
    from {{ ref('help_location') }}
),

organizations as (
    select
        dbt_organization_id,
        name,
        description
    from {{ ref('organization') }}
),


phone as (
    select
        dbt_service_at_location_id,
        number,
        priority
    from {{ ref('help_sal_phone') }}
        where priority = 0 -- getting first phone number for each service_at_location
),

final as (
    select
        sal.dbt_service_at_location_id,
        sal.dbt_service_id,
        sal.dbt_location_id,
        sal.tenant_id,
        services.dbt_organization_id,
        services.name as service_name,
        case 
            when services.name = locations.name
                then services.name
            else 
                services.name || ' at ' || locations.name
        end as display_name,
        -- services.name || ' at ' || locations.name as display_name,
        cast(null as text) as service_alternate_name,
        services.description as service_description,
        cast(null as text) as service_short_description,
        services.email as primary_email,
        services.url as primary_website,
        phone.number as primary_phone, -- Fallthrough from SAL to Service number to Location number
        services.extent as service_area,
        services.taxonomy_code,
        organizations.name as organization_name,
        cast(null as text) as organization_alternate_name,
        organizations.description as organization_description,
        locations.name as location_name,
        locations.latitude as location_latitude,
        locations.longitude as location_longitude,
        '{"coordinates": [' || locations.latitude || ',' || locations.longitude || '], "type": "Point"}' as location,
        locations.address_1 as physical_address,
        locations.city as physical_address_city,
        locations.state_province as physical_address_state,
        locations.postal_code as physical_address_postal_code,
        locations.country as physical_address_country,
        cast(null as text) as facets
        
    from sal
    join services on services.dbt_service_id = sal.dbt_service_id
    join locations on locations.dbt_location_id = sal.dbt_location_id
    join organizations on organizations.dbt_organization_id = services.dbt_organization_id
    left join phone on phone.dbt_service_at_location_id = sal.dbt_service_at_location_id
)

select * from final