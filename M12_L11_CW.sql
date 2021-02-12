SET client_encoding = 'UTF8'; 



/*
 1. Korzystaj�c z tabel administracyjnych bazy danych. Stw�rz zapytanie, kt�rego
wynikiem b�dzie lista obiekt�w:
Tabel, widok�w, indeks�w, typem (t dla tabeli, v dla widoku, i dla indeksu) razem
z ich w�a�cicielami i schematem, w jakim si� znajduj�.
*/

SELECT  schemaname,	
		tablename,
		tableowner,
		'T' AS object_type
FROM pg_catalog.pg_tables pt
UNION All
SELECT  schemaname ,
		viewname,
		viewowner,
		'V' AS object_type
FROM pg_catalog.pg_views pv
UNION All
SELECT 
	schemaname,
	tablename,
	indexname,
	'I' AS object_type
FROM pg_catalog.pg_indexes pi2;

/*2. Korzystaj�c z dodatku pgcrypto (lub z odpowiadaj�cych funkcji w Twojej bazie danych).
Zaszyfruj tekst 'ultraSilneHa3l0$567' korzystaj�c z opcji ENCRYPT (pami�taj o rzutowaniu na typ bytea - ::bytea lub CAST(xxx as bytea)) or CRYPT
Nast�pnie przedstaw spos�b, sprawdzania has�a w sytuacji logowania u�ytkownika (DECRYPT / CRYPT) */

CREATE TABLE user1 (
user_name VARCHAR(100),
user_password VARCHAR(100),
user_password_secret VARCHAR(100))
;

INSERT INTO user1(user_name, user_password) VALUES 
	('name','ultraSilneHa3l0$567');

CREATE EXTENSION pgcrypto;
UPDATE user1 SET user_password_secret = crypt(user_password, gen_salt('md5'));

SELECT * FROM user1;

SELECT 
	user_name,
	user_password_secret = crypt(user_password,user_password_secret) AS correct_password
FROM user1;
 
 
/*3. Dla danych z tabeli CUSTOMERS (skrypt poni�ej), wykorzystaj znane Ci techniki anonimizowania danych.
a. Pozb�d� si� duplikat�w.
b. Nie pokazuj ca�ego adresu email, tylko domen� firmy (np. X@polska.pl) - dla znalezienie domeny mailowej mo�esz wykorzysta� REGEX - '@(.*)$'
 (w substring lub REGEXP_MATCH)
c. Poka� tylko 3 ostatniej cyfry numeru telefonu (reszt� zast�p X-ami)
 */

DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
	id SERIAL,
	c_name TEXT,
	c_mail TEXT,
	c_phone VARCHAR(9),
	c_description TEXT
);
INSERT INTO customers (c_name, c_mail, c_phone, c_description) VALUES 
	('Krzysztof Bury', 'kbur@domein.pl', '123789456', left(md5(random()::text), 15)),
	('Onufry Zag�oba', 'zagloba@ogniemimieczem.pl', '100000001', left(md5(random()::text), 15)),
	('Krzysztof Bury', 'kbur@domein.pl', '123789456', left(md5(random()::text), 15)),
	('Pan Wo�odyjowski', 'p.wolodyj@polska.pl', '987654321', left(md5(random()::text), 15)),
	('Micha� Skrzetuski', 'michal<at>zamek.pl', '654987231', left(md5(random()::text), 15)),
	('Bohun Tuhajbejowicz', NULL, NULL, left(md5(random()::text), 15));
	

SELECT DISTINCT c_name,
				REGEXP_MATCHES(c_mail, '@(.*)$', 'g') AS domena,
				'XXX-XXX-' || substring(c_phone, length(c_phone) - 2) AS phone_number,
				c_description				
FROM customers;




