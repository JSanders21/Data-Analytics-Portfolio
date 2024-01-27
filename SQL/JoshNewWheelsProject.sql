USE newwheels;
Select * from customer_t limit 10;
select * from order_t limit 10;
select * from product_t limit 10;
select * from shipper_t limit 10;

-- Question 1. What is the distribution of customers across states? 
-- I'm selecting the state column and counting the total customers from each state and naming that column "total_customers" from the customer table, then I'm grouping it by state and ordering it from largest to smallest by customer count.
select state, count(customer_id) AS total_customers
from customer_t
group by state
order by total_customers desc;

-- Question 2. What is the average rating in each quarter? 
-- Here I called a CTE as avgratingtable to use a case statement to change the string feedback data into a float numerical rating so that I could then average it, group it, and order it by quarter.
with avgratingtable as (
select quarter_number, 
case customer_feedback
	when 'Very Bad' then 1
    when 'Bad' then 2
    when 'Okay' then 3
    when 'Good' then 4
    when 'Very Good' then 5
end as avgrating
from order_t
)
select quarter_number, avg(avgrating) as average_rating
from avgratingtable
group by quarter_number
order by quarter_number;

-- Question 3. Are customers getting more dissatisfied over time?
with avgratingtable as (
    select quarter_number, count(*) as total_feedback,
        sum(case when customer_feedback = 'very bad' then 1 else 0 end) as very_bad_count,
        sum(case when customer_feedback = 'bad' then 1 else 0 end) as bad_count,
        sum(case when customer_feedback = 'okay' then 1 else 0 end) as okay_count,
        sum(case when customer_feedback = 'good' then 1 else 0 end) as good_count,
        sum(case when customer_feedback = 'very good' then 1 else 0 end) as very_good_count
    from order_t
    group by quarter_number
)
select quarter_number,
    round((very_bad_count / total_feedback) * 100,2) as percentage_very_bad,
    round((bad_count / total_feedback) * 100,2) as percentage_bad,
    round((okay_count / total_feedback) * 100,2) as percentage_okay,
    round((good_count / total_feedback) * 100,2) as percentage_good,
    round((very_good_count / total_feedback) * 100,2) as percentage_very_good
from avgratingtable
order by quarter_number;

-- Question 4. Which are the top 5 vehicle makers preferred by the customer?
-- Here I joined three tables together to link the data. order_t to customer_t on the customer_id key, and then to product_t on the product_id key.
-- Then I grouped it by vehicle maker from the product table and ordered it by customer count from the customer_t table in descending order to only show the top 5 vehicle makers with the most customers.
select p.vehicle_maker, count(*) as customer_count
from customer_t as c
join order_t as o on c.customer_id = o.customer_id
join product_t as p on o.product_id = p.product_id
group by p.vehicle_maker
order by customer_count desc
limit 5;

-- Question 5. What is the most preferred vehicle make in each state?
-- I used a window function inside of a cte to rank the vehicle makers by state by counting the orders from the order table and joining it to the customer table and the product table.
with rankedautomakers AS (
    select state, vehicle_maker, count(*) as customer_count,
	rank() over (partition by state order by COUNT(*) desc) as rank_per_state
    from customer_t c
    join order_t o on c.customer_id = o.customer_id
    join product_t p on o.product_id = p.product_id
    group by state, vehicle_maker
)

select state, vehicle_maker
from rankedautomakers
where rank_per_state = 1;

-- Question 6. What is the trend of number of orders by quarter? The trend is a declining number of orders per quarter.
select quarter_number, count(*) as total_orders
from order_t
group by quarter_number
order by quarter_number;

-- Question 7. What is the quarter over quarter % change in revenue? 
with quarterlyrevenue as (
    select quarter_number, round(sum(o.quantity * p.vehicle_price), 2) as total_revenue
    from order_t o
    join product_t p on o.product_id = p.product_id
    group by quarter_number
)
select
    round(qr.quarter_number, 2) AS quarter_number,
    round(qr.total_revenue, 2) AS current_quarter_revenue,
    round(lag(qr.total_revenue) over (order by qr.quarter_number), 2) as last_quarter_revenue,
    round(((qr.total_revenue - lag(qr.total_revenue) over (order by qr.quarter_number)) / lag(qr.total_revenue) over (order by qr.quarter_number)) * 100, 2) as qoq_percentage_change
from quarterlyrevenue qr
order by qr.quarter_number;

-- Question 8. What is the trend of revenue and orders by quarter? Both are decreasing probably due to longer shipping times and higher customer dissatisfaction.
select quarter_number, round(sum(o.quantity * p.vehicle_price), 2) as total_revenue,
count(*) as total_orders
from order_t o
join product_t p on o.product_id = p.product_id
group by quarter_number
order by quarter_number;

-- Question 9. What is the average discount offered for different types of credit cards?
select c.credit_card_type, round(avg(o.discount) * 100, 2) as average_discount_percentage
from order_t o
join customer_t c on o.customer_id = c.customer_id
group by c.credit_card_type;

-- Question 10. What is the average time taken to ship the placed orders for each quarter?
select quarter_number, round(avg(datediff(ship_date, order_date)), 2) as average_ship_time_in_days
from order_t
group by quarter_number
order by quarter_number;




