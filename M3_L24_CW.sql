--- Modu� 3 Data Definition Language � Zadania Teoria SQL

/* 
1. Utw�rz nowy schemat o nazwie training.
2. Zmie� nazw� schematu na training_zs;
*/

CREATE SCHEMA training;
ALTER SCHEMA training RENAME TO training_zs;

/*
3. Korzystaj�c z konstrukcji <nazwa_schematy>.<nazwa_tabeli> lub ��cz�c si� do schematu training_zs, utw�rz tabel� wed�ug opisu.
Tabela: products;
Kolumny:
? id - typ ca�kowity,
? production_qty - typ zmiennoprzecinkowy (numeric - 10 znak�w i do 2 znak�w po przecinku)
? product_name - typ tekstowy 100 znak�w (varchar)
? product_code - typ tekstowy 10 znak�w
? description - typ tekstowy nieograniczona ilo�� znak�w
? manufacturing_date - typ data (sama data bez cz�ci godzin, minut, sekund)
*/

CREATE TABLE training_zs.products (
	id integer,
	production_qty NUMERIC(10,2),
	product_name varchar(100),
	product_code varchar(10) ,
	description TEXT,
	manufacturing_date date);
	)

	
--- 4. Korzystaj�c ze sk�adni ALTER TABLE, dodaj klucz g��wny do tabeli products dla pola ID.
ALTER TABLE training_zs.products ADD CONSTRAINT pk_products PRIMARY KEY (id);

--- 5. Korzystaj�c ze sk�adni IF EXISTS spr�buj usun�� tabel� sales ze schematu training_zs

DROP TABLE IF EXISTS training_zs.sales;

/*
 6. W schemacie training_zs, utw�rz now� tabel� sales wed�ug opisu.
Tabela: sales;
Kolumny:
? id - typ ca�kowity, klucz g��wny,
? sales_date - typ data i czas (data + cz�� godziny, minuty, sekundy), to pole ma nie zawiera�
warto�ci nieokre�lonych NULL,
? sales_amount - typ zmiennoprzecinkowy (NUMERIC 38 znak�w, do 2 znak�w po przecinku)
? sales_qty - typ zmiennoprzecinkowy (NUMERIC 10 znak�w, do 2 znak�w po przecinku)
? product_id - typ ca�kowity INTEGER
? added_by - typ tekstowy (nielimitowana ilo�� znak�w), z warto�ci� domy�ln� 'admin'
UWAGA: nie ma tego w materia�ach wideo. Przeczytaj o atrybucie DEFAULT dla kolumny
https://www.postgresql.org/docs/12/ddl-default.html

? Korzystaj�c z definiowania przy tworzeniu tabeli, po definicji kolumn, dodaje ograniczenie o
nazwie sales_over_1k na polu sales_amount typu CHECK takie, �e warto�ci w polu
sales_amount musz� by� wi�ksze od 1000

*/
CREATE TABLE training_zs.sales (
	id integer PRIMARY KEY,
	sales_date timestamp NOT NULL ,
	sales_amount NUMERIC(38,2),
	sales_qty NUMERIC(10,2),
	product_id integer,
	added_by TEXT DEFAULT 'admin',
	CONSTRAINT sales_over_1k CHECK (sales_amount > 1000)
	);

/*
7. Korzystaj�c z operacji ALTER utw�rz powi�zanie mi�dzy tabel� sales a products, jako klucz obcy
pomi�dzy atrybutami product_id z tabeli sales i id z tabeli products. Dodatkowo nadaj kluczowi
obcemu opcj� ON DELETE CASCADE */

ALTER TABLE training_zs.sales ADD CONSTRAINT fkey_sales_products
		FOREIGN KEY (product_id) REFERENCES training_zs.products(id) ON DELETE CASCADE  ;
	
--- 8. Korzystaj�c z polecenia DROP i opcji CASCADE usu� schemat training_zs

DROP SCHEMA  training_zs CASCADE;