/* create the database */
CREATE DATABASE baby_weight;

/* Define user permssions */
GRANT ALL PRIVILEGES ON DATABASE baby_weight TO docker;

\connect baby_weight;

/* Application schemas */

CREATE SCHEMA app
  CREATE TABLE children (
    id SERIAL PRIMARY KEY,
    surname varchar(25),
    firstname varchar(25),
    dob date NOT NULL,
    birth_weight int,
    male boolean, -- T| Male; F| Female
    timezone varchar(50) NOT NULL,
    creation_date timestamp with time zone
  )
  CREATE TABLE weights (
    id SERIAL PRIMARY KEY,
    child_id int NOT NULL,
    weight_date date NOT NULL,
    weight int NOT NULL
  );

ALTER DATABASE baby_weight SET search_path TO app, public;

SET search_path TO app, public;

/* Import data */

INSERT INTO children (id, surname, firstname, dob, birth_weight, male, timezone, creation_date)
VALUES (1, 'Stevenson', 'Jeremy', '2020-10-19', 3328, TRUE, 'Australia/Perth', '2020-10-19 00:00:00 AWST');

INSERT INTO weights (id, child_id, weight_date, weight)
VALUES (1, 1, '2020-10-23', 2860),
       (2, 1, '2020-10-24', 2840),
       (3, 1, '2020-10-26', 2895),
       (4, 1, '2020-10-29', 2980),
       (5, 1, '2020-11-02', 3085),
       (6, 1, '2020-11-03', 3120),
       (7, 1, '2020-11-05', 3198),
       (8, 1, '2020-11-09', 3336),
       (9, 1, '2020-11-23', 3935),
       (10, 1, '2020-11-29', 4090),
       (11, 1, '2020-12-15', 4640),
       (12, 1, '2021-02-15', 6494);

 /* Re-set sequences after data upload */

SELECT setval(pg_get_serial_sequence('children', 'id'), MAX(id)) FROM children;
SELECT setval(pg_get_serial_sequence('weights', 'id'), MAX(id)) FROM weights;
