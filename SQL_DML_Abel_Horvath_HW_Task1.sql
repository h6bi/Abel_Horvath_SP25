BEGIN;
--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
--Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

WITH inserted_films AS (
    INSERT INTO public.film (
        title, 
        description, 
        release_year, 
        language_id, 
        rental_duration, 
        rental_rate, 
        length, 
        rating, 
        special_features
    )
    SELECT title, 
           description, 
           release_year, 
           language_id, 
           rental_duration, 
           rental_rate, 
           length, 
           rating, 
           special_features
    FROM (
        VALUES 
          ('Blade Runner 2049', 'Young Blade Runner K discovers a long-buried secret that leads him to track down former Blade Runner Rick Deckard, who has been missing for thirty years.', 2017, 
           (SELECT language_id FROM public.language WHERE UPPER (name) = 'ENGLISH'), 1, 4.99, 164, 'R'::mpaa_rating, ARRAY['Trailers', 'Commentaries']),
          ('Forrest Gump', 'The history of the United States from the 1950s to the 70s unfolds from the perspective of an Alabama man with an IQ of 75, who yearns to be reunited with his childhood sweetheart.', 1994, 
           (SELECT language_id FROM public.language WHERE UPPER (name) = 'ENGLISH'), 2, 9.99, 162, 'PG-13'::mpaa_rating, ARRAY['Trailers', 'Commentaries']),
          ('Superhero Movie', 'Orphaned high school student Rick Riker is bitten by a radioactive dragonfly, develops super powers (except for the ability to fly), and becomes a hero.', 2008, 
           (SELECT language_id FROM public.language WHERE UPPER (name) = 'ENGLISH'), 3, 19.99, 75, 'PG-13'::mpaa_rating, ARRAY['Trailers', 'Commentaries'])
    ) AS new_films (title, description, release_year, language_id, rental_duration, rental_rate, length, rating, special_features)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.film f WHERE f.title = new_films.title
    )
    RETURNING film_id, title
),
inserted_actors AS (
    INSERT INTO public.actor (first_name, last_name)
    SELECT first_name, last_name
    FROM (
        VALUES 
        ('Ryan', 'Gosling'),
        ('Harrison', 'Ford'),
        ('Tom', 'Hanks'),
        ('Gary', 'Sinise'),
        ('Leslie', 'Nielsen'),
        ('Kevin', 'Hart')
    ) AS new_actors (first_name, last_name)
    WHERE NOT EXISTS (
        SELECT a.first_name, a.last_name
        FROM public.actor a
        WHERE a.first_name = new_actors.first_name
        AND a.last_name = new_actors.last_name
    )
    RETURNING actor_id
),
film_with_row_num AS (
    SELECT film_id, ROW_NUMBER() OVER () AS row_num
    FROM inserted_films
),
actor_with_row_num AS (
    SELECT actor_id, ROW_NUMBER() OVER () AS row_num
    FROM inserted_actors
),
film_actor_insert AS (
    INSERT INTO public.film_actor (film_id, actor_id)
    SELECT f.film_id, a.actor_id
    FROM film_with_row_num f
    JOIN actor_with_row_num a 
    ON (a.row_num - 1) / 2 + 1 = f.row_num
    RETURNING film_id, actor_id
),

--Add your favorite movies to any store's inventory.

inventory_insert AS (
    INSERT INTO public.inventory (film_id, store_id)
    SELECT film_id, store_id
    FROM inserted_films
    CROSS JOIN (SELECT store_id FROM public.store) AS stores
    RETURNING inventory_id, film_id, store_id
),


--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

updated_customer AS (
    UPDATE public.customer 
    SET
        first_name = 'Abel',
        last_name = 'Horvath',
        email = 'horvathabel89@gmail.com',
        address_id = 598
    WHERE customer_id = (
        SELECT c.customer_id
        FROM public.customer c
        INNER JOIN public.rental r ON c.customer_id = r.customer_id
        INNER JOIN public.payment p ON r.rental_id = p.rental_id
        GROUP BY c.customer_id
        HAVING COUNT(r.rental_id) >= 43
           AND COUNT(p.payment_id) >= 43
        LIMIT 1
    )
    RETURNING customer_id
),

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'

delete_payments AS (
    DELETE FROM public.payment
    WHERE rental_id IN (
        SELECT r.rental_id
        FROM public.rental r
        WHERE r.customer_id = (SELECT customer_id FROM updated_customer)
    )
    RETURNING *
),
delete_rentals AS (
    DELETE FROM public.rental
    WHERE customer_id = (SELECT customer_id FROM updated_customer)
    RETURNING *
)

SELECT 1;


--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the first half of 2017)
	-- I added records for 2017

WITH fav_rent1 AS (
INSERT INTO public.rental (
    rental_date, 
    inventory_id, 
    customer_id, 
    return_date, 
    staff_id
)
VALUES (
    '2017-04-11'::timestamptz,
    (SELECT i.inventory_id 
     FROM public.inventory i 
     WHERE i.film_id = (
         SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = 'BLADE RUNNER 2049' 
         LIMIT 1)
     LIMIT 1),
    (SELECT c.customer_id
     FROM public.customer c
     WHERE UPPER(c.first_name) = 'ABEL' 
       AND UPPER(c.last_name) = 'HORVATH'
     LIMIT 1),
    '2017-04-11'::timestamptz + INTERVAL '7 days',
    (SELECT s.staff_id
     FROM public.staff s
     WHERE s.store_id = (
         SELECT i.store_id
         FROM public.inventory i
         JOIN public.film f ON i.film_id = f.film_id
         WHERE UPPER(f.title) = 'BLADE RUNNER 2049'
         LIMIT 1)
     LIMIT 1))
RETURNING rental_id, rental_date, inventory_id, customer_id, return_date, staff_id),

fav_rent2 AS (
INSERT INTO public.rental (
    rental_date, 
    inventory_id, 
    customer_id, 
    return_date, 
    staff_id)
VALUES (
 '2017-04-11'::timestamptz,
    (SELECT i.inventory_id 
     FROM public.inventory i 
     WHERE i.film_id = (
         SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = 'FORREST GUMP' 
         LIMIT 1)
     LIMIT 1),
    (SELECT c.customer_id
     FROM public.customer c
     WHERE UPPER(c.first_name) = 'ABEL' 
       AND UPPER(c.last_name) = 'HORVATH'
     LIMIT 1),
    '2017-04-11'::timestamptz + INTERVAL '7 days',
    (SELECT s.staff_id
     FROM public.staff s
     WHERE s.store_id = (
         SELECT i.store_id
         FROM public.inventory i
         JOIN public.film f ON i.film_id = f.film_id
         WHERE UPPER(f.title) = 'FORREST GUMP'
         LIMIT 1)
     LIMIT 1)	
  )
  RETURNING rental_id, rental_date, inventory_id, customer_id, return_date, staff_id),
  
 fav_rent3 AS (
INSERT INTO public.rental (
    rental_date, 
    inventory_id, 
    customer_id, 
    return_date, 
    staff_id)
VALUES (
  '2017-04-11'::timestamptz,
    (SELECT i.inventory_id 
     FROM public.inventory i 
     WHERE i.film_id = (
         SELECT f.film_id
         FROM public.film f
         WHERE UPPER(f.title) = 'SUPERHERO MOVIE' 
         LIMIT 1)
     LIMIT 1),
    (SELECT c.customer_id
     FROM public.customer c
     WHERE UPPER(c.first_name) = 'ABEL' 
       AND UPPER(c.last_name) = 'HORVATH'
     LIMIT 1),
    '2017-04-11'::timestamptz + INTERVAL '7 days',
    (SELECT s.staff_id
     FROM public.staff s
     WHERE s.store_id = (
         SELECT i.store_id
         FROM public.inventory i
         JOIN public.film f ON i.film_id = f.film_id
         WHERE UPPER(f.title) = 'SUPERHERO MOVIE'
         LIMIT 1)
     LIMIT 1)
     )
 RETURNING rental_id, rental_date, inventory_id, customer_id, return_date, staff_id)


INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
VALUES 
(
(SELECT fav_rent1.customer_id FROM fav_rent1),
(SELECT fav_rent1.staff_id FROM fav_rent1),
(SELECT fav_rent1.rental_id FROM fav_rent1),
(SELECT f.rental_rate FROM fav_rent1
INNER JOIN public.inventory i ON fav_rent1.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id)
*
(SELECT EXTRACT(DAY FROM ((SELECT fav_rent1.return_date FROM fav_rent1) - (SELECT fav_rent1.rental_date FROM fav_rent1)))::int),
(SELECT fav_rent1.return_date FROM fav_rent1)),

(
(SELECT fav_rent2.customer_id FROM fav_rent2),
(SELECT fav_rent2.staff_id FROM fav_rent2),
(SELECT fav_rent2.rental_id FROM fav_rent2),
(SELECT f.rental_rate FROM fav_rent2
INNER JOIN public.inventory i ON fav_rent2.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id)
*
(SELECT EXTRACT(DAY FROM ((SELECT fav_rent2.return_date FROM fav_rent2) - (SELECT fav_rent2.rental_date FROM fav_rent2)))::int),
(SELECT fav_rent2.return_date FROM fav_rent2)),

(
(SELECT fav_rent3.customer_id FROM fav_rent3),
(SELECT fav_rent3.staff_id FROM fav_rent3),
(SELECT fav_rent3.rental_id FROM fav_rent3),
(SELECT f.rental_rate FROM fav_rent3
INNER JOIN public.inventory i ON fav_rent3.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id)
*
(SELECT EXTRACT(DAY FROM ((SELECT fav_rent3.return_date FROM fav_rent3) - (SELECT fav_rent3.rental_date FROM fav_rent3)))::int),
(SELECT fav_rent3.return_date FROM fav_rent3))

RETURNING *;

COMMIT;
