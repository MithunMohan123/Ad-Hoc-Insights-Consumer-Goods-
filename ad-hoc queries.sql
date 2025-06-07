-- 1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its  business in the  APAC  region. 

select * from dim_customer 
where customer="Atliq Exclusive" and region="APAC";


-- 2. What is the percentage of unique product increase in 2021 vs. 2020?

with unique_product_2020 as(
select count(distinct(product_code)) as product_count_2020  from fact_sales_monthly
where fiscal_year = 2020
),
unique_product_2021 as(
select count(distinct(product_code)) as product_count_2021 from fact_sales_monthly 
where fiscal_year = 2021
)

SELECT u20.product_count_2020,u21.product_count_2021,
ROUND((u21.product_count_2021 - u20.product_count_2020) / u20.product_count_2020 * 100, 2) AS pct_increase
FROM unique_product_2021 u21, unique_product_2020 u20;

-- 3. Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. 

select segment,count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;

-- 4. Which segment had the most increase in unique products in 2021 vs 2020?

with unique_prod_2020 as (
    select p.segment, count(distinct p.product_code) as product_count_2020
    from dim_product p
    join fact_sales_monthly s
    on p.product_code = s.product_code
    where s.fiscal_year = 2020
    group by p.segment
),
unique_prod_2021 as (
    select p.segment, count(distinct p.product_code) as product_count_2021
    from dim_product p
    join fact_sales_monthly s
    on p.product_code = s.product_code
    where s.fiscal_year = 2021
    group by p.segment
)
select up21.segment, up20.product_count_2020, up21.product_count_2021,
       up21.product_count_2021 - up20.product_count_2020 as increase_in_product_count
from unique_prod_2021 up21
join unique_prod_2020 up20
on up21.segment = up20.segment
order by increase_in_product_count desc;


--  5. Get the products that have the highest and lowest manufacturing costs. 

select m.product_code, p.product, m.manufacturing_cost
from fact_manufacturing_cost m
join dim_product p
on p.product_code = m.product_code
where m.manufacturing_cost in (
    (select max(manufacturing_cost) from fact_manufacturing_cost),
    (select min(manufacturing_cost) from fact_manufacturing_cost)
);


-- 6.  Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the Indian  market.

select f.customer_code, d.customer,f.pre_invoice_discount_pct,
       DENSE_RANK() OVER (ORDER BY AVG(f.pre_invoice_discount_pct) DESC) 
from fact_pre_invoice_deductions f
join dim_customer d ON f.customer_code = d.customer_code
where f.fiscal_year = 2021 AND d.market = 'India'
group by f.customer_code
limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month .

SELECT MONTHNAME(s.date) AS month, s.fiscal_year, 
concat(round(SUM(s.sold_quantity*g.gross_price)/1000000, 2), ' M') AS gross_sales_mln 
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY MONTHNAME(s.date), s.fiscal_year
ORDER BY fiscal_year;
 
 -- 8. In which quarter of 2020, got the maximum total_sold_quantity?
 
 with cte as (
 select *, sum(sold_quantity) as total_qty,
 
 case
	when month(s.date) in (9,10,11) then "Q1"
	when month(s.date) in (12,01,02) then "Q2"
	when month(s.date) in (04,05,03) then "Q3"
	else "Q4"
 end as quater
 from fact_sales_monthly s
 where fiscal_year=2020
 group by quater
 order by total_qty desc
 )
 select quater,total_qty from cte;
 
 -- 9. Which channel helped to bring more gross sales in the fiscal year 2021  and the percentage of contribution?
 
select 
    c.channel, 
    CONCAT(ROUND(SUM(g.gross_price * s.sold_quantity)/1000000, 2), ' M') AS gross_sales_mln,
    CONCAT(ROUND(
        (SUM(g.gross_price * s.sold_quantity) / 
         SUM(SUM(g.gross_price * s.sold_quantity)) OVER()) * 100, 2), ' %') AS percentage_contribution
from dim_customer c
join fact_sales_monthly s 
using (customer_code)
join fact_gross_price g 
using (product_code)
where s.fiscal_year = 2021
group by c.channel
order by percentage_contribution DESC;
 
 
 -- 10.  Get the Top 3 products in each division that have a high stotal_sold_quantity in the fiscal_year 2021?
 WITH product_sales AS 
(
    SELECT 
        p.division, 
        fs.product_code, 
        p.product AS product_name, 
        SUM(fs.sold_quantity) AS total_units_sold
    FROM dim_product p
    JOIN fact_sales_monthly fs ON p.product_code = fs.product_code
    WHERE fs.fiscal_year = 2021 
    GROUP BY fs.product_code, p.division, p.product
),
top_products_by_division AS 
(
    SELECT 
        division, 
        product_code, 
        product_name, 
        total_units_sold,
        RANK() OVER (PARTITION BY division ORDER BY total_units_sold DESC) AS rank_in_division
    FROM product_sales
)
SELECT 
    tp.division, 
    tp.product_code, 
    tp.product_name, 
    tp.total_units_sold, 
    tp.rank_in_division
FROM top_products_by_division tp
WHERE tp.rank_in_division IN (1, 2, 3);




