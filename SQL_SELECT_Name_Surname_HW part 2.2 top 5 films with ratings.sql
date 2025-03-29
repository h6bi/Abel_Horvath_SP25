-- Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
-- To determine expected age please use 'Motion Picture Association film rating system

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
FROM rental r
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film f ON i.film_id = f.film_id
GROUP BY f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;