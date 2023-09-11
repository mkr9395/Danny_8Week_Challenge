################################## week -> 1 : questions ########################################################

#### JOINING ALL TABLES:
select s.*,m.product_name,m.price,mem.join_date from sales as s
JOIN menu as m
ON s.product_id = m.product_id
JOIN members as mem
ON mem.customer_id=s.customer_id;

# 1. What is the total amount each customer spent at the restaurant?

select s.customer_id,
SUM(price) 
from sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY customer_id;

# 2. How many days has each customer visited the restaurant?

select s.customer_id,
COUNT(DISTINCT order_date) 
from sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY customer_id;

# 3. What was the first item from the menu purchased by each customer?

select DISTINCT customer_id,product_name 
from 
  (select s.*,m.product_name,
  RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as rank_date
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id) as 
t
WHERE t.rank_date=1;

# 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name,
COUNT(product_name) 
from sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(product_name) DESC
LIMIT 1;

# 5. Which item was the most popular for each customer?
 with cte as  (
  select  s.customer_id, m.product_name,
  COUNT(s.product_id) as order_times,
  RANK() OVER(partition by s.customer_id ORDER BY (COUNT(s.product_id)) DESC) as rank_item
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  GROUP BY s.customer_id,m.product_name) 
  
  select customer_id,product_name from cte
  WHERE cte.rank_item=1;

# 6. Which item was purchased first by the customer after they became a member?

with cte as 
  (select s.*,m.product_name,m.price,mem.join_date,
  RANK() over(PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rank_date
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  JOIN members as mem
  ON mem.customer_id=s.customer_id
  WHERE s.order_date >= mem.join_date
  ORDER BY s.order_date ASC)
  
SELECT customer_id,product_name
from cte
WHERE rank_date=1;

# 7. Which item was purchased just before the customer became a member?

with cte as 
  (select s.*,m.product_name,m.price,mem.join_date,
  RANK() over(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank_date
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  JOIN members as mem
  ON mem.customer_id=s.customer_id
  WHERE s.order_date < mem.join_date)
  
SELECT customer_id,product_name
from cte
WHERE rank_date=1;

# 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,
  SUM(price) as total_spent,
  COUNT(product_name) as number_of_items_oredered
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  JOIN members as mem
  ON mem.customer_id=s.customer_id
  WHERE s.order_date < mem.join_date
  GROUP BY s.customer_id 
  ORDER BY s.customer_id;

# 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(points) as total_points
from
  (select s.customer_id, s.product_id,m.product_name,
  CASE
    WHEN product_name = 'sushi' THEN price*20
    ELSE price*10
  END as points
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id) as 
t
GROUP BY t.customer_id;

# 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
#      not just sushi - how many points do customer A and B have at the end of January?

select t.customer_id, 
SUM(t.points) as total_points_earned
FROM
  (select s.customer_id,m.product_name,m.price,mem.join_date,
  DATE_ADD(join_date,INTERVAL 6 DAY) as week_after,
  CASE
    WHEN order_date BETWEEN join_date AND DATE_ADD(join_date,INTERVAL 6 DAY) THEN price*20
    WHEN product_name = 'sushi' THEN price * 20 
    ELSE price*10
  END AS points
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  JOIN members as mem
  ON mem.customer_id=s.customer_id
  WHERE MONTH(order_date)=1
  ORDER BY customer_id,points) as 
t
GROUP BY t.customer_id;



############ BONUS questions

## bq-1: Join All The Things

select s.customer_id,s.order_date,m.product_name,m.price,
CASE 
  WHEN s.order_date >= mem.join_date THEN "Y"
  ELSE "N"
END as memebr
from sales as s
JOIN menu as m
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON mem.customer_id=s.customer_id
ORDER BY customer_id,order_date;

## bq-2 : Rank All The Things

with cte as 
  (select s.customer_id,s.order_date,m.product_name,m.price,
    CASE 
      WHEN s.order_date >= mem.join_date THEN "Y"
      ELSE "N"
    END as memeber,
    ROW_NUMBER() over() as rn
  from sales as s
  JOIN menu as m
  ON s.product_id = m.product_id
  LEFT JOIN members as mem
  ON mem.customer_id=s.customer_id
  ORDER BY customer_id,order_date),


cte2 as 
  (select cte.customer_id, cte.order_date,cte.product_name,cte.rn,
  RANK() OVER(PARTITION BY cte.customer_id ORDER BY cte.order_date ASC) as ranking
  from cte
  WHERE memeber='Y')

select cte.customer_id, cte.order_date,cte.product_name,cte2.ranking 
from cte
LEFT JOIN cte2
ON (cte.rn=cte2.rn);


################################################ END ##################################################################

WITH CTE AS (
  SELECT 
    S.customer_id, 
    S.order_date, 
    product_name, 
    price, 
    CASE 
      WHEN join_date IS NULL THEN 'N'
      WHEN order_date < join_date THEN 'N'
      ELSE 'Y' 
    END as member 
  FROM 
    SALES as S 
    INNER JOIN MENU AS M ON S.product_id = M.product_id
    LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id
  ORDER BY 
    customer_id, 
    order_date, 
    price DESC
)
SELECT 
  *
  ,CASE 
    WHEN member = 'N'  THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)  
  END as rnk
FROM CTE;