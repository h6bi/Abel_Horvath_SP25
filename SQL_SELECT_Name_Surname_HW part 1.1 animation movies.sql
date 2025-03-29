-- All animation movies	
	-- 	released between 2017-2019
	-- rate > 1
	-- sorted alphabetically
	
SELECT f.title, f.release_year, f.rental_rate, c.name AS category
FROM
film f 
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id
WHERE 
release_year BETWEEN 2017 AND 2019
AND
name = 'Animation'
AND
rental_rate > 1
ORDER BY title
