-- Revenue earned by each rental store after March 2017
	-- columns: address and address2 – as one column, revenue
	
SELECT s_address.address || ' ' || COALESCE (s_address.address2, '') AS full_address, SUM (p.amount) AS revenue
    FROM
	(SELECT s.store_id, a.address, a.address2, st.staff_id
    FROM staff AS st
    LEFT JOIN store AS s ON st.store_id = s.store_id
    LEFT JOIN address AS a ON s.address_id = a.address_id
) AS s_address LEFT JOIN payment p ON p.staff_id = s_address.staff_id
WHERE
payment_date >= '2017-04-01'
GROUP BY full_address
