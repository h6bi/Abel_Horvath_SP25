-- All animation movies	
	-- 	released between 2017-2019
	-- rate > 1
	-- sorted alphabetically
	
SELECT f.title, f.release_year, f.rental_rate, c.name AS category
FROM
public.film f 
LEFT OUTER JOIN public.film_category fc ON f.film_id = fc.film_id
LEFT OUTER JOIN public.category c ON fc.category_id = c.category_id
WHERE 
f.release_year BETWEEN 2017 AND 2019
AND
UPPER (name) = UPPER ('Animation')
AND
f.rental_rate > 1
ORDER BY title;

-- Revenue earned by each rental store after March 2017
	-- columns: address and address2 – as one column, revenue

SELECT 
    a.address || ' ' || COALESCE(a.address2, ' ') AS full_address, sr.revenue
FROM 
    (SELECT i.store_id, SUM(p.amount) AS revenue
     FROM public.payment p
     INNER JOIN public.rental r ON p.rental_id = r.rental_id
     INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
     WHERE p.payment_date >= '2017-04-01'
     GROUP BY i.store_id) sr
INNER JOIN public.store s ON sr.store_id = s.store_id 
INNER JOIN public.address a ON s.address_id = a.address_id;

-- Top-5 actors by number of movies (released after 2015) they took part in
-- There is a tie for the 2nd 3rd 4th and 5th most appearances, so I've listed them all

WITH nr_of_movies AS (
	SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
	FROM public.actor a
	LEFT OUTER JOIN public.film_actor fa ON a.actor_id = fa.actor_id 
	LEFT OUTER JOIN public.film f ON fa.film_id = f.film_id
	WHERE f.release_year > 2015
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
ORDER BY nrm.number_of_movies DESC;

-- Number of Drama, Travel, Documentary per year 
-- columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies 
-- sorted by release year in descending order.

WITH 
dramas AS (
	SELECT f.release_year, COUNT (c.name) AS number_of_drama_movies
	FROM public.film f 
	LEFT OUTER JOIN public.film_category fc 
	ON f.film_id = fc.film_id
	LEFT OUTER JOIN public.category c
	ON fc.category_id = c.category_id
	WHERE c.name = 'Drama'
	GROUP BY f.release_year),
	
travels AS (
	SELECT f.release_year, COUNT (c.name) AS number_of_travel_movies
	FROM public.film f 
	LEFT OUTER JOIN public.film_category fc 
	ON f.film_id = fc.film_id
	LEFT OUTER JOIN public.category c
	ON fc.category_id = c.category_id
	WHERE c.name = 'Drama'
	GROUP BY f.release_year),

docs AS (SELECT f.release_year, COUNT (c.name) AS number_of_documentary_movies
	FROM public.film f 
	LEFT OUTER JOIN public.film_category fc 
	ON f.film_id = fc.film_id
	LEFT OUTER JOIN public.category c 
	ON fc.category_id = c.category_id
	WHERE c.name = 'Documentary'
	GROUP BY f.release_year),

all_years AS (
	SELECT DISTINCT f.release_year
	FROM public.film f
	ORDER BY f.release_year DESC) -- to list all possible release dates for films in the DB

SELECT ay.*, COALESCE (dr.number_of_drama_movies, 0) AS number_of_drama_movies, COALESCE (t.number_of_travel_movies, 0) AS number_of_travel_movies, COALESCE (docs.number_of_documentary_movies, 0) AS number_of_documentary_movies
FROM all_years ay
LEFT OUTER JOIN dramas dr 
ON ay.release_year = dr.release_year
LEFT OUTER JOIN travels t 
ON ay.release_year = t.release_year
LEFT OUTER JOIN docs 
ON ay.release_year = docs.release_year;


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
    FROM public.payment p
    INNER JOIN public.staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY p.staff_id, s.first_name, s.last_name
),
latest_payment_store AS (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        i.store_id,
        p.payment_date
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id 
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    ORDER BY p.staff_id, p.payment_date DESC
)
SELECT 
    sr.employee_name,
    sr.total_revenue,
    a.address || ', ' || a.district || ', ' || c.city || ', ' || a.postal_code AS store_address
FROM staff_revenue_2017 sr
INNER JOIN latest_payment_store lps ON sr.staff_id = lps.staff_id
INNER JOIN public.store st ON lps.store_id = st.store_id
INNER JOIN public.address a ON st.address_id = a.address_id
INNER JOIN public.city c ON a.city_id = c.city_id
ORDER BY sr.total_revenue DESC
LIMIT 3;

-- Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
-- To determine expected age please use 'Motion Picture Association film rating system

WITH toprentals AS (
SELECT 
    f.title, COUNT(r.rental_id) AS rental_count,
    f.rating,
    CASE f.rating
        WHEN 'G' THEN 0
        WHEN 'PG' THEN 10
        WHEN 'PG-13' THEN 13
        WHEN 'R' THEN 17
        WHEN 'NC-17' THEN 18
        ELSE NULL
    END AS expected_audience_age
FROM public.rental r
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id
GROUP BY f.title, f.rating
ORDER BY rental_count DESC),

top5 AS (
SELECT DISTINCT toprentals.rental_count
FROM toprentals 
ORDER BY toprentals.rental_count DESC
LIMIT 5
)

SELECT *
FROM toprentals
WHERE toprentals.rental_count >= (SELECT MIN(top5.rental_count) FROM top5);

-- Which actors/actresses didn't act for a longer period of time than the others? 
	-- V1: gap between the latest release_year and current year per each actor
	
SELECT a.actor_id, a.first_name, a.last_name, 
	EXTRACT(YEAR FROM CURRENT_DATE) - MAX (f.release_year) AS gap
FROM public.actor a 
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY gap DESC;