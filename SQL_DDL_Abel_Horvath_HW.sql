CREATE DATABASE recagency;

-- connect to recagency database, then:

CREATE SCHEMA training;

CREATE TABLE IF NOT EXISTS training.country (
    country_ID serial PRIMARY KEY,
    country_name varchar(50) NOT NULL);

CREATE TABLE IF NOT EXISTS training.city (
    city_ID serial PRIMARY KEY,
    city_name varchar(50) NOT NULL,
    country_ID integer NOT NULL,
    FOREIGN KEY (country_ID) REFERENCES training.country(country_ID));

CREATE TABLE IF NOT EXISTS training.role (
	role_ID serial PRIMARY KEY,
	role_name varchar(50) NOT NULL);

CREATE TABLE IF NOT EXISTS training.candidates (
    candidate_ID serial PRIMARY KEY,
    email varchar(255) UNIQUE NOT NULL,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    user_password varchar(50) NOT NULL,
    registration_date date NOT NULL,
    phone_nr varchar(50) UNIQUE NOT NULL,
    city_ID integer NOT NULL,
    birthdate date NOT NULL,
    highest_education varchar (50) NOT NULL,
	FOREIGN KEY (city_ID) REFERENCES training.city(city_ID));

CREATE TABLE IF NOT EXISTS training.address (
	address_ID serial PRIMARY KEY,
	street varchar(100) NOT NULL,
	zip_code varchar(50) NOT NULL,
	house_nr SMALLINT NOT NULL,
	city_ID integer NOT NULL,
	FOREIGN KEY (city_ID) REFERENCES training.city(city_ID));

CREATE TABLE IF NOT EXISTS training.companies (
	company_ID serial PRIMARY KEY,
	company_name varchar(100) NOT NULL,
	legal_form varchar(5) NOT NULL,
	industry varchar(50),
	address_ID integer NOT NULL,
	FOREIGN KEY (address_ID) REFERENCES training.address(address_ID));

CREATE TABLE IF NOT EXISTS training.job_listings (
	job_ID serial PRIMARY KEY,
	role_ID integer NOT NULL,
	company_ID integer NOT NULL,
	employment_type varchar(50) NOT NULL,
	contract_type varchar(50) NOT NULL,
	city_ID integer NOT NULL,
	upload_date date NOT NULL DEFAULT current_date,
 	FOREIGN KEY (role_ID) REFERENCES training.role(role_ID),
 	FOREIGN KEY (company_ID) REFERENCES training.companies(company_ID),
 	FOREIGN KEY (city_ID) REFERENCES training.city(city_ID));

CREATE TABLE IF NOT EXISTS training.job_applications (
	candidate_ID integer,
	job_ID integer,
	application_date date DEFAULT current_date,
	stage varchar(50) NOT NULL DEFAULT 'Waiting for review',
	PRIMARY KEY (candidate_ID, job_ID),
	FOREIGN KEY (candidate_ID) REFERENCES training.candidates(candidate_ID),
	FOREIGN KEY (job_ID) REFERENCES training.job_listings(job_ID));
 
CREATE TABLE IF NOT EXISTS training.skill (
	skill_ID serial PRIMARY KEY,
	skill_name varchar(50) NOT NULL,
	proficiency_level varchar (50) NOT NULL,
	certified boolean NOT NULL,
	certif_type varchar(50));

CREATE TABLE IF NOT EXISTS training.job_skill (
	job_ID integer,
	skill_ID integer,
	PRIMARY KEY (job_ID, skill_ID),
	FOREIGN KEY (job_ID) REFERENCES training.job_listings(job_ID),
	FOREIGN KEY (skill_ID) REFERENCES training.skill(skill_ID));

CREATE TABLE IF NOT EXISTS training.candidate_skill (
	candidate_ID integer,
	skill_ID integer,
	PRIMARY KEY (candidate_ID, skill_ID),
	FOREIGN KEY (candidate_ID) REFERENCES training.candidates(candidate_ID),
	FOREIGN KEY (skill_ID) REFERENCES training.skill(skill_ID));

CREATE TABLE IF NOT EXISTS training.experience (
	exp_ID serial PRIMARY KEY,
	role_ID integer NOT NULL,
	duration_months SMALLINT NOT NULL,
	FOREIGN KEY (role_ID) REFERENCES training.role(role_ID));

CREATE TABLE IF NOT EXISTS training.job_experience (
	job_ID integer,
	exp_ID integer,
	PRIMARY KEY (job_ID, exp_ID),
	FOREIGN KEY (job_ID) REFERENCES training.job_listings(job_ID),
	FOREIGN KEY (exp_ID) REFERENCES training.experience(exp_ID));
	
CREATE TABLE IF NOT EXISTS training.candidate_experience (
	candidate_ID integer,
	exp_ID integer,
	PRIMARY KEY (candidate_ID, exp_ID),
	FOREIGN KEY (candidate_ID) REFERENCES training.candidates(candidate_ID),
	FOREIGN KEY (exp_ID) REFERENCES training.experience(exp_ID));

CREATE TABLE IF NOT EXISTS training.interviewers (
	interviewer_ID serial PRIMARY KEY,
	first_name varchar(50) NOT NULL,
	last_name varchar(50) NOT NULL,
	phone_nr varchar(50) UNIQUE NOT NULL);

CREATE TABLE IF NOT EXISTS training.interviews (
	candidate_ID integer,
	job_ID integer,
	interview_round SMALLINT DEFAULT 1,
	interview_date date NOT NULL,
	interviewer_ID integer NOT NULL,
	PRIMARY KEY (candidate_ID, job_ID, interview_round),
	FOREIGN KEY (candidate_ID) REFERENCES training.candidates(candidate_ID),
	FOREIGN KEY (job_ID) REFERENCES training.job_listings(job_ID));
	
CREATE TABLE IF NOT EXISTS training.trainers (
	trainer_ID serial PRIMARY KEY,
	first_name varchar(50) NOT NULL,
	last_name varchar(50) NOT NULL,
	area_of_expertise varchar(50));

CREATE TABLE IF NOT EXISTS training.additional_services(
	service_ID serial PRIMARY KEY,
	service_name varchar(50) NOT NULL,
	service_level varchar(50) NOT NULL,
	duration_days SMALLINT NOT NULL,
	trainer_ID integer NOT NULL,
	price_USD SMALLINT NOT NULL,
	FOREIGN KEY (trainer_ID) REFERENCES training.trainers(trainer_ID));

CREATE TABLE IF NOT EXISTS training.service_applications(
	service_ID integer,
	candidate_ID integer,
	date_of_application date NOT NULL DEFAULT current_date,
	PRIMARY KEY (service_ID, candidate_ID));

ALTER TABLE training.additional_services
    ADD CONSTRAINT price_usd_check CHECK (price_USD > 0);

ALTER TABLE training.companies
    ADD CONSTRAINT possible_legal_forms CHECK (legal_form IN ('SP', 'GP', 'LP', 'LLC', 'Ltd', 'Inc', 'NPO', 'PLC', 'BO', 'JV'));

-- inserting values:

INSERT INTO training.country (country_name)
VALUES 
('Canada'),
('Hungary');

INSERT INTO training.city (city_name, country_ID)
VALUES 
('Vancouver', (SELECT country_ID FROM training.country WHERE country_name = 'Canada')),
('Budapest', (SELECT country_ID FROM training.country WHERE country_name = 'Hungary'));

INSERT INTO training.role (role_name)
VALUES 
('Software Engineer'),
('Data Analyst');

INSERT INTO training.candidates (
    email, first_name, last_name, user_password, registration_date, phone_nr, city_ID, birthdate, highest_education
)
VALUES 
('john.doe@example.com', 'John', 'Doe', 'Abc12345', '2023-07-12', '+1 555-1234', 
    (SELECT city_ID FROM training.city WHERE city_name = 'Vancouver'), '1984-05-21', 'bachelor’s degree'),
('sarah.smith@example.com', 'Sarah', 'Smith', 'Xyz98765', '2021-09-05', '+1 555-5678', 
    (SELECT city_ID FROM training.city WHERE city_name = 'Budapest'), '1992-11-12', 'master’s degree');

INSERT INTO training.address (street, zip_code, house_nr, city_ID)
VALUES 
('Váci', '1052', 6, (SELECT city_ID FROM training.city WHERE city_name = 'Vancouver')),
('Alexander', 'BC V6A 1B5', 148, (SELECT city_ID FROM training.city WHERE city_name = 'Budapest'));

INSERT INTO training.companies (company_name, legal_form, industry, address_ID)
VALUES 
('Tech Innovators', 'LLC', 'Technology', 
    (SELECT address_ID FROM training.address WHERE street = 'Váci')),
('Green Solutions', 'NPO', 'Environmental', 
    (SELECT address_ID FROM training.address WHERE street = 'Alexander'));

INSERT INTO training.job_listings (role_ID, company_ID, employment_type, contract_type, city_ID, upload_date)
VALUES 
((SELECT role_ID FROM training.role WHERE role_name = 'Software Engineer'),
 (SELECT company_ID FROM training.companies WHERE company_name = 'Tech Innovators'),
 'full time', 'permanent', (SELECT city_ID FROM training.city WHERE city_name = 'Vancouver'), '2025-03-01'),
((SELECT role_ID FROM training.role WHERE role_name = 'Data Analyst'),
 (SELECT company_ID FROM training.companies WHERE company_name = 'Green Solutions'),
 'part time', 'fixed term', (SELECT city_ID FROM training.city WHERE city_name = 'Budapest'), '2025-03-05');

INSERT INTO training.job_applications (candidate_ID, job_ID, application_date, stage)
VALUES 
((SELECT candidate_ID FROM training.candidates WHERE email = 'john.doe@example.com'),
 (SELECT job_ID FROM training.job_listings WHERE employment_type = 'full time' AND upload_date = '2025-03-01'),
 '2025-03-12', 'waiting for review'),
((SELECT candidate_ID FROM training.candidates WHERE email = 'sarah.smith@example.com'),
 (SELECT job_ID FROM training.job_listings WHERE employment_type = 'part time' AND upload_date = '2025-03-05'),
 '2025-03-13', 'waiting for review');

INSERT INTO training.experience (role_ID, duration_months)
VALUES 
((SELECT role_ID FROM training.role WHERE role_name = 'Software Engineer'), 24),
((SELECT role_ID FROM training.role WHERE role_name = 'Data Analyst'), 12);

INSERT INTO training.job_experience (job_ID, exp_ID)
VALUES 
((SELECT job_ID FROM training.job_listings WHERE employment_type = 'part time'), 
 (SELECT exp_ID FROM training.experience WHERE duration_months = 12)),
((SELECT job_ID FROM training.job_listings WHERE employment_type = 'full time'), 
 (SELECT exp_ID FROM training.experience WHERE duration_months = 24));

INSERT INTO training.candidate_experience (candidate_ID, exp_ID)
VALUES 
((SELECT candidate_ID FROM training.candidates WHERE email = 'sarah.smith@example.com'), 
 (SELECT exp_ID FROM training.experience WHERE duration_months = 12)),
((SELECT candidate_ID FROM training.candidates WHERE email = 'john.doe@example.com'), 
 (SELECT exp_ID FROM training.experience WHERE duration_months = 24));

INSERT INTO training.skill (skill_name, proficiency_level, certified, certif_type)
VALUES 
('Python', 'Advanced', FALSE, NULL),
('Spanish', 'C1', TRUE, 'IELTS certificate');

INSERT INTO training.candidate_skill (candidate_ID, skill_ID)
VALUES 
((SELECT candidate_ID FROM training.candidates WHERE email = 'sarah.smith@example.com'),
 (SELECT skill_ID FROM training.skill WHERE skill_name = 'Python')),
((SELECT candidate_ID FROM training.candidates WHERE email = 'john.doe@example.com'),
 (SELECT skill_ID FROM training.skill WHERE skill_name = 'Spanish'));

INSERT INTO training.job_skill (job_ID, skill_ID)
VALUES 
((SELECT job_ID FROM training.job_listings WHERE employment_type = 'part time'),
 (SELECT skill_ID FROM training.skill WHERE skill_name = 'Python')),
((SELECT job_ID FROM training.job_listings WHERE employment_type = 'full time'),
 (SELECT skill_ID FROM training.skill WHERE skill_name = 'Spanish'));

INSERT INTO training.interviewers (first_name, last_name, phone_nr)
VALUES 
('Sarah', 'Johnson', '+1-555-123-4567'),
('David', 'Smith', '+1-555-987-6543');

INSERT INTO training.interviews (candidate_ID, job_ID, interview_round, interview_date, interviewer_ID)
VALUES 
((SELECT candidate_ID FROM training.candidates WHERE email = 'sarah.smith@example.com'),
 5297452, 1, '2025-03-10', 
 (SELECT interviewer_ID FROM training.interviewers WHERE first_name = 'Sarah')),
((SELECT candidate_ID FROM training.candidates WHERE email = 'john.doe@example.com'),
 9926411, 2, '2025-03-20', 
 (SELECT interviewer_ID FROM training.interviewers WHERE first_name = 'David'));

INSERT INTO training.trainers (first_name, last_name, area_of_expertise)
VALUES 
('Sarah', 'Johnson', 'Communications'),
('David', 'Smith', 'HR');

INSERT INTO training.additional_services (service_name, service_level, duration_days, trainer_ID, price_USD)
VALUES 
('Assertive Communications', 'Beginner', 30, 
 (SELECT trainer_ID FROM training.trainers WHERE first_name = 'Sarah'), 200),
('CV workshop', 'Expert', 5, 
 (SELECT trainer_ID FROM training.trainers WHERE first_name = 'David'), 350);

INSERT INTO training.service_applications (service_ID, candidate_ID, date_of_application)
VALUES 
((SELECT service_ID FROM training.additional_services WHERE service_name = 'Assertive Communications'),
 9329, '2025-03-10'),
((SELECT service_ID FROM training.additional_services WHERE service_name = 'CV workshop'),
 1106, '2025-03-12');


