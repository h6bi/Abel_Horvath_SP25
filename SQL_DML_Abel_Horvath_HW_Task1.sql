--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
--Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.
--Add your favorite movies to any store's inventory.
--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the first half of 2017)


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
           (SELECT language_id FROM public.language WHERE name = 'English'), 1, 4.99, 164, 'R'::mpaa_rating, ARRAY['Trailers', 'Commentaries']),
          ('Forrest Gump', 'The history of the United States from the 1950s to the 70s unfolds from the perspective of an Alabama man with an IQ of 75, who yearns to be reunited with his childhood sweetheart.', 1994, 
           (SELECT language_id FROM public.language WHERE name = 'English'), 2, 9.99, 162, 'PG-13'::mpaa_rating, ARRAY['Trailers', 'Commentaries']),
          ('Superhero Movie', 'Orphaned high school student Rick Riker is bitten by a radioactive dragonfly, develops super powers (except for the ability to fly), and becomes a hero.', 2008, 
           (SELECT language_id FROM public.language WHERE name = 'English'), 3, 19.99, 75, 'PG-13'::mpaa_rating, ARRAY['Trailers', 'Commentaries'])
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
)

INSERT INTO public.inventory (film_id, store_id)
SELECT film_id, store_id
FROM inserted_films
CROSS JOIN (SELECT store_id FROM public.store) AS stores
RETURNING inventory_id, film_id, store_id

UPDATE public.customer 
SET
    first_name = 'Abel',
    last_name = 'Horvath',
    email = 'horvathabel89@gmail.com',
    address_id = 598
WHERE UPPER(first_name) = UPPER('Dan') 
  AND UPPER(last_name) = UPPER('Paine')
RETURNING customer_id

DELETE FROM public.payment
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE UPPER(first_name) = UPPER('Abel')
      AND UPPER(last_name) = UPPER('Horvath')
)

DELETE FROM public.rental
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE UPPER(first_name) = UPPER('Abel')
      AND UPPER(last_name) = UPPER('Horvath')
)
