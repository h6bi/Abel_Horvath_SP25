-- Number of Drama, Travel, Documentary per year 
-- columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies 
-- sorted by release year in descending order.
WITH 
dramas AS (
	SELECT f.release_year, COUNT (c.name) AS number_of_drama_movies
	FROM film f 
	LEFT JOIN film_category fc 
	ON f.film_id = fc.film_id
	LEFT JOIN category c
	ON fc.category_id = c.category_id
	WHERE c.name = 'Drama'
	GROUP BY f.release_year),
	
travels AS (
	SELECT f.release_year, COUNT (c.name) AS number_of_travel_movies
	FROM film f 
	LEFT JOIN film_category fc 
	ON f.film_id = fc.film_id
	LEFT JOIN category c
	ON fc.category_id = c.category_id
	WHERE c.name = 'Drama'
	GROUP BY f.release_year),

docs AS (SELECT f.release_year, COUNT (c.name) AS number_of_documentary_movies
	FROM film f 
	LEFT JOIN film_category fc 
	ON f.film_id = fc.film_id
	LEFT JOIN category c 
	ON fc.category_id = c.category_id
	WHERE c.name = 'Documentary'
	GROUP BY f.release_year),

all_years AS (
	SELECT DISTINCT release_year
	FROM film
	ORDER BY release_year DESC) -- to list all possible release dates for films in the DB

SELECT ay.*, COALESCE (dr.number_of_drama_movies, 0) AS number_of_drama_movies, COALESCE (t.number_of_travel_movies, 0) AS number_of_travel_movies, COALESCE (docs.number_of_documentary_movies, 0) AS number_of_documentary_movies
FROM all_years ay
LEFT JOIN dramas dr 
ON ay.release_year = dr.release_year
LEFT JOIN travels t 
ON ay.release_year = t.release_year
LEFT JOIN docs 
ON ay.release_year = docs.release_year





