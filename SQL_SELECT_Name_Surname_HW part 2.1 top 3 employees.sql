-- Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 

-- Assumptions: 
	-- staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
	-- if staff processed the payment then he works in the same store; 
	-- take into account only payment_date
	
WITH staff_revenue_2017 AS (
    SELECT
        p.staff_id,
        s.first_name || ' ' || s.last_name AS employee_name,
        SUM(p.amount) AS total_revenue,
        MAX(p.payment_date) AS last_payment_date
    FROM payment p
    JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY p.staff_id, s.first_name, s.last_name
),
latest_payment_store AS (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        s.store_id
    FROM payment p
    JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    ORDER BY p.staff_id, p.payment_date DESC
)
SELECT 
    sr.employee_name,
    sr.total_revenue,
    a.address || ', ' || a.district || ', ' || c.city || ', ' || a.postal_code AS store_address
FROM staff_revenue_2017 sr
JOIN latest_payment_store lps ON sr.staff_id = lps.staff_id
JOIN store st ON lps.store_id = st.store_id
JOIN address a ON st.address_id = a.address_id
JOIN city c ON a.city_id = c.city_id
ORDER BY sr.total_revenue DESC
LIMIT 3