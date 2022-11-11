
  
    
        create or replace table default.dim_customers
      
      
    using delta
      
      
      
      
    location '/mnt/gold/customers/dim_customers'
      
      
      as
      

with address_snapshot as (
    select
        AddressID,
        AddressLine1,
        AddressLine2,
        City,
        StateProvince,
        CountryRegion,
        PostalCode
    from snapshots.address_snapshot where dbt_valid_to is null
)

, customeraddress_snapshot as (
    select
        CustomerId,
        AddressId,
        AddressType
    from snapshots.customeraddress_snapshot where dbt_valid_to is null
)

, customer_snapshot as (
    select
        CustomerId,
        -- Adopted function concat() to concatenate first, middle and lastnames
        concat(ifnull(FirstName,' '),' ',ifnull(MiddleName,' '),' ',ifnull(LastName,' ')) as FullName
    from snapshots.customer_snapshot where dbt_valid_to is null
)

, transformed as (
    select
    row_number() over (order by customer_snapshot.customerid) as customer_sk, -- auto-incremental surrogate key    
    customer_snapshot.CustomerId,
    customer_snapshot.fullname,
    customeraddress_snapshot.AddressID,
    customeraddress_snapshot.AddressType,
    address_snapshot.AddressLine1,
    address_snapshot.City,
    address_snapshot.StateProvince,
    address_snapshot.CountryRegion,
    address_snapshot.PostalCode
    from customer_snapshot
    inner join customeraddress_snapshot on customer_snapshot.CustomerId = customeraddress_snapshot.CustomerId
    inner join address_snapshot on customeraddress_snapshot.AddressID = address_snapshot.AddressID
)
select *
from transformed
  