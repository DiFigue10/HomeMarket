use AdventureWorks2019;

-- Tables to be used
/*
1. [Person].[Person]
2. [Sales].[Customer]
3. [Production].[Product]
4. [Production].[ProductSubcategory]
5. [Production].[ProductCategory]
6. [Sales].[SalesTerritory]
7. [Sales].[SalesOrderHeader]
8. [Sales].[SalesOrderDetail]
*/
------------------------------------------------------------------------------------------------------------------
-- To get the CUSTOMERS view
select * from [Person].[Person] ;
select * from [Sales].[Customer];

create view v_customers as
select C.CustomerID , CONCAT_WS(' ',P.FirstName, P.LastName) as Names , C.StoreID , C.TerritoryID
from [sales].[Customer] as C
left Join [person].[person] as P
on C.PersonID = P.BusinessEntityID
where C.PersonID is not null;

------------------------------------------------------------------------------------------------------------------
-- To get the TERRITORY view
select * from [sales].[SalesTerritory];

create view v_territory as
select
	a.territoryID
	, case when a.countryregioncode ='US' then 'United States' else a.name END AS Country
	, a.countryregioncode
	,[group] as 'Group'
from [sales].[salesterritory] as a;

------------------------------------------------------------------------------------------------------------------
-- To get the PRODUCTS view
select * from [production].[Product];
select * from [Production].[ProductCategory];
select * from [Production].[ProductSubcategory];

create view v_products as
select p.productID, P.name as 'Product' , s.name as 'Subcategory' , C.Name as 'Category'
from [Production].[Product] as P
left join [Production].[ProductSubcategory] as S
	on P.ProductSubcategoryID = S.ProductSubcategoryID
left join [Production].[ProductCategory] as C
	on C.ProductCategoryID = S.ProductCategoryID;

------------------------------------------------------------------------------------------------------------------
-- To get the SALES view
select * from [Sales].[SalesOrderHeader];
select * from [Sales].[SalesOrderDetail];

create view v_sales as
select H.salesorderid
		, cast (h.orderdate as date) as OrderDate
		, cast (h.shipdate as date) as ShipDate 
		, h.territoryID 
		, h.customerid
		, d.productid 
		, d.orderqty as OrderQty 
		, d.unitprice as UnitPrice
		, d.orderqty*d.unitprice as subtotal
from [sales].[SalesOrderHeader] as H
	left join [Sales].[SalesOrderDetail] as D
on H.SalesOrderID = D.SalesOrderID;

------------------------------------------------------------------------------------------------------------------
-- Creating the CALENDAR table
create table calendar
	(fecha date,
	año int,
	mes_numero int,
	mes varchar (3),
	mes_largo varchar (20),
	dia int)

select * from calendar;

------------------------------------------------------------------------------------------------------------------
--Creating store procedure

create procedure generate_dates

as
	truncate table calendar;
	declare @fec_inicio date;
	declare @fec_fin date;
	declare @anio int;
	declare @mes_num int;
	declare @mes_corto varchar(20);
	declare @mes_largo varchar(20);
	declare @dia int;

	set @fec_inicio = (select cast(min(orderdate)as date) from [sales].[SalesOrderHeader]);

	set @fec_fin = (select cast (max(shipdate)as date) from [sales].[SalesOrderHeader]);

	while @fec_inicio <= @fec_fin
	begin
		set @anio = (select year (@fec_inicio));
		set @mes_num = (select MONTH (@fec_inicio));
		set @mes_corto = (select format (@fec_inicio , 'MMM' , 'PE'))
		set @mes_largo = (select format (@fec_inicio , 'MMMM' , 'es-PE'))
		set @dia = (select day (@fec_inicio))

		insert into calendar( fecha, año , mes_numero , mes , mes_largo , dia)
		select @fec_inicio , @anio , @mes_num , @mes_corto , @mes_largo , @dia;

		set @fec_inicio = dateadd(day, 1 , @fec_inicio)
	end;

exec generate_dates
 
/*drop procedure generar_fechas;*/

------------------------------------------------------------------------------------------------------------------
--Using Bulk to create a temporary table SALES PEOPLE

create table #salespeople  /*temporary table*/
(name varchar (100)
, PersonType varchar (100)
, TerritoryId varchar (100)
, SalesQuota varchar (100)
, Bonus varchar (100)
, SalesYTD varchar (100)
, SalesLastYear varchar (100)
);

BULK INSERT
	#salespeople
FROM
	'C:\Users\Usuario\OneDrive\Escritorio\Portafolio\1. SQL\Bulk.txt'
WITH
	(FIRSTROW=2);

select * from #salespeople

select
	a.Name
	,cast (PersonType as varchar(10)) as PersonType 
	,cast(case when TerritoryID = 'NULL' then 0 else TerritoryID end as smallint) as TerritoryID
	,cast(replace(case when SalesQuota = 'NULL' then 0 else SalesQuota end, ',' ,'.') as float) as SalesQuota
	,cast(replace(case when Bonus = 'NULL' then 0 else Bonus end , ',' , '.') as float) as Bonus
	,cast(replace(SalesYTD,',','.') as float) as SalesYTD
	,cast(replace(SalesLastYear,',','.') as float) as SalesLastYear
into t_salespeople /*materialize the temporary table*/
from
	#salespeople AS a;

select * from t_salespeople