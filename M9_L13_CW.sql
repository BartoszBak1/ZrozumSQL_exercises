SET client_encoding = 'UTF8';
DROP TABLE IF EXISTS products, sales, product_manufactured_region CASCADE;

CREATE TABLE products (
	id SERIAL,
	product_name VARCHAR(100),
	product_code VARCHAR(10),
	product_quantity NUMERIC(10,2),	
	manufactured_date DATE,
	product_man_region INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

CREATE TABLE product_manufactured_region (
	id SERIAL,
	region_name VARCHAR(25),
	region_code VARCHAR(10),
	established_year INTEGER
);

INSERT INTO product_manufactured_region (region_name, region_code, established_year)
	  VALUES ('EMEA', 'E_EMEA', 2010),
	  		 ('EMEA', 'W_EMEA', 2012),
	  		 ('APAC', NULL, 2019),
	  		 ('North America', NULL, 2012),
	  		 ('Africa', NULL, 2012);

INSERT INTO products (product_name, product_code, product_quantity, manufactured_date, product_man_region)
     SELECT 'Product '||floor(random() * 10 + 1)::int,
            'PRD'||floor(random() * 10 + 1)::int,
            random() * 10 + 1,
            CAST((NOW() - (random() * (interval '90 days')))::timestamp AS date),
            CEIL(random()*(10-5))::int
       FROM generate_series(1, 10) s(i);  
      
INSERT INTO sales (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 10000) s(i);   
       
      
      
/*1. Przygotuj widok bazodanowy na podstawie danych sprzeda¿owych SALES, który bêdzie
przedstawia³ dane za ostatni kwarta³ roku 2020, dla wszystkich produktów bior¹cych
udzia³ w transakcjach sprzeda¿owych wytworzonych w regionie EMEA. */
   
CREATE OR REPLACE VIEW sales_for_4qaur_2020 AS 
	SELECT s.*,
		  pmr.region_name	  
	FROM sales s
	JOIN products p ON p.id = s.sal_prd_id 
	JOIN product_manufactured_region pmr ON pmr.id  = p.product_man_region 
										 AND pmr.region_name = 'EMEA'
	WHERE EXTRACT(YEAR FROM s.sal_date) = 2020
			AND
		  EXTRACT(QUARTER FROM s.sal_date) = 4;
		 
DROP VIEW sales_for_4qaur_2020;
      
/*2. Zmieñ zapytanie z zadania pierwszego w taki sposób, aby w wynikach dodatkowo,
obliczyæ sumê sprzeda¿y w podziale na kod produktu (product_code) sortowane wed³ug
daty sprzeda¿y (sal_date), wynik wyœwietl dla ka¿dego wiersza (OVER). 
Tak przygotowane zapytanie wykorzystaj do stworzenia widoku zmaterializowanego,
 który bêdzie móg³ byæ odœwie¿any równolegle (CONCURRENTLY).*/
      
 CREATE MATERIALIZED VIEW sales_sum_for_4q_2020 AS 
 	SELECT s.*,
 		   pmr.region_name,
 		   p.product_code,
 		   sum(s.sal_value) OVER (PARTITION BY p.product_code ORDER BY s.sal_date) AS sum_sales_per_product_code
 	FROM sales s
	JOIN products p ON p.id = s.sal_prd_id 
	JOIN product_manufactured_region pmr ON pmr.id  = p.product_man_region 
										 AND pmr.region_name = 'EMEA'
	WHERE EXTRACT(YEAR FROM s.sal_date) = 2020
			AND
		  EXTRACT(QUARTER FROM s.sal_date) = 4
	WITH DATA ;

CREATE UNIQUE INDEX index_view_sales_sum_for_4q_2020 ON sales_sum_for_4q_2020(id);
REFRESH MATERIALIZED VIEW CONCURRENTLY sales_sum_for_4q_2020 ;

DROP  MATERIALIZED VIEW IF EXISTS sales_sum_for_4q_2020;

/*3. Stwórz zapytanie, w którego wynikach znajd¹ siê atrybuty: PRODUCT_CODE,
REGION_NAME i tablica zawieraj¹ nazwy produktów (PRODUCT_NAME) dla
wszystkich produktów z tabeli PRODUCTS.*/

SELECT p.product_name,
	   pmr.region_name,
	   array_agg(p.product_name) AS product_name_list
FROM products p 
JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
GROUP BY p.product_name, pmr.region_name;

/*4. Dla zapytania z zdania 3 stwórz now¹ tabelê korzystaj¹c z konstrukcji CTAS. Dodaj
dodatkowo do nowej tabeli 1 kolumnê zawieraj¹c¹ wartoœæ TRUE lub FALSE obliczan¹
na podstawie danych z atrybutu tablicy nazw produktów dla kodu i regionu (zadanie 3)
w taki sposób, ¿e gdy tablica zawiera wiêcej ni¿ 1 element wartoœæ ma byæ TRUE, w
przeciwnym razie FALSE.*/
 	   
CREATE TABLE prd_reg_list AS 
SELECT p.product_name,
	   	pmr.region_name,
	   	array_agg(p.product_name ) AS product_name_list,
	   	CASE 
	   	  WHEN array_length(array_agg(p.product_name ),1) > 1
	   	       THEN TRUE 
	   	       ELSE FALSE 
	   	END  is_more_than_1_element
FROM products p 
JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
GROUP BY p.product_name, pmr.region_name;

DROP TABLE IF EXISTS prd_reg_list;

/*5. Stwórz now¹ tabelê SALES_ARCHIVE (jako zwyk³y CREATE TABLE nie CTAS), która
bêdzie mia³a strukturê na podstawie tabeli SALES z wyj¹tkami:
- nowy atrybut: operation_type VARCHAR(1) NOT NULL
- nowy atrybut: archived_at TIMESTAMP z automatycznym przypisywaniem
wartoœci NOW()
- atrybut created_date powinien byæ usuniêty*/
      
CREATE TABLE IF NOT EXISTS sales_archive (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	operation_type VARCHAR(1) NOT NULL,
	archived_at TIMESTAMP DEFAULT now());


/*6. Dla tabeli stworzonej w zadaniu 5, utwórz TRIGGER + FUNKCJE DLA TRIGGERA, który
w momencie usuwania, lub aktualizacji wierszy w tabeli SALES, wstawi informacjê o
poprzedniej wartoœci do tabeli SALES_ARCHIVE. Po przypisaniu TRIGGERA, usuñ z
tabeli SALES wszystkie dane sprzeda¿owe z PaŸdziernika 2020 (10.2020). */

CREATE OR REPLACE FUNCTION archive_sales_function() 
   RETURNS TRIGGER 
   LANGUAGE plpgsql
	AS $$ 
		BEGIN 
			IF (TG_OP = 'DELETE') THEN 
				INSERT INTO sales_archive(sal_description, sal_date,sal_value, sal_prd_id,operation_type )
				VALUES (OLD.sal_description, OLD.sal_date, OLD.sal_value, OLD.sal_prd_id,'D');
			ELSEIF (TG_OP = 'UPDATE') THEN 
				INSERT INTO sales_archive(sal_description, sal_date,sal_value, sal_prd_id,operation_type )
				VALUES (OLD.sal_description, OLD.sal_date, OLD.sal_value, OLD.sal_prd_id,'U');
			END IF; 
		RETURN NULL;
		END;
	   $$;
	  
CREATE TRIGGER archive_sales_trigger
		AFTER DELETE OR UPDATE 
		ON sales
		FOR EACH ROW 
		EXECUTE PROCEDURE archive_sales_function();
		
DELETE FROM sales WHERE EXTRACT(MONTH FROM sales.sal_date) =10
				AND EXTRACT(YEAR FROM sales.sal_date) = 2020;
			
SELECT *
FROM sales_archive;

DROP TABLE IF EXISTS products, product_manufactured_region, sales,sales_archive CASCADE;
DROP FUNCTION archive_sales_function;
