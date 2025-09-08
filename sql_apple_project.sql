--creating tables 

--creating table stores

create table stores(
Store_ID varchar(5) primary key,
Store_Name varchar(30),
City varchar(25),
Country varchar(25)
);


--creating table category	
create table category(
category_id varchar(10) primary key,
category_name varchar(20)
);


--creating table products
create table products(
	Product_ID varchar(10) primary key,
	Product_Name varchar(35),
	Category_ID varchar(10),
	Launch_Date date,
	Price float,
	constraint fk_category foreign key (category_id) references category(category_id)
);


--creating table sales
create table sales(
	sale_id varchar(15) primary key,
	sale_date date,
	store_id varchar(5),
	product_id varchar(10),
	quantity int,
	constraint fk_stores foreign key (store_id) references stores(store_id),
	constraint fk_products foreign key (product_id) references products(product_id)
);


--creating table warranty
create table warranty(
claim_id  varchar(10) primary key,
claim_date date,
sale_id varchar(15),
repair_status varchar(15),
constraint fk_sales foreign key (sale_id) references sales(sale_id)
);

--Apple Sales Project - 1M rows sales dataset
select * from category;
select * from stores;
select * from products;
select * from sales;
select * from warranty;

--Find the number of stores in each country.
select count(store_id), country from stores
group by country;
	
--Calculate the total number of units sold by each store.
select count(quantity) as units, store_id from sales
	group by store_id;


--Identify how many sales occurred in December 2023.
select sum(quantity) no_of_sale from sales
where extract( year from sale_date) = 2023
and
extract(month from sale_date) = 12;


--Determine how many stores have never had a warranty claim filed.
select count(distinct store_id) from sales
join warranty 
on sales.sale_id=warranty.sale_id
where warranty.sale_id is null;

--Identify which store had the highest total units sold in the last year.
select sum(quantity) from sales
where extract(year from sale_date)= 2024
	;
--Count the number of unique products sold in the last year.
select count(distinct product_name) from products
	join sales on products.product_id=sales.product_id
where 
	extract(year from sales.sale_date)=(select max(extract(year from sales.sale_date)) from sales);

--Find the average price of products in each category.
select avg(price), product_id from products
group by product_id;


--How many warranty claims were filed in 2020?
select count(claim_id)
	from warranty
	where extract( years from claim_date) = 
	(select min(extract(years from claim_date))
	from warranty);

--For each store, identify the best-selling day based on highest quantity sold.

select * from 
(select store_id,
	sum(quantity),
	extract(dow from sale_date) as best_selling_day,
	rank() over (partition by store_id 
	order by sum(quantity) desc)as rank 
	from sales 
	group by store_id, extract(dow from sale_date)) sub
where rank = 1
	;

--Identify the least selling product in each country for each year based on total units sold.

SELECT country,
       years,
       p.product_name,
       total_units
FROM (
    SELECT st.country,
           EXTRACT(YEAR FROM s.sale_date) AS years,
           s.product_id,
           min(s.quantity) AS total_units,
           ROW_NUMBER() OVER (
               PARTITION BY st.country, EXTRACT(YEAR FROM s.sale_date)
               ORDER BY min(s.quantity) ASC
           ) AS rn
    FROM sales s
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.country, EXTRACT(YEAR FROM s.sale_date), s.product_id
) sub
JOIN products p ON sub.product_id = p.product_id
WHERE rn = 1;


--Calculate how many warranty claims were filed within 180 days of a product sale.
select count(*)
from warranty w
join sales s
on w.sale_id=s.sale_id
where w.claim_date= s.sale_date + interval '180 days';

--Determine how many warranty claims were filed for products launched in the last two years.
select count(distinct claim_id)
from warranty w
join sales s on w.sale_id= s.sale_id
join products p on s.product_id=p.product_id
where w.claim_date= p.launch_date + interval '2 years';


--List the months in the last three years where sales exceeded 10,0000 units.
select years,months, total_quantity, rnk from
(select sum(quantity) as total_quantity,
	extract(year from sale_date) as years,
	extract(month from sale_date) as months,
	rank() over (partition by extract(year from sale_date) 
	order by sum(quantity)) as rnk  
	from sales
	group by extract(year from sale_date),
	extract(month from sale_date)) sub
where total_quantity>100000;



--Identify the product category with the most warranty claims filed in the last two years.
select count(w.claim_id) as total_claims,
	extract(year from w.claim_date) as dates,
	c.category_name 
from warranty w
join sales s on w.sale_id= s.sale_id
join products p on s.product_id=p.product_id
join category c on p.category_id=c.category_id	
	where w.claim_date>= current_date - interval '2 years'
group by c.category_name, extract(year from w.claim_date)
order by total_claims desc 
	limit 1 ;


--Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.
SELECT 
    p.product_id,
    p.product_name,
    CASE 
        WHEN (s.sale_date - p.launch_date) <= 180 THEN '0-6 months'
        WHEN (s.sale_date - p.launch_date) <= 365 THEN '6-12 months'
        WHEN (s.sale_date - p.launch_date) <= 545 THEN '12-18 months'
        ELSE '18+ months'
    END AS periods,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.quantity * p.price) AS total_revenue
FROM products p
JOIN sales s 
    ON p.product_id = s.product_id
GROUP BY 
    p.product_id, p.product_name,
    CASE 
        WHEN (s.sale_date - p.launch_date) <= 180 THEN '0-6 months'
        WHEN (s.sale_date - p.launch_date) <= 365 THEN '6-12 months'
        WHEN (s.sale_date - p.launch_date) <= 545 THEN '12-18 months'
        ELSE '18+ months'
    END
ORDER BY p.product_id, periods;
