-- TASK 1
-- Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. 
-- The view should only display categories with at least one sale in the current quarter. 
-- Note: when the next quarter begins, it will be considered as the current quarter.

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT c.name AS category_name, SUM(p.amount) AS quarterly_revenue
FROM public.category c 
INNER JOIN public.film_category fc ON c.category_id = fc.category_id
INNER JOIN public.film f ON fc.film_id = f.film_id
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id 
INNER JOIN public.payment p ON r.rental_id = p.rental_id
WHERE EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM NOW())
  AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM NOW())
GROUP BY category_name;

SELECT * FROM sales_revenue_by_category_qtr;

-- TASK 2
-- Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter 
-- representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    p_year_quarter TEXT  -- expected format: 'YYYYQN', e.g., '2025Q2'
)
RETURNS TABLE (
    category_name TEXT,
    quarterly_revenue NUMERIC
)
AS $$
    SELECT 
        c.name AS category_name, 
        SUM(p.amount) AS quarterly_revenue
    FROM public.category c 
    INNER JOIN public.film_category fc ON c.category_id = fc.category_id
    INNER JOIN public.film f ON fc.film_id = f.film_id
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id 
    INNER JOIN public.payment p ON r.rental_id = p.rental_id
    WHERE EXTRACT(QUARTER FROM p.payment_date) = CAST(SUBSTRING(p_year_quarter FROM 6 FOR 1) AS INTEGER)
      AND EXTRACT(YEAR FROM p.payment_date) = CAST(SUBSTRING(p_year_quarter FROM 1 FOR 4) AS INTEGER)
    GROUP BY c.name
$$ LANGUAGE sql;

SELECT * FROM get_sales_revenue_by_category_qtr('2025Q2');

-- TASK 3
-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
-- The function should format the result set as follows:
     -- Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

CREATE OR REPLACE FUNCTION mostpop_film(p_countries TEXT[])
RETURNS TABLE("Country" TEXT, "Film" TEXT, "Rating" TEXT, "Language" TEXT, "Length" smallint, "Release year" year) AS $$
BEGIN
RETURN QUERY
WITH film_popularity AS (
    SELECT 
        co.country,
        f.film_id,
        COUNT(r.rental_id) AS popularity
    FROM public.country co
    INNER JOIN public.city ci ON co.country_id = ci.country_id
    INNER JOIN public.address a ON ci.city_id = a.city_id
    INNER JOIN public.store s ON a.address_id = s.address_id
    INNER JOIN public.inventory i ON s.store_id = i.store_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    WHERE UPPER(co.country) = ANY(SELECT UPPER(c) FROM unnest(p_countries) AS c)
    GROUP BY co.country, f.film_id
),
ranked_films AS (
    SELECT 
        country,
        film_id,
        popularity,
        RANK() OVER (PARTITION BY country ORDER BY popularity DESC) AS rnk
    FROM film_popularity
)
SELECT 
    rf.country AS "Country",
    f.title AS "Film",
    CAST(f.rating AS TEXT) AS "Rating",
    CAST(l.name AS TEXT) AS "Language",
    f.length AS "Length",
    f.release_year AS "Release year"
FROM ranked_films rf
INNER JOIN public.film f ON rf.film_id = f.film_id
INNER JOIN public.language l ON f.language_id = l.language_id
WHERE rf.rnk = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM mostpop_film(ARRAY['Australia', 'Canada', 'United States']);

--TASK 4
--Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
--The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, return a message indicating that it was not found.
--The function should produce the result set in the following format 
	--(note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100...).
	--Query (example):select * from core.films_in_stock_by_title('%love%’);

CREATE OR REPLACE FUNCTION films_in_stock_by_title(p_title TEXT)
RETURNS TABLE (
    Row_num INT,
    "Film title" TEXT,
    "Language" TEXT,
    "Customer name" TEXT,
    "Rental date" TIMESTAMP
) AS $$
BEGIN
RETURN QUERY
WITH available_inventory AS (
    SELECT i.inventory_id, f.film_id, f.title, l.name AS language
    FROM public.film f
    INNER JOIN public.language l ON f.language_id = l.language_id
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
    WHERE UPPER(f.title) LIKE UPPER(p_title)
    GROUP BY i.inventory_id, f.film_id, f.title, l.name
    HAVING bool_or(r.rental_id IS NULL OR r.return_date IS NOT NULL)
),
last_rentals AS (
    SELECT DISTINCT ON (ai.film_id)
        ai.film_id,
        ai.title,
        ai.language,
        c.first_name || ' ' || c.last_name AS customer_name,
        r.rental_date
    FROM available_inventory ai
    LEFT JOIN public.rental r ON ai.inventory_id = r.inventory_id
    LEFT JOIN public.customer c ON r.customer_id = c.customer_id
    ORDER BY ai.film_id, r.rental_date DESC
)
SELECT
    CAST (ROW_NUMBER() OVER (ORDER BY lr.title) AS int) AS Row_num,
    lr.title AS "Film title",
    CAST (lr.language AS text) AS "Language",
    lr.customer_name AS "Customer name",
    CAST (lr.rental_date AS timestamp) AS "Rental date"
FROM last_rentals lr;

-- If no matching films are found
IF NOT FOUND THEN
    RAISE NOTICE 'No films matching the pattern % are currently in stock.', p_title;
END IF;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM films_in_stock_by_title('%gun%');

-- TASK 5
-- Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table.
-- The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
-- The release year and language are optional and by default should be current year and Klingon respectively. 
	-- The function should also verify that the language exists in the 'language' table. 
-- Then, ensure that no such function has been created before; if so, replace it.


CREATE OR REPLACE FUNCTION new_movie(
    p_title TEXT,
    p_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_language_name TEXT DEFAULT 'Klingon'
)
RETURNS TABLE (
    film_id INT,
    title TEXT,
    release_year YEAR,
    language TEXT,
    rental_rate NUMERIC,
    rental_duration SMALLINT,
    replacement_cost NUMERIC
) AS $$
DECLARE
    v_language_id INT;
    v_language_name TEXT;
    v_film_id INT;
BEGIN
    -- Attempt to find the language ID for the provided language name
    SELECT lang.language_id
    INTO v_language_id
    FROM public.language lang
    WHERE lang.name = p_language_name;

    -- If the provided language is not found, use English instead
    IF NOT FOUND THEN
        RAISE NOTICE 'Language "%" not found. Falling back to English.', p_language_name;

        SELECT lang.language_id
        INTO v_language_id
        FROM public.language lang
        WHERE lang.name = 'English';

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Fallback language "English" not found in the language table.';
        END IF;

        v_language_name := 'English';
    ELSE
        v_language_name := p_language_name;
    END IF;

    -- Check if a film with the same title already exists
    PERFORM 1
    FROM public.film existing_film
    WHERE UPPER(existing_film.title) = UPPER(p_title);

    IF FOUND THEN
        RAISE EXCEPTION 'A film with the title "%" already exists.', p_title;
    END IF;

    -- Inserting new film
    INSERT INTO public.film (
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost
    )
    VALUES (
        p_title,
        p_release_year,
        v_language_id,
        3,
        4.99,
        19.99
    )
    RETURNING film.film_id INTO v_film_id;

    -- Returns the inserted film details
    RETURN QUERY
    SELECT 
        inserted_film.film_id,
        inserted_film.title,
        inserted_film.release_year,
        v_language_name AS language,
        inserted_film.rental_rate,
        inserted_film.rental_duration,
        inserted_film.replacement_cost
    FROM public.film inserted_film
    WHERE inserted_film.film_id = v_film_id;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM new_movie('Blade Runner');






