-- q_1:
-- channels of atliq exclusive's markets:
select distinct market, channel
from dim_customer
where customer='atliq exclusive';
-- gross sales amount of each market of atliq exclusive in apac region:
select dc.market, 
	concat(round(sum(fsm.sold_quantity*fgp.gross_price)*0.000001,2),' m')
		as gross_sales_amnt
from dim_customer as dc
	left join fact_sales_monthly as fsm 
		on dc.customer_code = fsm.customer_code
	left join fact_gross_price as fgp
		on fsm.product_code = fgp.product_code
where dc.customer = 'atliq exclusive'
	and region = 'apac'
group by 1;
-- total sales quantity of atliq exclusive indian market:
select dc.market,
	concat(round(sum(fsm.sold_quantity*0.000001),2),' m')
		as gross_sales_quantity
from dim_customer as dc
	left join fact_sales_monthly as fsm 
		on dc.customer_code = fsm.customer_code
where dc.customer = 'atliq exclusive'
	and dc.market = 'india' 
    and dc.region = 'apac';
-- channel wise gross sales amount of atliq exclusive indian market in apac region:
select dc.channel,
	round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2) 
		as gross_sales_amnt
from fact_gross_price as fgp
  inner join fact_sales_monthly as fsm
    on fsm.product_code = fgp.product_code 
    and fsm.fiscal_year = fgp.fiscal_year
  inner join dim_customer as dc
    on fsm.customer_code = dc.customer_code
where dc.customer = "atliq exclusive" 
		and dc.region = 'apac' 
		and dc.market = 'india'
group by 1;

-- q_2:
-- common products of 2020  and 2021:
with all_pro as (
	select distinct dp.product_code, fsm.fiscal_year
	from dim_product as dp
	right join fact_sales_monthly as fsm
	on dp.product_code = fsm.product_code)
select distinct product_code, group_concat(fiscal_year)
from all_pro
group by 1
having group_concat(fiscal_year) = '2020,2021';
-- product codes of 2020 fiscal year :
with all_pro as (
	select distinct dp.product_code, fsm.fiscal_year
	from dim_product as dp
	right join fact_sales_monthly as fsm
	on dp.product_code = fsm.product_code)
select distinct product_code, group_concat(fiscal_year)
from all_pro
group by 1
having group_concat(fiscal_year) = '2020';
-- product codes of 2021 fiscal year :
with all_pro as (
	select distinct dp.product_code, fsm.fiscal_year
	from dim_product as dp
	right join fact_sales_monthly as fsm
	on dp.product_code = fsm.product_code)
select distinct product_code, group_concat(fiscal_year)
from all_pro
group by 1
having group_concat(fiscal_year) = '2021';
-- year wise product count, their difference and difference in percentage :
with pro_20 as (
	select count(distinct(dp.product_code)) as unique_product_2020
    from dim_product as dp
    left join fact_sales_monthly as fsm
		on dp.product_code=fsm.product_code
    where fiscal_year='2020'),
    pro_21 as (
	select count(distinct(dp.product_code)) as unique_product_2021
    from dim_product as dp
    left join fact_sales_monthly as fsm
		on dp.product_code=fsm.product_code
    where fiscal_year='2021'),
    unknown_yr as (
	select count(distinct(dp.product_code))  as year_unknown
    from dim_product as dp
    left join fact_sales_monthly as fsm
		on dp.product_code=fsm.product_code
    where fiscal_year is null)
select *,   (unique_product_2021 - unique_product_2020) as difference,
	round(((unique_product_2021 - unique_product_2020)
	/unique_product_2020 * 100), 2) as percentage_chg
from pro_20 join pro_21 join unknown_yr;

q_3:
-- segment wise distinct product_count:
select segment, count(distinct product)
from dim_product
group by segment;
-- variant of each products in notebook segment:
select product, count(variant)
from dim_product 
where segment='notebook'
group by 1;
-- product details of networking segment:
select product, category, variant
from dim_product
where segment = 'networking';

-- q_4:
-- segment wise new product count, outdated product count and their differences:
with ab as (
	with code_seg as (
		with all_pro as (
			select distinct dp.product_code, dp.segment, 
				fsm.fiscal_year
			from dim_product as dp
			left join fact_sales_monthly as fsm
			on dp.product_code = fsm.product_code)
		select product_code, segment
		from all_pro
		group by 1,2
		having group_concat(fiscal_year)='2021')
	select segment, count(product_code) as new_pro_2021
	from code_seg
	group by 1),
     xy as (
	with code_seg as (
		with all_pro as (
			select distinct dp.product_code, dp.segment, 
				fsm.fiscal_year
			from dim_product as dp
			left join fact_sales_monthly as fsm
			on dp.product_code = fsm.product_code)
		select product_code, segment
		from all_pro
		group by 1,2
		having group_concat(fiscal_year)='2020')
	select segment, count(product_code) as outdated_pro_20
	from code_seg
	group by 1)
select ab.segment, new_pro_2021, outdated_pro_20,
		(ifnull(new_pro_2021,0)-ifnull(outdated_pro_20,0)) as difference
from ab left join xy on ab.segment = xy.segment
order by difference desc;
-- details and percentage of sold quantity of outdated products 2020:
with qnty as (
	with som as (
	with all_pro as (
		select distinct dp.product_code, dp.segment, dp.category, 
			product, variant, fsm.fiscal_year
		from dim_product as dp
		left join fact_sales_monthly as fsm
		on dp.product_code = fsm.product_code)
		select all_pro.product_code, segment, category, product, variant
		from all_pro  
		group by 1,2,3,4,5
		having group_concat(all_pro.fiscal_year)='2020')
	select som.product_code, segment, category, product, variant,
			sum(fsm.sold_quantity) as pro_sold_qnty
	from som inner join fact_sales_monthly as fsm
	on som.product_code = fsm.product_code
	group by 1,2,3,4,5),
	seg as (
		select dp.segment, sum(fsm.sold_quantity) as seg_sold_qnty
		from dim_product as dp left join fact_sales_monthly as fsm
		on dp.product_code = fsm.product_code
		group by 1)
select qnty.product_code, qnty.segment, category, product, variant,
		pro_sold_qnty, seg.seg_sold_qnty, (pro_sold_qnty/seg.seg_sold_qnty)*100 as pcnt_pro_sold
from qnty inner join seg
on qnty.segment = seg.segment
group by 1,2,3,4,5,6,7;

-- q_5:
-- product details fiscal and manufacture year and gross price of highest and lowest manufacturing cost: 
select dp.product_code, product, category, segment, variant, 
		fmc.manufacturing_cost, fmc.cost_year, 
        fgp.gross_price, fgp.fiscal_year
from dim_product as dp 
	right join fact_manufacturing_cost as fmc
	on dp.product_code = fmc.product_code
    left join fact_gross_price as fgp
    on fmc.product_code = fgp.product_code
where fmc.manufacturing_cost = (select max(manufacturing_cost)
				from fact_manufacturing_cost)
union
select dp.product_code, product, category, segment, variant, 
		fmc.manufacturing_cost, fmc.cost_year, 
        fgp.gross_price, fgp.fiscal_year
from dim_product as dp 
	right join fact_manufacturing_cost as fmc
	on dp.product_code = fmc.product_code
        left join fact_gross_price as fgp
    on fmc.product_code = fgp.product_code
where fmc.manufacturing_cost = (select min(manufacturing_cost)
				from fact_manufacturing_cost);

-- q_6:
-- 2020 top 5 customer in indian market who received highest average discount percentage:
select dc.customer_code, dc.customer,
        round(avg(pid.pre_invoice_discount_pct)*100, 2) 
		 as avg_discnt_pct
from fact_pre_invoice_deductions as pid
left join dim_customer as dc
	on dc.customer_code = pid.customer_code
where dc.market = 'india' and pid.fiscal_year='2020'
group by 1,2 order by 3 desc
limit 5;
/*2021 top 5 customer in indian market who received highest average discount percentage and their gross sales amount comparision:*/
with ab as (
	select distinct dc.customer, 
			round(avg(pid.pre_invoice_discount_pct)*100, 2) 
			 as avg_discnt_pct
	from fact_pre_invoice_deductions as pid
	inner join dim_customer as dc
    on pid.customer_code=dc.customer_code
	where dc.market = 'india' and pid.fiscal_year='2021'
	group by 1),
	xy as (
    select dc.customer, 
	round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2)
	as gross_sales_amnt
	from dim_customer as dc
	inner join fact_sales_monthly as fsm
	on dc.customer_code = fsm.customer_code
	inner join fact_gross_price as fgp
	on fsm.product_code = fgp.product_code
	where dc.market='india' and fsm.fiscal_year='2021'
	and dc.customer in ('flipkart', 'viveks', 'ezone', 'croma', 'amazon')
	group by 1)
select xy.customer,  gross_sales_amnt, avg_discnt_pct
from ab right join xy 
on ab.customer = xy.customer
order by 3 desc;

-- q_7:
-- highest monthly gross sales amount for all customers with month and year:
with som as (
	select date_format(fsm.date, "%b") as month,
	date_format(fsm.date, "%y") as year, dc.customer,
	round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2)
		as gross_sales_amnt,
	 dense_rank() 
		over(partition by customer 
	 order by round((sum(fsm.sold_quantity * fgp.gross_price)*0.000001),2) desc)
	 as highest
from fact_gross_price as fgp
  inner join fact_sales_monthly as fsm
    on fsm.product_code = fgp.product_code 
    and fsm.fiscal_year = fgp.fiscal_year
  inner join dim_customer as dc
    on fsm.customer_code = dc.customer_code
group by 3,2,1)
select customer, concat_ws(" - ",month,year) as month_year, gross_sales_amnt
from som
where highest=1
order by gross_sales_amnt desc;

-- q_8:
-- segment wise total sold quantity of each quarters in 2020:
with top as (
	select dp.segment,
		case when month(fsm.date) between 9 and 11 then '1st'
             when month(fsm.date) between 3 and  5 then '3rd'
             when month(fsm.date) between 6 and  8 then '4th'
		else '2nd'
        end as quarter,
		sum(fsm.sold_quantity) as total_sold_quantity
	from dim_product as dp 
	  inner join fact_sales_monthly as fsm
	   on dp.product_code = fsm.product_code
	where fsm.fiscal_year = '2020'
	group by 1,2)
select * from top;
-- 2021 quarter wise total sold quantity:
select case when month(date) between 9 and 11 then '1st'
             when month(date) between 3 and  5 then '3rd'
             when month(date) between 6 and  8 then '4th'
		else '2nd'
        end as quarter,
		round((sum(sold_quantity)*0.000001),2) 
		as total_sold_quantity
from fact_sales_monthly
where fiscal_year = '2021' 
group by 1
order by total_sold_quantity desc;
-- total sold quantity grouped by fiscal years and segment:
with top as (
	select dp.segment, fsm.fiscal_year,
		sum(fsm.sold_quantity) as total_sold_quantity
	from dim_product as dp 
	  inner join fact_sales_monthly as fsm
	   on dp.product_code = fsm.product_code
	group by 1,2
    order by 2)
select * from top;
-- q_10:
-- division wise top 3 products and their variants with high total sold quantity in 2021:
with top as (
	select dp.division, dp.product_code, dp.product, dp.variant,
		sum(fsm.sold_quantity) as total_sold_quantity,
            dense_rank() 
            over(partition by division 
		 order by sum(fsm.sold_quantity) desc)
		 as rank_order
	from dim_product as dp 
	  inner join fact_sales_monthly as fsm
	   on dp.product_code = fsm.product_code
	where fsm.fiscal_year = '2021'
	group by 1,2,3,4
	order by total_sold_quantity desc)
select * from top where rank_order <= 3;