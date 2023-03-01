-- Q_1:
select distinct market
from dim_customer
where customer = 'atliq exclusive'
	and region = 'apac';

-- Q_2:
with pro_20 as (
    select count(distinct(product_code)) as unique_product_2020
    from fact_sales_monthly
    where fiscal_year='2020'),
    pro_21 as (
	select count(distinct(product_code)) as unique_product_2021
    from fact_sales_monthly
    where fiscal_year='2021')
select *, round(((unique_product_2021 - unique_product_2020)
		/unique_product_2020 * 100), 2) as percentage_chg
from pro_20 join pro_21;

-- Q_3:
select segment, count(product_code) as product_count
from dim_product 
group by 1 order by 2 desc;

-- Q_4:
with pro_20 as (
     select dp.segment, 
	count(distinct dp.product_code) as product_count_20
	from dim_product as dp 
    inner join fact_sales_monthly as fsm
	on dp.product_code = fsm.product_code
    where fsm.fiscal_year = '2020' 
    group by 1),
    pro_21 as (
    select dp.segment,
	count(distinct dp.product_code) as product_count_21
    from dim_product as dp 
    inner join fact_sales_monthly as fsm
	on dp.product_code = fsm.product_code
    where fsm.fiscal_year = '2021'
    group by 1)
select pro_20.segment, product_count_21, product_count_20,
	   (product_count_21-product_count_20) as difference
from pro_21 left join pro_20 on pro_21.segment = pro_20.segment
order by difference desc;

-- Q_5:
select dp.product_code, product, fmc.manufacturing_cost
from dim_product as dp 
	right join fact_manufacturing_cost as fmc
	on dp.product_code = fmc.product_code
where fmc.manufacturing_cost = (select max(manufacturing_cost)
				from fact_manufacturing_cost)
union
select dp.product_code, product, fmc.manufacturing_cost
from dim_product as dp 
	right join fact_manufacturing_cost as fmc
	on dp.product_code = fmc.product_code
where fmc.manufacturing_cost = (select min(manufacturing_cost)
				from fact_manufacturing_cost);

-- Q_6:
select dc.customer_code, dc.customer,
        round(avg(pid.pre_invoice_discount_pct)*100, 2) 
		 as avg_discnt_pct
from fact_pre_invoice_deductions as pid
left join dim_customer as dc
	on dc.customer_code = pid.customer_code
where dc.market = 'india' and pid.fiscal_year='2021'
group by 1,2 order by 3 desc
limit 5;

-- Q_7:
select date_format(fsm.date, "%b") as month,
	date_format(fsm.date, "%y") as year,
	concat(round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2), ' M') 
		as gross_sales_amnt
from fact_gross_price as fgp
  inner join fact_sales_monthly as fsm
    on fsm.product_code = fgp.product_code 
    and fsm.fiscal_year = fgp.fiscal_year
  inner join dim_customer as dc
    on fsm.customer_code = dc.customer_code
where dc.customer = "atliq exclusive"
group by 1,2;

-- Q_8:
select case when month(date) between 9 and 11 then '1st'
             when month(date) between 3 and  5 then '3rd'
             when month(date) between 6 and  8 then '4th'
		else '2nd'
        end as quarter,
	concat(round((sum(sold_quantity)*0.000001),2), ' M') 
	  as total_sold_quantity
from fact_sales_monthly
where fiscal_year = '2020' 
group by 1
order by total_sold_quantity desc;

-- Q_9:
with chl as (
	select dc.channel,
	concat(round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2), ' M')
		as gross_sales_mln
	from fact_gross_price as fgp
	  inner join fact_sales_monthly as fsm
	    on fsm.product_code = fgp.product_code 
	    and fsm.fiscal_year = fgp.fiscal_year
	  inner join dim_customer as dc
	    on fsm.customer_code = dc.customer_code
	where fsm.fiscal_year='2021'
	group by 1)
select *, round(100*gross_sales_mln/sum(gross_sales_mln)
			over (),2) as percentage
from chl order by percentage desc;

-- Q_10:
with top as (
	select dp.division, dp.product_code, dp.product, 
		sum(fsm.sold_quantity) as total_sold_quantity,
            dense_rank() 
            over(partition by division 
		 order by sum(fsm.sold_quantity) desc)
		 as rank_order
	from dim_product as dp 
	  inner join fact_sales_monthly as fsm
	   on dp.product_code = fsm.product_code
	where fsm.fiscal_year = '2021'
	group by 1,2,3
	order by total_sold_quantity desc)
select * from top where rank_order <= 3;