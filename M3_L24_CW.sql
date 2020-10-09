--- Modu³ 3 Data Definition Language – Zadania Teoria SQL

/* 
1. Utwórz nowy schemat o nazwie training.
2. Zmieñ nazwê schematu na training_zs;
*/

CREATE SCHEMA training;
ALTER SCHEMA training RENAME TO training_zs;

/*
3. Korzystaj¹c z konstrukcji <nazwa_schematy>.<nazwa_tabeli> lub ³¹cz¹c siê do schematu training_zs, utwórz tabelê wed³ug opisu.
Tabela: products;
Kolumny:
? id - typ ca³kowity,
? production_qty - typ zmiennoprzecinkowy (numeric - 10 znaków i do 2 znaków po przecinku)
? product_name - typ tekstowy 100 znaków (varchar)
? product_code - typ tekstowy 10 znaków
? description - typ tekstowy nieograniczona iloœæ znaków
? manufacturing_date - typ data (sama data bez czêœci godzin, minut, sekund)
*/

CREATE TABLE training_zs.products (
	id integer,
	production_qty NUMERIC(10,2),
	product_name varchar(100),
	product_code varchar(10) ,
	description TEXT,
	manufacturing_date date);
	)

	
--- 4. Korzystaj¹c ze sk³adni ALTER TABLE, dodaj klucz g³ówny do tabeli products dla pola ID.
ALTER TABLE training_zs.products ADD CONSTRAINT pk_products PRIMARY KEY (id);

--- 5. Korzystaj¹c ze sk³adni IF EXISTS spróbuj usun¹æ tabelê sales ze schematu training_zs

DROP TABLE IF EXISTS training_zs.sales;

/*
 6. W schemacie training_zs, utwórz now¹ tabelê sales wed³ug opisu.
Tabela: sales;
Kolumny:
? id - typ ca³kowity, klucz g³ówny,
? sales_date - typ data i czas (data + czêœæ godziny, minuty, sekundy), to pole ma nie zawieraæ
wartoœci nieokreœlonych NULL,
? sales_amount - typ zmiennoprzecinkowy (NUMERIC 38 znaków, do 2 znaków po przecinku)
? sales_qty - typ zmiennoprzecinkowy (NUMERIC 10 znaków, do 2 znaków po przecinku)
? product_id - typ ca³kowity INTEGER
? added_by - typ tekstowy (nielimitowana iloœæ znaków), z wartoœci¹ domyœln¹ 'admin'
UWAGA: nie ma tego w materia³ach wideo. Przeczytaj o atrybucie DEFAULT dla kolumny
https://www.postgresql.org/docs/12/ddl-default.html

? Korzystaj¹c z definiowania przy tworzeniu tabeli, po definicji kolumn, dodaje ograniczenie o
nazwie sales_over_1k na polu sales_amount typu CHECK takie, ¿e wartoœci w polu
sales_amount musz¹ byæ wiêksze od 1000

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
7. Korzystaj¹c z operacji ALTER utwórz powi¹zanie miêdzy tabel¹ sales a products, jako klucz obcy
pomiêdzy atrybutami product_id z tabeli sales i id z tabeli products. Dodatkowo nadaj kluczowi
obcemu opcjê ON DELETE CASCADE */

ALTER TABLE training_zs.sales ADD CONSTRAINT fkey_sales_products
		FOREIGN KEY (product_id) REFERENCES training_zs.products(id) ON DELETE CASCADE  ;
	
--- 8. Korzystaj¹c z polecenia DROP i opcji CASCADE usuñ schemat training_zs

DROP SCHEMA  training_zs CASCADE;