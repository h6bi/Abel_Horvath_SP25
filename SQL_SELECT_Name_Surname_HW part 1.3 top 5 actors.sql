-- Top-5 actors by number of movies (released after 2015) they took part in
-- There is a tie for the 2nd 3rd 4th and 5th most appearances, so I've listed them all
WITH nr_of_movies AS (
	SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
	FROM actor a
	LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id 
	LEFT JOIN film f ON fa.film_id = f.film_id
	WHERE release_year > 2015
	GROUP BY a.actor_id, a.first_name, a.last_name
),
top5_distinct AS (
	SELECT DISTINCT number_of_movies
	FROM nr_of_movies
	ORDER BY number_of_movies DESC
	LIMIT 5
)
SELECT nrm.first_name, nrm.last_name, nrm.number_of_movies
FROM nr_of_movies nrm
WHERE nrm.number_of_movies >= (SELECT MIN(number_of_movies) FROM top5_distinct)
ORDER BY nrm.number_of_movies DESC