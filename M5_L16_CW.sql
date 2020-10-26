-- 1. Utw�rz nowy schemat dml_exercises
CREATE SCHEMA dml_exercises;

/* 2. Utw�rz now� tabel� sales w schemacie dml_exercises wed�ug opisu:
Tabela: sales;
Kolumny:
* id - typ SERIAL, klucz g��wny,
* sales_date - typ data i czas (data + cz�� godziny, minuty, sekundy), to pole ma nie
zawiera� warto�ci nieokre�lonych NULL,
* sales_amount - typ zmiennoprzecinkowy (NUMERIC 38 znak�w, do 2 znak�w po
przecinku)
* sales_qty - typ zmiennoprzecinkowy (NUMERIC 10 znak�w, do 2 znak�w po przecinku)
* added_by - typ tekstowy (nielimitowana ilo�� znak�w), z warto�ci� domy�ln� 'admin'
* korzystaj�c z definiowania przy tworzeniu tabeli, po definicji kolumn, dodaje
ograniczenie o nazwie sales_less_1k na polu sales_amount typu CHECK takie, �e
warto�ci w polu sales_amount musz� by� mniejsze lub r�wne 1000 */

CREATE TABLE dml_exercises.sales(
	id Serial PRIMARY KEY,
	sales_date timestamp NOT NULL,
	sales_amount NUMERIC(38,2),
	sales_qty NUMERIC(10,2),
	added_by TEXT DEFAULT 'admin',
	CONSTRAINT sales_less_1k CHECK (sales_amount<=1000));

/* 3. Dodaj to tabeli kilka wierszy korzystaj�c ze sk�adni INSERT INTO
3.1 Tak, aby id by�o generowane przez sekwencj�
3.2 Tak by pod pole added_by wpisa� warto�� nieokre�lon� NULL
3.3 Tak, aby sprawdzi� zachowanie ograniczenia sales_less_1k, gdy wpiszemy warto�ci wi�ksze od 1000 */

INSERT INTO dml_exercises.sales(sales_date,sales_amount,sales_qty,added_by)
						  VALUES('21.9.2020 14:56:25',1000,10,NULL),
							('12.10.2020 10:50:25',560,5,NULL),
							('15.6.2019 11:30:55',100,2,NULL),
							('30.1.2019 16:16:15',800,8,NULL);
-- je�li warto�� sales_amount > 1000 zostanie zwr�cony error
						   

/* 4. Co zostanie wstawione, jako format godzina (HH), minuta (MM), sekunda (SS), w polu
sales_date, jak wstawimy do tabeli nast�puj�cy rekord.
INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
 								VALUES ('20/11/2019', 101, 50, NULL); */
						
INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
 								VALUES ('20/11/2019', 101, 50, NULL);
-- zostanie wstawiona data 2019-11-20 00:00:00 
/*
5. Jaka b�dzie warto�� w atrybucie sales_date, po wstawieniu wiersza jak poni�ej. Jak
zintepretujesz miesi�c i dzie�, �eby mie� pewno��, o jaki konkretnie chodzi.
INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
 VALUES ('04/04/2020', 101, 50, NULL); 
 */
 INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
 						  VALUES ('04/04/2020', 101, 50, NULL); 
SHOW datestyle;

 -- zostanie wstawiona data 2020-04-04 00:00:00
 						 
--6. Dodaj do tabeli sales wstaw wiersze korzystaj�c z poni�szego polecenia

INSERT INTO dml_exercises.sales (sales_date, sales_amount, sales_qty,added_by)
 SELECT NOW() + (random() * (interval '90 days')) + '30 days',
 random() * 500 + 1,
 random() * 100 + 1,
 NULL
 FROM generate_series(1, 20000) s(i);

/* 7. Korzystaj�c ze sk�adni UPDATE, zaktualizuj atrybut added_by, wpisuj�c mu warto�� 'sales_over_200',
gdy warto�� sprzeda�y (sales_amount jest wi�ksza lub r�wna 200) */

UPDATE dml_exercises.sales 
	SET added_by = 'sales_over_200' 
	WHERE sales_amount >= 200;

/* SELECT * FROM dml_exercises.sales 
ORDER BY sales_amount DESC; */

/* 8. Korzystaj�c ze sk�adni DELETE, usu� te wiersze z tabeli sales, dla kt�rych warto�� w polu
added_by jest warto�ci� nieokre�lon� NULL. Sprawd� r�nic� mi�dzy zapisemm added_by = NULL, a added_by IS NULL*/
DELETE FROM dml_exercises.sales
	WHERE added_by = NULL; -- nie usune�o danych

DELETE FROM dml_exercises.sales
	WHERE added_by IS NULL;

SELECT * FROM dml_exercises.sales ;

-- 9. Wyczy�� wszystkie dane z tabeli sales i zrestartuj sekwencje

TRUNCATE TABLE dml_exercises.sales RESTART IDENTITY;


/* 10. DODATKOWE ponownie wstaw do tabeli sales wiersze jak w zadaniu 4.
Utw�rz kopi� zapasow� tabeli do pliku. Nast�pnie usu� tabel� ze schematu dml_exercises i odtw�rz j� z kopii zapasowej. */

INSERT INTO dml_exercises.sales (sales_date, sales_amount, sales_qty,added_by)
 SELECT NOW() + (random() * (interval '90 days')) + '30 days',
 random() * 500 + 1,
 random() * 100 + 1,
 NULL
 FROM generate_series(1, 20000) s(i);
 
/*pg_dump --host localhost ^
        --port 5432 ^
        --username postgres ^
        --format d ^
        --file "D:\PostgreSQL_dump\db_postgres_dump" ^
        --table dml_exercises.sales ^
        postgres */

/*pg_restore --host localhost ^
           --port 5432 ^
           --username postgres ^
           --dbname postgres ^
           --clean ^
           "D:\PostgreSQL_dump\db_postgres_dump"   */