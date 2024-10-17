-- rename column
 
 alter table stocks rename column quantity to stock_quantity;
 
-- update orders table

Alter table orders
add column def_order_status varchar(15);

update orders
set def_order_status = 'Pending'
where order_status = 1;

update orders
set def_order_status = 'Processing'
where order_status = 2;

update orders
set def_order_status = 'Rejected'
where order_status = 3;

update orders
set def_order_status = 'Completed'
where order_status = 4;

alter table orders modify column def_order_status varchar(15) after order_status;

-- creating new column total sales in order_items

Alter table order_items
add column total_sales float;

Update order_items
set total_sales = list_price*quantity-(list_price*quantity*discount);

# Analyzing products 

-- top 10 best-selling products

select products.product_id, 
product_name,
sum(quantity) as total_units,
round(sum(total_sales)) as total_sales
from products 
inner join order_items on products.product_id = order_items.product_id
group by 1
order by 4 desc
limit 10; 

-- most rejected products

with rejected as (
select products.product_id, 
product_name, 
sum(quantity) as total_units,
sum(case when def_order_status = 'Rejected' then 1 else 0 end) as total_rejected,
round(sum(case when def_order_status = 'Rejected' then 1 else 0 end)/count(*) * 100,2) as percentage_rejected
from orders
inner join order_items on orders.order_id = order_items.order_id
inner join products on order_items.product_id = products.product_id
group by 1,2
order by 4 desc)

select *
from rejected
where total_rejected > 0;
 
 
 
 # Analyzing brands
 
-- revenue by brands
 
 with brand as(
 select brands.brand_id, 
 brand_name, 
 year(order_date) as year,
 sum(total_sales) as total_revenue,
 sum(quantity) as total_units
 from brands
 inner join products on products.brand_id = brands.brand_id
 inner join order_items on products.product_id = order_items.product_id
 inner join orders on orders.order_id = order_items.order_id
 group by 1,2,3),
 
revenue as (
select brand_id, 
brand_name,
round(sum(case when year = '2021' then total_revenue else 0 end)) as 2021_year,
round(sum(case when year = '2022' then total_revenue else 0 end)) as 2022_year,
round(sum(case when year = '2023' then total_revenue else 0 end)) as 2023_year,
round(sum(total_revenue)) as total_revenue,
sum(total_units) as total_units
from brand
group by 1,2)

select *, 
round(sum(total_revenue) over (partition by brand_id) / sum(total_revenue) over() * 100,2) as percentage_of_sales
from revenue
group by 1,2
order by 6 desc;

-- best-selling brands in each city

with ranking_table as (
select brands.brand_id, 
brand_name, 
state, 
city, 
sum(quantity) as total_units,
round(sum(total_sales)) as total_revenue,
rank() over(partition by city order by sum(total_sales) desc) as ranking
from brands
inner join products on products.brand_id = brands.brand_id
inner join order_items on products.product_id = order_items.product_id
inner join orders on orders.order_id = order_items.order_id
inner join customers on customers.customer_id = orders.customer_id
group by 1,2,3,4
)

select * 
from ranking_table
where ranking = 1
order by 5 desc;
 
 
 
# Analyzing categories:

-- revenue by category

with category as (
select categories.category_id, 
category_name, 
sum(total_sales) as total_revenue,
sum(quantity) as total_units,
year(order_date) as year
from categories
inner join products on categories.category_id = products.category_id
inner join order_items on order_items.product_id = products.product_id
inner join orders on orders.order_id = order_items.order_id
group by 1,2,5),

revenue as (select category_id, 
category_name,
round(sum(case when year = '2021' then total_revenue else 0 end)) as 2021_year,
round(sum(case when year = '2022' then total_revenue else 0 end)) as 2022_year,
round(sum(case when year = '2023' then total_revenue else 0 end)) as 2023_year,
sum(total_units) as total_units,
round(sum(total_revenue)) as total_revenue
from category
group by 1,2)

select *, 
round(sum(total_revenue) over (partition by category_id) / sum(total_revenue) over() * 100) as percentage_of_sales
from revenue
group by 1,2
order by 7 desc;

-- best-selling categories in each city

with ranking_table as (
select category_name, 
state,
city, 
sum(quantity) as total_units,
round(sum(total_sales)) as total_sales,
rank() over(partition by city order by sum(total_sales) desc) as ranking
from customers 
inner join orders on customers.customer_id = orders.customer_id
inner join order_items on orders.order_id = order_items.order_id
inner join products on order_items.product_id = products.product_id
inner join categories on categories.category_id= products.category_id
group by 1,2,3)

select *
from ranking_table
where ranking = 1
order by 4 desc;



# Analyzing stores

-- total sales by store

with st as( 
select stores.store_id, 
store_name, 
sum(quantity) as total_units,
sum(total_sales) as total_revenue , 
year(order_date) as year
from stores 
inner join orders on stores.store_id = orders.store_id
inner join order_items on orders.order_id = order_items.order_id
group by 1,2,5),

revenue as (
select store_id, 
store_name,
round(sum(case when year = '2021' then total_revenue else 0 end)) as 2021_year,
round(sum(case when year = '2022' then total_revenue else 0 end)) as 2022_year,
round(sum(case when year = '2023' then total_revenue else 0 end)) as 2023_year,
sum(total_units) as total_units,
round(sum(total_revenue)) as total_revenue
from st
group by 1,2)

select *, 
round(sum(total_revenue) over (partition by store_id) / sum(total_revenue) over() * 100,2) as percentage_of_sales
from revenue
group by 1,2
order by 7 desc;

-- average_delivery time 

select stores.store_id, 
store_name, 
round(avg(datediff(shipped_date, order_date)),2) as average_delivery_time
from stores 
inner join orders on stores.store_id = orders.store_id
inner join order_items on orders.order_id = order_items.order_id
group by 1,2
order by 3;

-- best month for each store based on total_sales

select * from (
select stores.store_id, 
store_name, 
concat(monthname(order_date), '-' , year(order_date)) as month, 
sum(quantity) as total_units, 
round(sum(total_sales)) as total_sales, 
rank() over (partition by store_id order by sum(total_sales) desc) as ranking
from stores 
inner join orders on stores.store_id = orders.store_id
inner join order_items on orders.order_id = order_items.order_id
group by 1,2,3) as sales
where ranking = 1
order by 5 desc;


# Analyzing customers

-- top 10 customers by purchases

with ct as (
select customers.customer_id, 
concat(first_name, ' ', last_name) as full_name,
year(order_date) as year,
sum(total_sales) as total_purchases,
sum(quantity) as total_units
from customers 
inner join orders on customers.customer_id = orders.customer_id
inner join order_items on orders.order_id = order_items.order_id
group by 1,2,3) 

select customer_id, 
full_name,
round(sum(case when year = '2021' then total_purchases else 0 end)) as 2021_year,
round(sum(case when year = '2022' then total_purchases else 0 end)) as 2022_year,
round(sum(case when year = '2023' then total_purchases else 0 end)) as 2023_year,
round(sum(total_purchases)) as total_purchases,
sum(total_units) as total_units,
round(sum(total_purchases)/sum(total_units)) as average_order
from ct
group by 1,2
order by 6 desc
limit 10;

-- top customers in each city

select * from (
select customers.customer_id, 
concat(first_name, ' ', last_name) as full_name, 
state, 
city, 
count(orders.order_id) as total_orders,
sum(quantity) as total_units,
round(sum(total_sales)) as total_purchases,
dense_rank() over(partition by city order by sum(total_sales) desc) as ranking
from customers 
inner join orders on customers.customer_id = orders.customer_id
inner join order_items on orders.order_id = order_items.order_id
group by 1,2,3,4) as top_customers
where ranking = 1
order by 6 desc;

-- customers whose goods weren’t shipped or has been delayed

select orders.order_id,  
concat(first_name, ' ', last_name) as full_name,
product_name, 
quantity, 
required_date, 
shipped_date, 
coalesce(datediff(shipped_date, required_date),0) as delaying
from customers 
inner join orders on customers.customer_id = orders.customer_id
inner join order_items on orders.order_id = order_items.order_id
inner join products on order_items.product_id = products.product_id
where shipped_date is null or shipped_date > required_date 
order by 7;



# Analyzing sales by city

 with cities as(
 select state, 
 city,
 year(order_date) as year,
 sum(total_sales) as total_revenue,
 sum(quantity) as total_units
 from products
 inner join order_items on products.product_id = order_items.product_id
 inner join orders on orders.order_id = order_items.order_id
 inner join customers on orders.customer_id = customers.customer_id
 group by 1,2,3),
 
revenue as (
select state, 
city,
round(sum(case when year = '2021' then total_revenue else 0 end)) as 2021_year,
round(sum(case when year = '2022' then total_revenue else 0 end)) as 2022_year,
round(sum(case when year = '2023' then total_revenue else 0 end)) as 2023_year,
round(sum(total_revenue)) as total_revenue,
sum(total_units) as total_units
from cities
group by 1,2)

select *, 
round(sum(total_revenue) over (partition by city) / sum(total_revenue) over() * 100,2) as percentage_of_sales
from revenue
group by 1,2
order by 6 desc;



# Analyzing stocks 

-- inventory stock alerts

select stores.store_id,
store_name,
products.product_id,
product_name, 
stock_quantity as current_stock
from stocks
inner join products on stocks.product_id = products.product_id
inner join stores on stocks.store_id = stores.store_id
where stock_quantity = 0;

 
# Analyzing employees 

with sellers as(
select staffs.staff_id, 
store_name, 
concat(first_name, ' ', last_name) as full_name, 
def_order_status, 
sum(quantity) as total_quantity, 
round(sum(total_sales)) as total_sales
from staffs
left join stores on staffs.store_id = stores.store_id
inner join orders on staffs.staff_id = orders.staff_id 
inner join order_items on orders.order_id = order_items.order_id
group by 1, 2, 3, 4
order by 1)

select staff_id, 
store_name, 
full_name, 
sum(case when def_order_status = 'Completed' then total_quantity else 0 end) as complited_orders,
sum(case when def_order_status = 'Processing' then total_quantity else 0 end) as processing_orders,
sum(case when def_order_status = 'Pending' then total_quantity else 0 end) as pending_orders,
sum(case when def_order_status = 'Rejected' then total_quantity else 0 end) as rejected_orders,
round(sum(case when def_order_status = 'Completed' then total_quantity else 0 end)/sum(total_quantity) * 100) as succesful_sales_ratio,
sum(total_sales) as total_sales
from sellers
group by 1,2,3
order by 8 desc;



# Analyzing sales trends and sales growth rate

with a1 as(
select monthname(order_date) as month,
year(order_date) as year, 
round(sum(total_sales)) as total_sales,
sum(quantity) as total_units
from orders inner join 
order_items on orders.order_id = order_items.order_id
group by 1,2),

a2 as (
select month, year, 
total_sales as total_sales, 
total_units as total_units,
lag(total_sales, 1) over(order by year) as last_month_sale
from a1
group by 1,2)

select *,
round(100 - (last_month_sale/total_sales * 100),2) as sales_growth_rate
from a2;



# Create a procedure 

Delimiter $$

Create procedure update_sales
(in p_order_id int,
in p_item_id int, 
in p_customer_id int, 
in p_store_id int, 
in p_staff_id int,
in p_product_id int,
in p_quantity int,
in p_discount float,
out message varchar(100)
)

begin

	-- set variables

    declare v_count, v_price int;
    
    -- checking product in stock

     set v_count = (select sum(stock_quantity) 
		from stocks 
		where product_id = p_product_id and store_id = p_store_id);
        
    -- receiving price   
 
	set v_price = (select list_price
		from products
		where product_id = p_product_id);
    
	-- adding values into orders
        
	  if v_count > 0 then
		insert into orders(order_id, customer_id, order_date, store_id, staff_id)
		values (p_order_id, p_customer_id, current_date(), p_store_id, p_staff_id);
        
	-- adding values into order_items

       insert into order_items(order_id, item_id, product_id, quantity, list_price, discount, total_sales)
       values(p_order_id, p_item_id, p_product_id, p_quantity, v_price, p_discount, v_price * p_quantity);
        
	-- update stock table
        
		update stocks 
		set stock_quantity = stock_quantity - p_quantity
        where product_id = p_product_id and store_id = p_store_id;
        
		set message = 'Product has been added and stock has been updated';
        
	else 
		set message = 'This product is not available now';
	end if;
end 
$$  

Delimiter ;  

