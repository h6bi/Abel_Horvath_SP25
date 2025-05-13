/* 3. Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
Create relationships between tables using primary and foreign keys.
Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 
	date to be inserted, which must be greater than January 1, 2024
	inserted measured value that cannot be negative
	inserted value that can only be a specific value
	unique
	not null

Give meaningful names to your CHECK constraints. 
Use appropriate data types for each column and apply DEFAULT, STORED AS and GENERATED ALWAYS AS columns as required. */


DROP DATABASE IF EXISTS appliance_store;

CREATE DATABASE appliance_store;

-- connect to appliance_store DB, then:

CREATE SCHEMA IF NOT EXISTS main;

-- Creating tables with primary key, foreign key and NOT NULL constraints:

CREATE TABLE IF NOT EXISTS main.customer (
    "customer_id" bigserial NOT NULL PRIMARY KEY,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "create_date" DATE NOT NULL DEFAULT current_date
);

CREATE TABLE IF NOT EXISTS main.country (
    "country_id" SERIAL NOT NULL PRIMARY KEY,
    "country_name" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS main.city (
    "city_id" SERIAL NOT NULL PRIMARY KEY,
    "city_name" TEXT NOT NULL,
    "country_id" INTEGER NOT NULL,
    CONSTRAINT "city_country_id_fk" FOREIGN KEY ("country_id") REFERENCES main.country("country_id")
);

CREATE TABLE IF NOT EXISTS main.address (
    "address_id" SERIAL NOT NULL PRIMARY KEY,
    "address" TEXT NOT NULL,
    "city_id" INTEGER NOT NULL,
    "postal_code" INTEGER NOT NULL,
    CONSTRAINT "address_city_id_fk" FOREIGN KEY ("city_id") REFERENCES main.city("city_id")
);

CREATE TABLE IF NOT EXISTS main.staff_role (
    "role_id" SERIAL NOT NULL PRIMARY KEY,
    "role_name" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS main.brand (
    "brand_id" SERIAL NOT NULL PRIMARY KEY,
    "brand_name" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS main.category (
    "category_id" SERIAL NOT NULL PRIMARY KEY,
    "category_name" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS main.type (
    "type_id" SERIAL NOT NULL PRIMARY KEY,
    "type_name" TEXT NOT NULL,
    "category_id" INTEGER NOT NULL,
    CONSTRAINT "type_category_id_fk" FOREIGN KEY ("category_id") REFERENCES main.category("category_id")
);

CREATE TABLE IF NOT EXISTS main.model (
    "model_id" SERIAL NOT NULL PRIMARY KEY,
    "model_name" TEXT NOT NULL,
    "brand_id" INTEGER NOT NULL,
    "colour" TEXT NOT NULL,
    "release_year" INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    CONSTRAINT "model_brand_id_fk" FOREIGN KEY ("brand_id") REFERENCES main.brand("brand_id")
);

CREATE TABLE IF NOT EXISTS main.product (
    "product_id" bigserial NOT NULL PRIMARY KEY,
    "type_id" INTEGER NOT NULL,
    "model_id" INTEGER NOT NULL,
    "price" DECIMAL(8, 2) NOT NULL,
    CONSTRAINT "product_model_id_fk" FOREIGN KEY ("model_id") REFERENCES main.model("model_id"),
    CONSTRAINT "product_type_id_fk" FOREIGN KEY ("type_id") REFERENCES main.type("type_id")
);

-- Creating staff and store tables without foreign key constraints as they reference each other:

CREATE TABLE IF NOT EXISTS main.staff (
    "staff_id" SERIAL NOT NULL PRIMARY KEY,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone_number" TEXT NOT NULL,
    "address_id" INTEGER NOT NULL,
    "store_id" INTEGER NOT NULL,
    "role_id" INTEGER NOT NULL,
    CONSTRAINT "staff_address_id_fk" FOREIGN KEY ("address_id") REFERENCES main.address("address_id"),
    CONSTRAINT "staff_role_id_fk" FOREIGN KEY ("role_id") REFERENCES main.staff_role("role_id")
);

CREATE TABLE IF NOT EXISTS main.store (
    "store_id" SERIAL NOT NULL PRIMARY KEY,
    "manager_staff_id" INTEGER, -- no not null constraint, as it is only known after hiring someone to be manager
    "address_id" INTEGER NOT NULL,
    CONSTRAINT "store_address_id_fk" FOREIGN KEY ("address_id") REFERENCES main.address("address_id")
);

-- Adding foreign key constraint for staff and store tables using ALTER TABLE commands (wrapped in DO block for reusability)

DO $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'main' 
        AND tc.table_name = 'staff' 
        AND tc.constraint_name = 'staff_store_id_fk'
    ) THEN
        ALTER TABLE main.staff
            ADD CONSTRAINT "staff_store_id_fk" FOREIGN KEY ("store_id") REFERENCES main.store("store_id");
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'main' 
        AND tc.table_name = 'store' 
        AND tc.constraint_name = 'store_manager_staff_id_fk'
    ) THEN
        ALTER TABLE main.store
            ADD CONSTRAINT "store_manager_staff_id_fk" FOREIGN KEY ("manager_staff_id") REFERENCES main.staff("staff_id");
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'main' 
        AND tc.table_name = 'staff' 
        AND tc.constraint_name = 'staff_address_id_fk'
    ) THEN
        ALTER TABLE main.staff
            ADD CONSTRAINT "staff_address_id_fk" FOREIGN KEY ("address_id") REFERENCES main.address("address_id");
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        WHERE tc.table_schema = 'main' 
        AND tc.table_name = 'store' 
        AND tc.constraint_name = 'store_address_id_fk'
    ) THEN
        ALTER TABLE main.store
            ADD CONSTRAINT "store_address_id_fk" FOREIGN KEY ("address_id") REFERENCES main.address("address_id");
    END IF;
END
$$;

-- Continuing to create tables with foreign key constraints:

CREATE TABLE IF NOT EXISTS main.purchase (
    "purchase_id" bigserial NOT NULL PRIMARY KEY,
    "purchase_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    "customer_id" BIGINT NOT NULL,
    "sales_staff_id" INTEGER NOT NULL,
    CONSTRAINT "purchase_customer_id_fk" FOREIGN KEY ("customer_id") REFERENCES main.customer("customer_id"),
    CONSTRAINT "purchase_sales_staff_id_fk" FOREIGN KEY ("sales_staff_id") REFERENCES main.staff("staff_id")
);

CREATE TABLE IF NOT EXISTS main.payment (
    "payment_id" bigserial NOT NULL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL,
    "payment_date" TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    "amount" DECIMAL(8, 2) NOT NULL,
    "payment_method" TEXT NOT NULL DEFAULT 'debit card',
    "customer_id" BIGINT NOT NULL,
    "staff_id" INTEGER NOT NULL,
    CONSTRAINT "payment_purchase_id_fk" FOREIGN KEY ("purchase_id") REFERENCES main.purchase("purchase_id"),
    CONSTRAINT "payment_staff_id_fk" FOREIGN KEY ("staff_id") REFERENCES main.staff("staff_id"),
    CONSTRAINT "payment_customer_id_fk" FOREIGN KEY ("customer_id") REFERENCES main.customer("customer_id")
);

CREATE TABLE IF NOT EXISTS main.purchase_item (
    "purchase_item_id" bigserial NOT NULL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL,
    "product_id" BIGINT NOT NULL,
    "qty" INTEGER NOT NULL DEFAULT 1,
    "unit_price" DECIMAL(8, 2) NOT NULL, -- product's price AT the time OF purchase
    CONSTRAINT "purchase_item_purchase_id_fk" FOREIGN KEY ("purchase_id") REFERENCES main.purchase("purchase_id"),
    CONSTRAINT "purchase_item_product_id_fk" FOREIGN KEY ("product_id") REFERENCES main.product("product_id")
);

CREATE TABLE IF NOT EXISTS main.inventory (
    "inventory_id" bigserial NOT NULL PRIMARY KEY,
    "product_id" BIGINT NOT NULL,
    "qty_in_stock" INTEGER NOT NULL,
    "store_id" INTEGER NOT NULL,
    CONSTRAINT "inventory_store_id_fk" FOREIGN KEY ("store_id") REFERENCES main.store("store_id"),
    CONSTRAINT "inventory_product_id_fk" FOREIGN KEY ("product_id") REFERENCES main.product("product_id")
);

CREATE TABLE IF NOT EXISTS main.supplier (
    "supplier_id" SERIAL NOT NULL PRIMARY KEY,
    "supplier_name" TEXT NOT NULL,
    "address_id" INTEGER NOT NULL,
    "email" TEXT NOT NULL,
    "phone_number" TEXT NOT NULL,
    CONSTRAINT "supplier_address_id_fk" FOREIGN KEY ("address_id") REFERENCES main.address("address_id")
);


CREATE TABLE IF NOT EXISTS main.brand_supplier (
    "brand_id" INTEGER NOT NULL,
    "supplier_id" INTEGER NOT NULL,
    PRIMARY KEY ("brand_id", "supplier_id"),
    CONSTRAINT "brand_supplier_supplier_id_fk" FOREIGN KEY ("supplier_id") REFERENCES main.supplier("supplier_id"),
    CONSTRAINT "brand_supplier_brand_id_fk" FOREIGN KEY ("brand_id") REFERENCES main.brand("brand_id")
);

-- ALTER TABLE commands wrapped in DO block for reusability:

DO $$
BEGIN

-- Adding check constraints: 

-- staff_role_check: specifies the possible roles for employees in the staff_role table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'staff_role'
AND cc.constraint_name = 'staff_role_check'
) THEN
ALTER TABLE main.staff_role
ADD CONSTRAINT staff_role_check CHECK (role_name IN ('clerk', 'sales', 'manager'));
END IF;

-- category_name_check: specifies the possible product categories for the category table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'category'
AND cc.constraint_name = 'category_name_check'
) THEN
ALTER TABLE main.category
ADD CONSTRAINT category_name_check CHECK (category_name IN ('Refrigeration', 'Cooking', 'Laundry', 'Heating/Cooling', 'Countertop', 'Cleaning', 'Personal Care'));
END IF;

-- product_price_check: checks that the price in the product table is greater than 0
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'product'
AND cc.constraint_name = 'product_price_check'
) THEN
ALTER TABLE main.product
ADD CONSTRAINT product_price_check CHECK (price > 0);
END IF;

-- payment_amount_check: checks that the paid amount in the payment table is greater than 0
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'payment'
AND cc.constraint_name = 'payment_amount_check'
) THEN
ALTER TABLE main.payment
ADD CONSTRAINT payment_amount_check CHECK (amount > 0);
END IF;

-- payment_pmethod_check: specifies the accepted payment methods for the payment table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'payment'
AND cc.constraint_name = 'payment_pmethod_check'
) THEN
ALTER TABLE main.payment
ADD CONSTRAINT payment_pmethod_check CHECK (payment_method IN('cash', 'credit card', 'debit card', 'bank transfer'));
END IF;

-- purchase_item_qty_check: checks that the purchased quantity is greater than 0 in the purchase_item table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'purchase_item'
AND cc.constraint_name = 'purchase_item_qty_check'
) THEN
ALTER TABLE main.purchase_item
ADD CONSTRAINT purchase_item_qty_check CHECK (qty > 0);
END IF;

-- purchase_item_price_check: checks that the unit_price (product's price at the time of purchase) is greater than 0 in the purchase_item table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'purchase_item'
AND cc.constraint_name = 'purchase_item_price_check'
) THEN
ALTER TABLE main.purchase_item
ADD CONSTRAINT purchase_item_price_check CHECK (unit_price > 0);
END IF;

-- inventory_stocklevel_check: checks that the stock level is at least 0 in the inventory table
IF NOT EXISTS (
SELECT *
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
ON cc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'main'
AND tc.table_name = 'inventory'
AND cc.constraint_name = 'inventory_stocklevel_check'
) THEN
ALTER TABLE main.inventory
ADD CONSTRAINT inventory_stocklevel_check CHECK (qty_in_stock >= 0);
END IF;

-- Adding UNIQUE constraints:

-- for the emial and phone_number columns of the staff table:	
IF NOT EXISTS (
SELECT *
FROM information_schema.table_constraints tc
WHERE tc.constraint_type = 'UNIQUE'
AND tc.table_schema = 'main'
AND tc.table_name = 'staff'
AND tc.constraint_name = 'staff_email_unique'
) THEN
ALTER TABLE main.staff
ADD CONSTRAINT staff_email_unique UNIQUE (email);
END IF;

IF NOT EXISTS (
SELECT *
FROM information_schema.table_constraints tc
WHERE tc.constraint_type = 'UNIQUE'
AND tc.table_schema = 'main'
AND tc.table_name = 'staff'
AND tc.constraint_name = 'staff_phone_number_unique'
) THEN
ALTER TABLE main.staff
ADD CONSTRAINT staff_phone_number_unique UNIQUE (phone_number);
END IF;

-- for the emial and phone_number columns of the supplier table:
IF NOT EXISTS (
SELECT *
FROM information_schema.table_constraints tc
WHERE tc.constraint_type = 'UNIQUE'
AND tc.table_schema = 'main'
AND tc.table_name = 'supplier'
AND tc.constraint_name = 'supplier_email_unique'
) THEN
ALTER TABLE main.supplier
ADD CONSTRAINT supplier_email_unique UNIQUE (email);
END IF;	

IF NOT EXISTS (
SELECT *
FROM information_schema.table_constraints tc
WHERE tc.constraint_type = 'UNIQUE'
AND tc.table_schema = 'main'
AND tc.table_name = 'supplier'
AND tc.constraint_name = 'supplier_phone_number_unique'
) THEN
ALTER TABLE main.supplier
ADD CONSTRAINT supplier_phone_number_unique UNIQUE (phone_number);
END IF;	
	
END
$$;


/* 4. Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.
Create DML scripts for insert your data. 
Ensure that the DML scripts do not include values for surrogate keys, as these keys should be generated by the database during runtime. 
Also, ensure that any DEFAULT values required are specified appropriately in the DML scripts. 
These DML scripts should be designed to successfully adhere to all previously defined constraints */



-- inserting customers:
INSERT INTO main.customer (first_name, last_name, create_date)
SELECT *
FROM (VALUES
    ('Alice', 'Johnson', '2023-06-15'::date),
    ('Brian', 'Smith', '2022-11-03'::date),
    ('Catherine', 'Lee', '2023-01-27'::date),
    ('David', 'Martinez', '2023-05-01'::date),
    ('Ella', 'Brown', '2022-09-18'::date),
    ('Frank', 'Davis', '2020-07-13'::date),
    ('Grace', 'Wilson', '2023-12-05'::date),
    ('Henry', 'Miller', '2021-11-25'::date)
) AS v(first_name, last_name, create_date)
WHERE NOT EXISTS (
    SELECT 1 FROM main.customer c 
    WHERE c.first_name = v.first_name AND c.last_name = v.last_name
);

-- inserting countries:
INSERT INTO main.country (country_name)
SELECT *
FROM (VALUES
    ('Hungary'),
    ('Serbia'),
    ('Croatia'),
    ('Poland'),
    ('Romania'),
    ('Slovakia'),
    ('Slovenia'),
    ('Germany')
) AS v(country_name)
WHERE NOT EXISTS (
    SELECT 1 FROM main.country c 
    WHERE UPPER(c.country_name) = UPPER(v.country_name)
);

-- inserting cities:
INSERT INTO main.city (city_name, country_id)
SELECT *
FROM (VALUES
    ('Budapest', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'HUNGARY')),
    ('Debrecen', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'HUNGARY')),
    ('Szeged', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'HUNGARY')),
    ('Pecs', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'HUNGARY')),
    ('Gyor', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'HUNGARY')),
    ('Belgrade', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'SERBIA')),
    ('Zagreb', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'CROATIA')),
    ('Warsaw', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'POLAND')),
    ('Bucharest', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'ROMANIA')),
    ('Bratislava', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'SLOVAKIA')),
    ('Ljubljana', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'SLOVENIA')),
    ('Berlin', (SELECT country_id FROM main.country WHERE UPPER(country_name) = 'GERMANY'))
) AS v(city_name, country_id)
WHERE NOT EXISTS (
    SELECT 1 FROM main.city c 
    WHERE UPPER(c.city_name) = UPPER(v.city_name)
);


-- inserting addresses:
INSERT INTO main.address (address, city_id, postal_code)
SELECT *
FROM (VALUES
    ('Andrassy ut 12', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUDAPEST'), 1061),
    ('Kossuth Lajos utca 5', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUDAPEST'), 1055),
    ('Piac utca 3', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'DEBRECEN'), 4025),
    ('Boszormenyi ut 45', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'DEBRECEN'), 4032),
    ('Karasz utca 8', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'SZEGED'), 6720),
    ('Tisza Lajos korut 23', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'SZEGED'), 6725),
    ('Irgalmasok utcaja 15', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'PECS'), 7621),
    ('Rakoczi ut 2', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'PECS'), 7632),
    ('Baross ut 10', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'GYOR'), 9021),
    ('Meszaros Lorinc utca 4', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'GYOR'), 9025),
    ('Knez Mihailova 14', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BELGRADE'), 11000),
    ('Nemanjina 22', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BELGRADE'), 11080),
    ('Ilica 7', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'ZAGREB'), 10000),
    ('Savska cesta 32', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'ZAGREB'), 10020),
    ('Marszalkowska 120', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'WARSAW'), 110),
    ('Aleje Jerozolimskie 54', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'WARSAW'), 697),
    ('Calea Victoriei 22', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUCHAREST'), 10094),
    ('Strada Lipscani 45', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUCHAREST'), 30033),
    ('Obchodna 12', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BRATISLAVA'), 81106),
    ('Spitalska 14', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BRATISLAVA'), 81108),
    ('Tromostovje 1', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'LJUBLJANA'), 1000),
    ('Slovenska cesta 50', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'LJUBLJANA'), 1000),
    ('Kurfurstendamm 21', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BERLIN'), 10719),
    ('Alexanderplatz 1', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BERLIN'), 10178),
    
    ('Petofi utca 51', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUDAPEST'), 1054),
    ('Vaci utca 40', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BUDAPEST'), 1023),
    ('Mariastrasse 83', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BERLIN'), 10719),
    ('Mannerplatz 23', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'BERLIN'), 10178),
    ('Marszalkowska 43', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'WARSAW'), 110),
    ('Aleje Jerozolimskie 6', (SELECT city_id FROM main.city WHERE UPPER(city_name) = 'WARSAW'), 697)
    
) AS v(address, city_id, postal_code)
WHERE NOT EXISTS (
    SELECT 1 FROM main.address a 
    WHERE a.address = v.address
);

-- inserting staff roles:
INSERT INTO main.staff_role (role_name)
SELECT *
FROM (VALUES
    ('clerk'),
    ('sales'),
    ('manager')
) AS v(role_name)
WHERE NOT EXISTS (
    SELECT 1 FROM main.staff_role r
    WHERE LOWER(r.role_name) = LOWER(v.role_name)
);

-- inserting brands:
INSERT INTO main.brand (brand_name)
SELECT *
FROM (VALUES
    ('Samsung'),
    ('LG'),
    ('Whirlpool'),
    ('Bosch'),
    ('Electrolux'),
    ('Miele'),
    ('Panasonic'),
    ('Philips')
) AS v(brand_name)
WHERE NOT EXISTS (
    SELECT 1 FROM main.brand b 
    WHERE LOWER(b.brand_name) = LOWER(v.brand_name)
);

-- inserting categories:
INSERT INTO main.category (category_name)
SELECT *
FROM (VALUES
    ('Refrigeration'),
    ('Cooking'),
    ('Laundry'),
    ('Heating/Cooling'),
    ('Countertop'),
    ('Cleaning'),
    ('Personal Care')
) AS v(category_name)
WHERE NOT EXISTS (
    SELECT 1 FROM main.category c 
    WHERE LOWER(c.category_name) = LOWER(v.category_name)
);

-- inserting types:
WITH category_map AS (
    SELECT category_id, UPPER(category_name) AS category_name_upper
    FROM main.category
)
INSERT INTO main.type (type_name, category_id)
SELECT *
FROM (VALUES
    ('French Door Refrigerator', (SELECT category_id FROM category_map WHERE category_name_upper = 'REFRIGERATION')),
    ('Chest Freezer', (SELECT category_id FROM category_map WHERE category_name_upper = 'REFRIGERATION')),
    ('Gas Range', (SELECT category_id FROM category_map WHERE category_name_upper = 'COOKING')),
    ('Microwave Oven', (SELECT category_id FROM category_map WHERE category_name_upper = 'COOKING')),
    ('Front Load Washer', (SELECT category_id FROM category_map WHERE category_name_upper = 'LAUNDRY')),
    ('Dryer', (SELECT category_id FROM category_map WHERE category_name_upper = 'LAUNDRY')),
    ('Portable Air Conditioner', (SELECT category_id FROM category_map WHERE category_name_upper = 'HEATING/COOLING')),
    ('Space Heater', (SELECT category_id FROM category_map WHERE category_name_upper = 'HEATING/COOLING')),
    ('Toaster Oven', (SELECT category_id FROM category_map WHERE category_name_upper = 'COUNTERTOP')),
    ('Coffee Maker', (SELECT category_id FROM category_map WHERE category_name_upper = 'COUNTERTOP')),
    ('Robot Vacuum', (SELECT category_id FROM category_map WHERE category_name_upper = 'CLEANING')),
    ('Steam Mop', (SELECT category_id FROM category_map WHERE category_name_upper = 'CLEANING')),
    ('Electric Shaver', (SELECT category_id FROM category_map WHERE category_name_upper = 'PERSONAL CARE')),
    ('Hair Dryer', (SELECT category_id FROM category_map WHERE category_name_upper = 'PERSONAL CARE'))
) AS v(type_name, category_id)
WHERE NOT EXISTS (
    SELECT 1 FROM main.type t 
    WHERE t.type_name = v.type_name
);

-- inserting models:
WITH new_models AS (
    SELECT 'X100' AS model_name, 'SAMSUNG' AS brand_name, 'Black' AS colour, 2022 AS release_year UNION ALL
    SELECT 'X200', 'SAMSUNG', 'Silver', 2023 UNION ALL
    SELECT 'Z300', 'LG', 'White', 2021 UNION ALL
    SELECT 'Z400', 'LG', 'Grey', 2024 UNION ALL
    SELECT 'A500', 'WHIRLPOOL', 'White', 2020 UNION ALL
    SELECT 'A600', 'WHIRLPOOL', 'Blue', 2022 UNION ALL
    SELECT 'B700', 'BOSCH', 'Grey', 2021 UNION ALL
    SELECT 'B800', 'BOSCH', 'Black', 2023 UNION ALL
    SELECT 'C900', 'ELECTROLUX', 'Silver', 2020 UNION ALL
    SELECT 'C1000', 'ELECTROLUX', 'White', 2021 UNION ALL
    SELECT 'D1100', 'MIELE', 'Silver', 2022 UNION ALL
    SELECT 'D1200', 'MIELE', 'Grey', 2023 UNION ALL
    SELECT 'E1300', 'PANASONIC', 'Black', 2021 UNION ALL
    SELECT 'E1400', 'PANASONIC', 'Silver', 2024 UNION ALL
    SELECT 'F1500', 'PHILIPS', 'White', 2022 UNION ALL
    SELECT 'F1600', 'PHILIPS', 'Grey', 2023
)

INSERT INTO main.model (model_name, brand_id, colour, release_year)
SELECT
    nm.model_name,
    b.brand_id,
    nm.colour,
    nm.release_year
FROM new_models nm
INNER JOIN main.brand b ON UPPER(b.brand_name) = nm.brand_name
WHERE NOT EXISTS (
    SELECT 1
    FROM main.model m
    WHERE m.model_name = nm.model_name
);

-- inserting products:
WITH model_products AS (
    SELECT 'X100' AS model_name, 'Portable Air Conditioner' AS type_name, 499.99 AS price UNION ALL
    SELECT 'X200', 'Portable Air Conditioner', 549.99 UNION ALL
    SELECT 'Z300', 'Dryer', 799.99 UNION ALL
    SELECT 'Z400', 'Front Load Washer', 899.99 UNION ALL
    SELECT 'A500', 'Chest Freezer', 699.99 UNION ALL
    SELECT 'A600', 'French Door Refrigerator', 1499.99 UNION ALL
    SELECT 'B700', 'French Door Refrigerator', 1599.99 UNION ALL
    SELECT 'B800', 'Chest Freezer', 749.99 UNION ALL
    SELECT 'C900', 'Dryer', 849.99 UNION ALL
    SELECT 'C1000', 'Front Load Washer', 899.99 UNION ALL
    SELECT 'D1100', 'Space Heater', 379.99 UNION ALL
    SELECT 'D1200', 'Space Heater', 399.99 UNION ALL
    SELECT 'E1300', 'Microwave Oven', 299.99 UNION ALL
    SELECT 'E1400', 'Microwave Oven', 349.99 UNION ALL
    SELECT 'F1500', 'Electric Shaver', 199.99 UNION ALL
    SELECT 'F1600', 'Electric Shaver', 229.99
)

INSERT INTO main.product (type_id, model_id, price)
SELECT
    t.type_id,
    m.model_id,
    mp.price
FROM model_products mp
INNER JOIN main.model m ON m.model_name = mp.model_name
INNER JOIN main.type t ON UPPER(t.type_name) = UPPER(mp.type_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM main.product p
    WHERE p.model_id = m.model_id
);


-- inserting stores:

WITH selected_addresses AS (
    -- 2 Hungarian store addresses
    SELECT address_id FROM main.address WHERE address = 'Andrassy ut 12'
    UNION ALL
    SELECT address_id FROM main.address WHERE address = 'Karasz utca 8'

    UNION ALL

    -- 4 non-Hungarian store addresses
    SELECT address_id FROM main.address WHERE address = 'Ilica 7'
    UNION ALL
    SELECT address_id FROM main.address WHERE address = 'Obchodna 12'
    UNION ALL
    SELECT address_id FROM main.address WHERE address = 'Kurfurstendamm 21'
    UNION ALL
    SELECT address_id FROM main.address WHERE address = 'Marszalkowska 120'
)

INSERT INTO main.store (address_id)
SELECT sa.address_id
FROM selected_addresses sa
WHERE NOT EXISTS (
    SELECT 1 FROM main.store s WHERE s.address_id = sa.address_id
);



-- inserting staff:


WITH role_ids AS (
    SELECT 
        (SELECT role_id FROM main.staff_role WHERE LOWER(role_name) = 'manager') AS manager_id,
        (SELECT role_id FROM main.staff_role WHERE LOWER(role_name) = 'clerk') AS clerk_id,
        (SELECT role_id FROM main.staff_role WHERE LOWER(role_name) = 'sales') AS sales_id
),


store_refs AS (
    SELECT s.store_id, s.address_id, a.address
    FROM main.store s
    JOIN main.address a ON s.address_id = a.address_id
    WHERE a.address IN (
        'Andrassy ut 12',
        'Karasz utca 8',
        'Ilica 7',
        'Obchodna 12',
        'Kurfurstendamm 21',
        'Marszalkowska 120'
    )
    ORDER BY s.store_id
),

-- 18 new employees: 6 managers, 6 clerks, 6 sales (1 of each per store)
staff_data AS (
    SELECT * FROM (
        VALUES
        -- Store 1
        ('Anna', 'Novak', 'anna.novak@example.com', '+3620000001', 'manager'),
        ('Nora', 'Molnar', 'nora.molnar@example.com', '+3620000002', 'clerk'),
        ('Tamas', 'Vida', 'tamas.vida@example.com', '+3620000003', 'sales'),

        -- Store 2
        ('Peter', 'Horvath', 'peter.horvath@example.com', '+3620000004', 'manager'),
        ('Bence', 'Kovacs', 'bence.kovacs@example.com', '+3620000005', 'clerk'),
        ('Fanni', 'Varga', 'fanni.varga@example.com', '+3620000006', 'sales'),

        -- Store 3
        ('Luca', 'Varga', 'luca.varga@example.com', '+3620000007', 'manager'),
        ('Zsofia', 'Feher', 'zsofia.feher@example.com', '+3620000008', 'clerk'),
        ('Kristof', 'Barta', 'kristof.barta@example.com', '+3620000009', 'sales'),

        -- Store 4
        ('David', 'Szabo', 'david.szabo@example.com', '+3620000010', 'manager'),
        ('Marton', 'Pinter', 'marton.pinter@example.com', '+3620000011', 'clerk'),
        ('Dora', 'Lengyel', 'dora.lengyel@example.com', '+3620000012', 'sales'),

        -- Store 5
        ('Kata', 'Farkas', 'kata.farkas@example.com', '+3620000013', 'manager'),
        ('Eszter', 'Major', 'eszter.major@example.com', '+3620000014', 'clerk'),
        ('Noemi', 'Szoke', 'noemi.szoke@example.com', '+3620000015', 'sales'),

        -- Store 6
        ('Adam', 'Toth', 'adam.toth@example.com', '+3620000016', 'manager'),
        ('Gabor', 'Simon', 'gabor.simon@example.com', '+3620000017', 'clerk'),
        ('Roland', 'Gulyas', 'roland.gulyas@example.com', '+3620000018', 'sales')
    ) AS t(first_name, last_name, email, phone_number, role_label)
),
numbered_staff AS (
    SELECT *, ROW_NUMBER() OVER () AS row_num FROM staff_data
),

-- looking up address_ids for staff
home_address_strings AS (
    SELECT * FROM (
        VALUES
        ('Strada Lipscani 45'), ('Calea Victoriei 22'), ('Spitalska 14'), ('Nemanjina 22'),
        ('Alexanderplatz 1'), ('Slovenska cesta 50'), ('Aleje Jerozolimskie 54'), ('Kossuth Lajos utca 5'),
        ('Meszaros Lorinc utca 4'), ('Boszormenyi ut 45'), ('Piac utca 3'), ('Tisza Lajos korut 23'),
        ('Baross ut 10'), ('Savska cesta 32'), ('Tromostovje 1'), ('Knez Mihailova 14'),
        ('Rakoczi ut 2'), ('Irgalmasok utcaja 15')
    ) AS t(address)
),

home_addresses AS (
    SELECT a.address_id, has.address, ROW_NUMBER() OVER () AS row_num
    FROM home_address_strings has
    JOIN main.address a ON a.address = has.address
    LIMIT 18
),

-- Match 3 employees per store (row_num 1-3 → store 1, 4-6 → store 2, etc.)
staff_with_lookups AS (
    SELECT
        s.first_name, s.last_name, s.email, s.phone_number, s.role_label,
        sr.store_id,
        ha.address_id AS home_address_id
    FROM numbered_staff s
    JOIN home_addresses ha ON s.row_num = ha.row_num
    JOIN (
        SELECT store_id, ROW_NUMBER() OVER (ORDER BY store_id) AS store_index FROM store_refs
    ) sr ON ((s.row_num - 1) / 3 + 1) = sr.store_index
),

-- Final insert into main.staff
insert_staff AS (
    INSERT INTO main.staff (
        first_name, last_name, email, phone_number, address_id, store_id, role_id
    )
    SELECT
        s.first_name,
        s.last_name,
        s.email,
        s.phone_number,
        s.home_address_id,
        s.store_id,
        r.resolved_role_id
    FROM staff_with_lookups s,
    LATERAL (
        SELECT
            CASE 
                WHEN s.role_label = 'manager' THEN manager_id
                WHEN s.role_label = 'clerk' THEN clerk_id
                ELSE sales_id
            END AS resolved_role_id
        FROM role_ids
    ) r
    WHERE NOT EXISTS (
        SELECT 1 FROM main.staff existing
        WHERE existing.email = s.email
    )
)

SELECT 1;

-- populating manager_staff_id column of store table:

UPDATE main.store s
SET manager_staff_id = m.staff_id
FROM main.staff m
JOIN main.staff_role r ON m.role_id = r.role_id
WHERE
    r.role_name ILIKE 'manager' -- ensure role is manager
    AND m.store_id = s.store_id
    AND s.manager_staff_id IS DISTINCT FROM m.staff_id;

-- inserting purchases:

WITH customer_staff_pairs AS (
    SELECT * FROM (
        VALUES
        -- customer_first, customer_last, staff_first, staff_last, purchase_date
        ('Catherine', 'Lee', 'Roland', 'Gulyas', '2025-04-01 09:45:00+00'),
        ('Catherine', 'Lee', 'Fanni', 'Varga', '2025-04-11 13:15:00+00'),

        ('Grace', 'Wilson', 'Dora', 'Lengyel', '2025-04-03 10:20:00+00'),
        ('Grace', 'Wilson', 'Tamas', 'Vida', '2025-04-17 15:05:00+00'),

        ('Brian', 'Smith', 'Kristof', 'Barta', '2025-04-06 08:30:00+00'),
        ('Brian', 'Smith', 'Noemi', 'Szoke', '2025-04-20 12:00:00+00'),

        ('Ella', 'Brown', 'Dora', 'Lengyel', '2025-04-02 16:50:00+00'),
        ('Ella', 'Brown', 'Fanni', 'Varga', '2025-04-12 09:10:00+00'),

        ('David', 'Martinez', 'Dora', 'Lengyel', '2025-04-04 11:40:00+00'),
        ('David', 'Martinez', 'Tamas', 'Vida', '2025-04-19 17:25:00+00'),

        ('Henry', 'Miller', 'Kristof', 'Barta', '2025-04-07 10:10:00+00'),
        ('Henry', 'Miller', 'Noemi', 'Szoke', '2025-04-16 13:30:00+00'),

        ('Frank', 'Davis', 'Roland', 'Gulyas', '2025-04-08 12:15:00+00'),
        ('Frank', 'Davis', 'Fanni', 'Varga', '2025-04-21 14:45:00+00'),

        ('Alice', 'Johnson', 'Dora', 'Lengyel', '2025-04-05 09:00:00+00'),
        ('Alice', 'Johnson', 'Tamas', 'Vida', '2025-04-18 10:35:00+00')
    ) AS t(customer_first, customer_last, staff_first, staff_last, purchase_date)
),
resolved_pairs AS (
    SELECT
        p.customer_first,
        p.customer_last,
        p.staff_first,
        p.staff_last,
        p.purchase_date::timestamptz,
        (
            SELECT c.customer_id
            FROM main.customer c
            WHERE c.first_name = p.customer_first AND c.last_name = p.customer_last
            LIMIT 1
        ) AS customer_id,
        (
            SELECT s.staff_id
            FROM main.staff s
            WHERE s.first_name = p.staff_first AND s.last_name = p.staff_last
            LIMIT 1
        ) AS staff_id
    FROM customer_staff_pairs p
),
purchases_to_insert AS (
    SELECT *
    FROM resolved_pairs
    WHERE customer_id IS NOT NULL
      AND staff_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM main.purchase p
        WHERE p.customer_id = resolved_pairs.customer_id
          AND p.sales_staff_id = resolved_pairs.staff_id
          AND p.purchase_date = resolved_pairs.purchase_date
    )
)

INSERT INTO main.purchase (purchase_date, customer_id, sales_staff_id)
SELECT purchase_date, customer_id, staff_id
FROM purchases_to_insert;


-- inserting payment data (1 for each purchase)

WITH payment_data AS (
    SELECT * FROM (
        VALUES
        ('Catherine', 'Lee', '2025-04-01 09:45:00+00'::timestamptz, 'Roland', 'Gulyas', 399.99, 'debit card'),
        ('Catherine', 'Lee', '2025-04-11 13:15:00+00'::timestamptz, 'Fanni', 'Varga', 379.99, 'credit card'),

        ('Grace', 'Wilson', '2025-04-03 10:20:00+00'::timestamptz, 'Dora', 'Lengyel', 399.98, 'bank transfer'),
        ('Grace', 'Wilson', '2025-04-17 15:05:00+00'::timestamptz, 'Tamas', 'Vida', 459.98, 'cash'),

        ('Brian', 'Smith', '2025-04-06 08:30:00+00'::timestamptz, 'Kristof', 'Barta', 899.97, 'debit card'),
        ('Brian', 'Smith', '2025-04-20 12:00:00+00'::timestamptz, 'Noemi', 'Szoke', 349.99, 'credit card'),

        ('Ella', 'Brown', '2025-04-02 16:50:00+00'::timestamptz, 'Roland', 'Gulyas', 499.99, 'bank transfer'),
        ('Ella', 'Brown', '2025-04-12 09:10:00+00'::timestamptz, 'Fanni', 'Varga', 549.99, 'cash'),

        ('David', 'Martinez', '2025-04-04 11:40:00+00'::timestamptz, 'Dora', 'Lengyel', 1599.99, 'credit card'),
        ('David', 'Martinez', '2025-04-19 17:25:00+00'::timestamptz, 'Tamas', 'Vida', 749.99, 'debit card'),

        ('Henry', 'Miller', '2025-04-07 10:10:00+00'::timestamptz, 'Kristof', 'Barta', 1499.99, 'cash'),
        ('Henry', 'Miller', '2025-04-16 13:30:00+00'::timestamptz, 'Noemi', 'Szoke', 899.99, 'bank transfer'),

        ('Frank', 'Davis', '2025-04-08 12:15:00+00'::timestamptz, 'Gabor', 'Simon', 899.99, 'debit card'),
        ('Frank', 'Davis', '2025-04-21 14:45:00+00'::timestamptz, 'Nora', 'Molnar', 849.99, 'credit card'),

        ('Alice', 'Johnson', '2025-04-05 09:00:00+00'::timestamptz, 'Eszter', 'Major', 799.99, 'cash'),
        ('Alice', 'Johnson', '2025-04-18 10:35:00+00'::timestamptz, 'Bence', 'Kovacs', 699.99, 'bank transfer')
    ) AS t(
        customer_first, customer_last,
        purchase_date, staff_first, staff_last,
        amount, payment_method
    )
),
resolved_payments AS (
    SELECT
        pd.customer_first,
        pd.customer_last,
        pd.purchase_date,
        pd.amount,
        pd.payment_method,
        pd.purchase_date + interval '1 minute' AS payment_date,
        (
            SELECT c.customer_id
            FROM main.customer c
            WHERE c.first_name = pd.customer_first AND c.last_name = pd.customer_last
            LIMIT 1
        ) AS customer_id,
        (
            SELECT s.staff_id
            FROM main.staff s
            WHERE s.first_name = pd.staff_first AND s.last_name = pd.staff_last
            LIMIT 1
        ) AS staff_id,
        (
            SELECT p.purchase_id
            FROM main.purchase p
            JOIN main.customer c ON c.customer_id = p.customer_id
            WHERE c.first_name = pd.customer_first
              AND c.last_name = pd.customer_last
              AND p.purchase_date = pd.purchase_date
            LIMIT 1
        ) AS purchase_id
    FROM payment_data pd
),
to_insert AS (
    SELECT *
    FROM resolved_payments rp
    WHERE customer_id IS NOT NULL
      AND staff_id IS NOT NULL
      AND purchase_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM main.payment pay
        WHERE pay.purchase_id = rp.purchase_id
      )
)

INSERT INTO main.payment (
    purchase_id, payment_date, amount, payment_method, customer_id, staff_id
)
SELECT purchase_id, payment_date, amount, payment_method, customer_id, staff_id
FROM to_insert;

-- inserting into purchase_item table:

WITH product_prices AS (
    SELECT * FROM (
        VALUES
            ('D1200', 399.99),
            ('D1100', 379.99),
            ('F1500', 199.99),
            ('F1600', 229.99),
            ('E1300', 299.99),
            ('E1400', 349.99),
            ('X100', 499.99),
            ('X200', 549.99),
            ('B700', 1599.99),
            ('B800', 749.99),
            ('A600', 1499.99),
            ('Z400', 899.99),
            ('C1000', 899.99),
            ('C900', 849.99),
            ('Z300', 799.99),
            ('A500', 699.99)
    ) AS pp(model_name, unit_price)
),
product_ids AS (
    SELECT
        pp.model_name,
        p.product_id,
        pp.unit_price
    FROM product_prices pp
    JOIN main.model m ON pp.model_name = m.model_name
    JOIN main.product p ON p.model_id = m.model_id
),
purchase_reference AS (
    SELECT * FROM (
        VALUES
            ('Catherine', 'Lee', '2025-04-01 11:45:00+02'::timestamptz),
            ('Catherine', 'Lee', '2025-04-11 15:15:00+02'::timestamptz),
            ('Grace', 'Wilson', '2025-04-03 12:20:00+02'::timestamptz),
            ('Grace', 'Wilson', '2025-04-17 17:05:00+02'::timestamptz),
            ('Brian', 'Smith', '2025-04-06 10:30:00+02'::timestamptz),
            ('Brian', 'Smith', '2025-04-20 14:00:00+02'::timestamptz),
            ('Ella', 'Brown', '2025-04-02 18:50:00+02'::timestamptz),
            ('Ella', 'Brown', '2025-04-12 11:10:00+02'::timestamptz),
            ('David', 'Martinez', '2025-04-04 13:40:00+02'::timestamptz),
            ('David', 'Martinez', '2025-04-19 19:25:00+02'::timestamptz),
            ('Henry', 'Miller', '2025-04-07 12:10:00+02'::timestamptz),
            ('Henry', 'Miller', '2025-04-16 15:30:00+02'::timestamptz),
            ('Frank', 'Davis', '2025-04-08 14:15:00+02'::timestamptz),
            ('Frank', 'Davis', '2025-04-21 16:45:00+02'::timestamptz),
            ('Alice', 'Johnson', '2025-04-05 11:00:00+02'::timestamptz),
            ('Alice', 'Johnson', '2025-04-18 12:35:00+02'::timestamptz)
    ) AS t(first_name, last_name, purchase_date)
),
matched_purchases AS (
    SELECT
        pr.first_name,
        pr.last_name,
        pr.purchase_date,
        p.purchase_id,
        pay.amount
    FROM purchase_reference pr
    JOIN main.customer c ON c.first_name = pr.first_name AND c.last_name = pr.last_name
    JOIN main.purchase p ON p.customer_id = c.customer_id AND p.purchase_date = pr.purchase_date
    JOIN main.payment pay ON pay.purchase_id = p.purchase_id
),
purchase_item_matches AS (
    SELECT
        mp.purchase_id,
        pi.product_id,
        pi.unit_price,
        (mp.amount / pi.unit_price)::int AS qty,
        ROW_NUMBER() OVER (PARTITION BY mp.purchase_id ORDER BY pi.unit_price) AS product_rank
    FROM matched_purchases mp
    JOIN product_ids pi ON (mp.amount / pi.unit_price) % 1 = 0
),
final_items AS (
    SELECT
        purchase_id,
        product_id,
        qty,
        unit_price
    FROM purchase_item_matches
    WHERE product_rank = 1
    AND NOT EXISTS (
        SELECT 1
        FROM main.purchase_item pi
        WHERE pi.purchase_id = purchase_item_matches.purchase_id
    )
)
INSERT INTO main.purchase_item (purchase_id, product_id, qty, unit_price)
SELECT purchase_id, product_id, qty, unit_price
FROM final_items;

-- inserting into inventory table:

WITH manual_inventory AS (
    SELECT * FROM (
        VALUES
            -- model_name,           store_address,           qty_in_stock
            ('D1200',               'Andrassy ut 12',         40),
            ('D1200',               'Karasz utca 8',          35),
            ('D1200',               'Obchodna 12',            30),

            ('D1100',               'Ilica 7',                25),
            ('D1100',               'Marszalkowska 120',      20),

            ('F1500',               'Obchodna 12',            30),
            ('F1500',               'Kurfurstendamm 21',      32),

            ('F1600',               'Kurfurstendamm 21',      50),
            ('F1600',               'Ilica 7',                45),

            ('E1300',               'Marszalkowska 120',      45),
            ('E1300',               'Karasz utca 8',          40),

            ('E1400',               'Andrassy ut 12',         60),

            ('X100',                'Karasz utca 8',          20),
            ('X100',                'Kurfurstendamm 21',      15),

            ('X200',                'Ilica 7',                22),
            ('X200',                'Obchodna 12',            25),

            ('B700',                'Andrassy ut 12',         10),
            ('B700',                'Obchodna 12',            12),

            ('B800',                'Obchodna 12',            15),

            ('A600',                'Karasz utca 8',          8),
            ('A600',                'Marszalkowska 120',      6),

            ('Z400',                'Ilica 7',                18),
            ('Z400',                'Karasz utca 8',          12),

            ('C1000',               'Kurfurstendamm 21',      12),
            ('C1000',               'Andrassy ut 12',         9),

            ('C900',                'Marszalkowska 120',      26),

            ('Z300',                'Kurfurstendamm 21',      33),
            ('Z300',                'Karasz utca 8',          25),

            ('A500',                'Marszalkowska 120',      42),
            ('A500',                'Obchodna 12',            38)
    ) AS t(model_name, store_address, qty_in_stock)
),
resolved_inventory AS (
    SELECT
        mi.model_name,
        mi.store_address,
        mi.qty_in_stock,
        p.product_id,
        s.store_id
    FROM manual_inventory mi
    JOIN main.model m ON mi.model_name = m.model_name
    JOIN main.product p ON p.model_id = m.model_id
    JOIN main.address a ON a.address = mi.store_address
    JOIN main.store s ON s.address_id = a.address_id
),
to_insert AS (
    SELECT *
    FROM resolved_inventory ri
    WHERE NOT EXISTS (
        SELECT 1 FROM main.inventory i
        WHERE i.product_id = ri.product_id AND i.store_id = ri.store_id
    )
)
INSERT INTO main.inventory (product_id, store_id, qty_in_stock)
SELECT product_id, store_id, qty_in_stock
FROM to_insert;

-- inserting suppliers:

WITH supplier_data AS (
    SELECT * FROM (
        VALUES
            ('EuroTech Distribution',      'Vaci utca 40',                'info@eurotech.com',         '+3612345671'),
            ('AlpenMarkt GmbH',           'Mariastrasse 83',             'contact@alpenmarkt.at',     '+498912345672'),
            ('Varsovia Components',       'Marszalkowska 43',            'sales@varsovia.pl',         '+48221234567'),
            ('Danube Electronics',        'Petofi utca 51',              'support@danube-elec.hu',    '+3612345673'),
            ('MannerTech Supplies',       'Mannerplatz 23',              'hello@mannertech.de',       '+4915112345678'),
            ('Jerozolimskie Partners',    'Aleje Jerozolimskie 6',       'partners@jerozolimskie.pl', '+48201234567')
    ) AS t(supplier_name, address_text, email, phone_number)
),
resolved_suppliers AS (
    SELECT
        sd.supplier_name,
        sd.email,
        sd.phone_number,
        a.address_id
    FROM supplier_data sd
    JOIN main.address a ON a.address = sd.address_text
),
to_insert AS (
    SELECT *
    FROM resolved_suppliers rs
    WHERE NOT EXISTS (
        SELECT 1 FROM main.supplier s WHERE s.email = rs.email
    )
)
INSERT INTO main.supplier (supplier_name, address_id, email, phone_number)
SELECT supplier_name, address_id, email, phone_number
FROM to_insert;


-- inserting brand-supplier connections:

WITH brand_supplier_data AS (
    SELECT * FROM (
        VALUES
            -- brand_name,         supplier_name
            ('Electrolux',        'EuroTech Distribution'),
            ('LG',                'AlpenMarkt GmbH'),
            ('Philips',           'Varsovia Components'),
            ('Bosch',             'Danube Electronics'),
            ('Samsung',           'MannerTech Supplies'),
            ('Whirlpool',         'Jerozolimskie Partners'),
            ('Panasonic',         'EuroTech Distribution'),  -- same supplier as Electrolux
            ('Miele',             'Varsovia Components')     -- same supplier as Philips
    ) AS t(brand_name, supplier_name)
),
resolved_links AS (
    SELECT
        b.brand_id,
        s.supplier_id
    FROM brand_supplier_data bsd
    JOIN main.brand b ON b.brand_name = bsd.brand_name
    JOIN main.supplier s ON s.supplier_name = bsd.supplier_name
),
to_insert AS (
    SELECT *
    FROM resolved_links rl
    WHERE NOT EXISTS (
        SELECT 1 FROM main.brand_supplier bs
        WHERE bs.brand_id = rl.brand_id AND bs.supplier_id = rl.supplier_id
    )
)
INSERT INTO main.brand_supplier (brand_id, supplier_id)
SELECT brand_id, supplier_id
FROM to_insert;


/* 5.1 Create a function that updates data in one of your tables. This function should take the following input arguments:
		The primary key value of the row you want to update
		The name of the column you want to update
		The new value you want to set for the specified column

	This function should be designed to modify the specified row in the table, updating the specified column with the new value. */


CREATE OR REPLACE FUNCTION main.update_staff_text(
    pkey BIGINT,
    column_name TEXT,
    new_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    sql_query TEXT;
BEGIN
    sql_query := format(
        'UPDATE main.staff SET %I = $1 WHERE staff_id = $2',
        column_name
    );

    EXECUTE sql_query USING new_value, pkey;
END;
$$;

SELECT main.update_staff_text (
	162,
	'email',
	'p.horvath@gmail.com');
	
/* 5.2 Create a function that adds a new transaction to your transaction table. 
	You can define the input arguments and output format. 
	Make sure all transaction attributes can be set with the function (via their natural keys). 
	The function does not need to return a value but should confirm the successful insertion of the new transaction. */


CREATE OR REPLACE FUNCTION main.add_purchase(
    p_date TIMESTAMP, 
    p_customername TEXT,
    p_staffname TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE 
    v_new_id BIGINT; 
    v_purchase_date TIMESTAMPTZ;
    v_customer_id BIGINT;
    v_sales_staff_id INTEGER;
BEGIN 
    -- Cast the purchase date to timestamptz
    SELECT p_date::TIMESTAMPTZ INTO v_purchase_date;

    -- Retrieve customer ID
    SELECT c.customer_id 
    INTO v_customer_id
    FROM main.customer c 
    WHERE UPPER(c.first_name || ' ' || c.last_name) = UPPER(p_customername);

    -- Retrieve sales staff ID
    SELECT s.staff_id
    INTO v_sales_staff_id
    FROM main.staff s 
    WHERE UPPER(s.first_name || ' ' || s.last_name) = UPPER(p_staffname);

    -- Insert into purchase table and return the new purchase_id into v_new_id variable
    INSERT INTO main.purchase (purchase_date, customer_id, sales_staff_id)
    VALUES (v_purchase_date, v_customer_id, v_sales_staff_id)
    RETURNING purchase_id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

SELECT main.add_purchase (
	'2025-05-07 10:30',
	'Grace Wilson',
	'Dora Lengyel')

	
/*6. Create a view that presents analytics for the most recently added quarter in your database. 
 	Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries. */

CREATE OR REPLACE VIEW q2_topsalesperson AS
SELECT (s.first_name || ' ' || s.last_name) AS salesperson, SUM (pa.amount) AS total_sales
FROM main.staff s
INNER JOIN main.purchase p ON s.staff_id = p.sales_staff_id
INNER JOIN main.payment pa ON p.purchase_id = pa.purchase_id
WHERE p.purchase_date BETWEEN '2025-04-01' AND '2025-06-30'
GROUP BY salesperson 
ORDER BY total_sales DESC 
LIMIT 1;

SELECT * FROM q2_topsalesperson


/*7. Create a read-only role for the manager.
 	This role should have permission to perform SELECT queries on the database tables, and also be able to log in. 
 	Please ensure that you adhere to best practices for database security when defining this role*/


CREATE ROLE manager LOGIN PASSWORD 'mypw123';

GRANT CONNECT
ON DATABASE appliance_store
TO manager;

GRANT USAGE ON SCHEMA main TO manager;

GRANT SELECT
ON ALL TABLES IN SCHEMA main
TO manager;

SET ROLE manager;

SELECT * FROM main.staff s;





