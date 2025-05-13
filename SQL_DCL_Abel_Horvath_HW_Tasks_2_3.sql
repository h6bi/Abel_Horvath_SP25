-- Task 2:
--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
--Create a new user group called "rental" and add "rentaluser" to the group. 
--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
--Create a personalized role for any customer already existing in the dvd_rental database. 
	--The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. 

CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';

GRANT SELECT ON public.customer TO rentaluser;

SET ROLE rentaluser;

SELECT * FROM public.customer;

RESET ROLE;

CREATE ROLE rental;

GRANT INSERT, UPDATE ON public.rental TO rental;
-- I have to grant these priviliges to rental in order to use auto increment on rental_id in the insert operation
GRANT USAGE, SELECT, UPDATE ON SEQUENCE public.rental_rental_id_seq TO rental;

GRANT rental TO rentaluser;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (current_date::timestamptz, 1938, 234, 1);

UPDATE public.rental r
SET 
	rental_date = current_date::timestamptz,
	return_date = (current_date + 7)::timestamptz
WHERE r.rental_id = 44;

RESET ROLE;

REVOKE INSERT ON public.rental FROM rental;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (current_date::timestamptz, 1624, 132, 2);

RESET ROLE;

CREATE ROLE client_mary_smith LOGIN PASSWORD 'mary123';

-- Task 3:
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables.
-- Write a query to make sure this user sees only their own data.

ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.rental, public.payment TO client_mary_smith;

CREATE POLICY own_rental ON public.rental
TO client_mary_smith
USING (customer_id = 1);

CREATE POLICY own_payment ON public.payment
TO client_mary_smith
USING (customer_id = 1);

SET ROLE client_mary_smith;

SELECT * FROM public.rental;

SELECT * FROM public.payment;






