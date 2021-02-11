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


 /*    1. Przygotuj zapytanie wyœwietlaj¹ce dane sprzeda¿owe za okres ostatnich 2 miesiêcy (skorzystaj ze sk³adni INTERVAL).
 W wyniku wyœwietl wszystkie atrybuty sprzeda¿owe i dodatkowo nazwê i kod produktu oraz region, w którym produkt powsta³.
Dane wyœwietl wy³¹cznie dla kodu produktu równego PRD8.*/

SELECT p.product_name,
	   p.product_code,
	   pmr.region_name,
	   s.*
FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
WHERE s.sal_date BETWEEN now()- (INTERVAL '2 months') AND now() 
	AND p.product_code = 'PRD9';

/*2. Korzystaj¹c z opcji EXPLAIN ANALYZE, przeanalizuj plan zapytania dla zapytania z zadania 1. 
Rozpisz, z jakich elementów siê sk³ada: rodzaj u¿ytego algorytmu, koszty na poszczególnych etapach, jaki rodzaj pobierania danych zosta³ wykorzystany
(sekwencyjne skanowanie czy indeksy). */

DISCARD ALL;
EXPLAIN ANALYZE 
SELECT p.product_name,
	   p.product_code,
	   pmr.region_name,
	   s.*
FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
WHERE s.sal_date BETWEEN now()- (INTERVAL '2 months') AND now() 
	 AND  p.product_code = 'PRD9';

/*

Execution Time: 7.307 ms
algorym ³¹czenia hash join
sekwencyjne przechodzenie przez tabele  "Seq Scan"
liczba wierszy na wyjsciu rows = 1059
do zbudowania tabeli zosta³o wykorzystane 9 kB

 */

/*3. Oblicz miarê selektywnoœci dla atrybutu PRODUCT_CODE z tabeli PRODUCTS.*/

SELECT count(DISTINCT product_code)::float / count(product_code) AS selektywnoœæ 
FROM products; 

/*4. Dodaj indeks do tabeli PRODUCTS na polu PRODUCT_CODE typu BTREE.*/
CREATE INDEX idx_products_product_code ON products USING btree (product_code);

/*5. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy indeks zosta³ u¿yty?*/
DISCARD ALL;
EXPLAIN ANALYZE 
SELECT p.product_name,
	   p.product_code,
	   pmr.region_name,
	   s.*
FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
WHERE s.sal_date BETWEEN now()- (INTERVAL '2 months') AND now() 
	AND p.product_code = 'PRD9';

/*
Execution Time: 6.497 ms
indeks nie zosta³ u¿yty 
 */
/*6. Dodaj indeks dla daty sprzeda¿y (SAL_DATE) na tabeli SALES.*/
CREATE INDEX idx_sales_sal_date ON sales USING btree (sal_date);

/*7. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy
indeks dla SAL_DATE lub PRODUCT_CODE zosta³ u¿yty?*/
DISCARD ALL;
EXPLAIN ANALYZE 
SELECT p.product_name,
	   p.product_code,
	   pmr.region_name,
	   s.*
FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
WHERE s.sal_date BETWEEN now()- (INTERVAL '2 months') AND now() 
	AND p.product_code = 'PRD9';

/*
 
Execution Time: 7.081 ms
index nie zosta³ u¿yty
 */

/* 8. Na podstawie instrukcji poni¿ej zweryfikuj czy partycjonowanie tabeli ma istotny wp³yw
na plan wykonania zapytania i operacjê INSERT. (ten skrypt znajduje siê równie¿ w linku
powy¿ej). */
      
DROP TABLE IF EXISTS  sales, sales_partitioned CASCADE;

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);
 
 
CREATE TABLE sales_partitioned (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
) PARTITION BY RANGE (sal_date);

CREATE TABLE sales_y2018 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE sales_y2019 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
   
CREATE TABLE sales_y2020 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
   
CREATE TABLE sales_y2022 PARTITION OF sales_partitioned
	FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

EXPLAIN ANALYZE
INSERT INTO sales (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);  
      


EXPLAIN ANALYZE
INSERT INTO sales_partitioned (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);
      
      
/*

Dla tabeli sales: 			  Execution Time: 6405.123 ms
Dla tabeli sales_partitioned: Execution Time: 8334.565 ms

Wykonanie zapytania bez partycjonowania trwa ok 2 sekundy krócej. 

 */  
      
      
      
      
      
      
      
      
      
      
      
      

-- CZÊŒC POTRZEBNA DO ZADANIA 8 Z TEORII SQL
DROP TABLE sales, sales_partitioned CASCADE;

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);
 
 
CREATE TABLE sales_partitioned (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
) PARTITION BY RANGE (sal_date);

CREATE TABLE sales_y2018 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE sales_y2019 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
   
CREATE TABLE sales_y2020 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

EXPLAIN ANALYZE
INSERT INTO sales (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);     

EXPLAIN ANALYZE
INSERT INTO sales_partitioned (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);