-- Create Database Pizza_Data_31102024

--USE Pizza_Data_31102024

--Select *
--from dbo.order_details

--Select *
--from dbo.orders

--Select *
--from dbo.pizza_types

--Select *
--from dbo.pizzas

-- Retrieve the total number of orders placed.
SELECT count(*) AS total_orders
FROM dbo.orders

-- Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(od.quantity * p.price), 2) AS Total_Revenue
FROM dbo.pizzas p
JOIN dbo.order_details od ON p.pizza_id = od.pizza_id

-- Identify the highest-priced pizza
SELECT TOP 1 pt.name
	,ROUND(MAX(p.price), 2) AS 'price'
FROM dbo.pizzas p
JOIN dbo.pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY Max(p.price) DESC

-- Identify the most common pizza size ordered.

SELECT p.size
	,count(od.order_details_id) AS count_of_pizzas_ordered
FROM dbo.pizzas p
JOIN dbo.order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY count(od.order_details_id) DESC

-- List the top 5 most ordered pizza types along with their quantities.

SELECT TOP 5 p.pizza_type_id, pt.name
	,sum(od.quantity) AS quantity_of_pizzas_ordered
FROM dbo.pizzas p
Join dbo.pizza_types pt on p.pizza_type_id = pt.pizza_type_id
JOIN dbo.order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.pizza_type_id, pt.name
ORDER BY sum(od.quantity) DESC

-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pt.category
	,sum(od.quantity) AS quantity_of_pizzas
FROM dbo.pizza_types pt
JOIN dbo.pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN dbo.order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category
ORDER BY sum(od.quantity) DESC

-- Determine the distribution of orders by hour of the day.

SELECT DATEPART(HOUR, o.TIME) AS [number_of_hours]
	,COUNT(o.order_id) AS [count_of_orders]
FROM dbo.orders o
GROUP BY DATEPART(HOUR, o.TIME)
ORDER BY count_of_orders DESC

-- Join relevant tables to find the category-wise distribution of pizzas.

SELECT pt.category
	,count(pt.name) AS 'count'
FROM dbo.pizza_types pt
GROUP BY pt.category
ORDER BY count(pt.name) DESC

-- Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT avg(total_orders) as 'Average number of pizzas ordered per day'
FROM (
	SELECT o.DATE
		,sum(od.quantity) AS 'total_orders'
	FROM dbo.orders o
	JOIN dbo.order_details od ON o.order_id = od.order_id
	GROUP BY o.DATE
	) AS ordered_qty

--Determine the top 3 most ordered pizza types based on revenue.

SELECT TOP 3 pt.name
	,ROUND(SUM(od.quantity * p.price), 0) AS Revenue
FROM dbo.order_details od
JOIN dbo.pizzas p ON od.pizza_id = p.pizza_id
JOIN dbo.pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY Revenue DESC

-- Calculate the percentage contribution of each pizza type to total revenue.

SELECT pt.category
	,Round((
			SUM(od.quantity * p.price) / (
				SELECT SUM(od.quantity * p.price)
				FROM dbo.order_details od
				JOIN dbo.pizzas p ON p.pizza_id = od.pizza_id
				) * 100
			), 2) AS 'Revenue %'
FROM dbo.pizza_types pt
JOIN dbo.pizzas p ON p.pizza_type_id = pt.pizza_type_id
JOIN dbo.order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category
ORDER BY [Revenue %] DESC

--Analyze the cumulative revenue generated over time.

SELECT sales.DATE
	,sum(revenue) OVER (
		ORDER BY sales.DATE
		) AS cumu_rev
FROM (
	SELECT o.DATE
		,sum(od.quantity * p.price) AS revenue
	FROM dbo.order_details od
	JOIN dbo.pizzas p ON od.pizza_id = p.pizza_id
	JOIN dbo.orders o ON o.order_id = od.order_id
	GROUP BY o.DATE
	) AS sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT name
	,category
	,Revenue
FROM (
	SELECT category
		,name
		,Revenue
		,rank() OVER (
			PARTITION BY category ORDER BY revenue DESC
			) AS rn
	FROM (
		SELECT pt.category
			,pt.name
			,SUM(od.quantity * p.price) AS Revenue
		FROM dbo.pizza_types pt
		JOIN dbo.pizzas p ON pt.pizza_type_id = p.pizza_type_id
		JOIN order_details od ON p.pizza_id = od.pizza_id
		GROUP BY pt.category
			,pt.name
		) AS a
	) AS b
WHERE rn <= 3
ORDER BY category ASC
	,Revenue DESC