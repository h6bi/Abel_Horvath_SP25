-- Which actors/actresses didn't act for a longer period of time than the others? 
	-- V1: gap between the latest release_year and current year per each actor
	
SELECT a.actor_id, a.first_name, a.last_name, 
	EXTRACT(YEAR FROM CURRENT_DATE) - MAX (f.release_year) AS gap
FROM actor a 
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY gap DESC