with location as (
    select
        dbt_location_id,
        tenant_id,
        dbt_organization_id,
        name,
        latitude,
        longitude
    from {{ ref('location') }}
),

physical_address as (
    select
        dbt_location_id,
        address_1,
        city,
        state_province,
        postal_code,
        country
    from {{ ref('address') }}
    where address_type = 'physical'
),

phone_w_multiple_locations as (
    select
        dbt_location_id,
        number,
        ROW_NUMBER() OVER (PARTITION BY dbt_location_id ORDER BY number) as rn 
    from {{ ref('phone') }}
    where type = 'Main'
)
, phone as (
    select
        dbt_location_id,
        number
    from phone_w_multiple_locations
    where rn = 1 -- getting first phone number for each location
)

, final as (
    select
        location.dbt_location_id,
        location.tenant_id,
        location.dbt_organization_id,
        location.name,
        location.latitude,
        location.longitude,
        physical_address.address_1,
        physical_address.city,
        physical_address.state_province,
        physical_address.postal_code,
        physical_address.country,
        phone.number
    from location
    left join physical_address
    on location.dbt_location_id = physical_address.dbt_location_id
    left join phone on phone.dbt_location_id = location.dbt_location_id
)

select * from final