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



/*1. Korzystaj�c z konstrukcji INNER JOIN po��cz dane sprzeda�owe (SALES, sal_prd_id) z
danymi o produktach (PRODUCTS, id). W wynikach poka� tylko te produkty, kt�re
powsta�y w regionie EMEA. Wyniki ogranicz do 100 wierszy. */

SELECT s.*,
       p.*,
       pmr.*
  FROM sales s
  JOIN products p ON p.id = s.sal_prd_id 
  JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
    								   AND pmr.region_name = 'EMEA'
  LIMIT 100;     

SELECT s.*,
       p.*,
       pmr.*
  FROM sales s
  JOIN products p ON p.id = s.sal_prd_id 
  JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
WHERE  pmr.region_name = 'EMEA' 
LIMIT 100;    


/*2. Korzystaj�c z konstrukcji LEFT JOIN po��cz dane o produktach (PRODUCTS,
product_man_region) z danymi o regionach w kt�rych produkty powsta�y
(PRODUCT_MANUFACTURED_REGION, id)
W wynikach wy�wietl wszystkie atrybuty z tabeli produkt�w i atrybut REGION_NAME
z tabeli PRODUCT_MANUFACTURED_REGION. Dodatkowo w trakcie z��czenia
ogranicz dane brane przy z��czenia do tych region�w, kt�re zosta�y za�o�one po 2012
roku.*/


SELECT p.*, pmr.*
FROM products p
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
										AND pmr.established_year > 2012;
																	
/*3. Korzystaj�c z konstrukcji LEFT JOIN po��cz dane o produktach (PRODUCTS,
product_man_region) z danymi o regionach w kt�rych produkty powsta�y
(PRODUCT_MANUFACTURED_REGION, id).
W wynikach wy�wietl wszystkie atrybuty z tabeli produkt�w i atrybut REGION_NAME
z tabeli PRODUCT_MANUFACTURED_REGION.
Dodatkowo wyfiltruj dane wynikowe taki spos�b, aby pokaza� tylko te produkty, dla
kt�rych regiony, w kt�rych powsta�y zosta�y za�o�one po 2012 roku.
Por�wnaj te wyniki z wynikami z zadania 2.*/

SELECT p.*, pmr.*
FROM products p
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
WHERE pmr.established_year > 2012;

-- po przefiltrowaniu dostajemy tylko 2 rekordy bez wartosci null-owych  w koumnie established_year
									
/*4. Korzystaj�c z konstrukcji RIGHT JOIN po��cz dane sprzeda�owe (SALES, sal_prd_id) z
podzapytaniem, w kt�rych dla danych produktowych uwzgl�dnij tylko te produkty
(PRODUCTS, id), kt�rych ilo�� jednostek jest wi�ksza od 5 (product_quantity).
W wynikach wy�wietl unikatow� nazw� produktu (product_name) oraz z��czeniem
ROK_MIESI�C z danych sprzeda�owych - data sprzeda�y.
Dane posortuj wed�ug pierwszej kolumny malej�co.*/ 

SELECT DISTINCT 
	pr.product_name, 
	EXTRACT (YEAR FROM s.sal_date) || '-' || EXTRACT (MONTH FROM s.sal_date) AS year_month_sal
FROM sales s
RIGHT JOIN (SELECT p.*
			FROM products p
			WHERE p.product_quantity > 5) pr ON s.sal_prd_id = pr.id
ORDER BY 1 DESC;

/*5. Dodaj nowy region do tabeli PRODUCT_MANUFACTURED_REGION. 
Nast�pnie korzystaj�c z konstrukcji FULL JOIN po��cz dane o produktach
(PRODUCTS,product_man_region) z danymi o regionach produkt�w w kt�rych
zosta�y one stworzone (PRODUCT_MANUFACTURED_REGION, id)
Wy�wietl w wynikach wszystkie atrybuty z obu tabel. */

INSERT INTO product_manufactured_region (region_name, region_code, established_year)
     VALUES ('South America', NULL, 2020);
SELECT p.*, pmr.*
FROM products p 
FULL JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id ;

/*6. Uzyskaj te same wyniki, co w zadaniu 5 dla stworzonego zapytania, tym razem nie
korzystaj ze sk�adni FULL JOIN. Wykorzystaj INNER JOIN / LEFT / RIGHT JOIN lub
inne cz�ci SQL-a, kt�re znasz :) */

SELECT p.*, pmr.*
FROM products p 
RIGHT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
UNION 
SELECT p.*, pmr2.*
FROM products p 
LEFT JOIN product_manufactured_region pmr2 ON p.product_man_region = pmr2.id
;

/*7. Wykorzystaj konstrukcj� WITH i zmie� Twoje zapytanie z zadania 4 w taki spos�b, aby
podzapytanie znalaz�o si� w sekcji CTE (common table expression = WITH) zapytania. */

WITH product_quantity_mor_than_5 AS (SELECT p.*
			FROM products p
			WHERE p.product_quantity > 5)
SELECT DISTINCT 
	pqm.product_name, 
	EXTRACT (YEAR FROM s.sal_date) || '-' || EXTRACT (MONTH FROM s.sal_date) AS year_month_sal
FROM sales s
RIGHT JOIN product_quantity_mor_than_5 pqm ON s.sal_prd_id = pqm.id
ORDER BY 1 DESC;

/*8. Usu� wszystkie te produkty (PRODUCTS), kt�re s� przypisane do regionu EMEA i kodu
E_EMEA.
Skorzystaj z konstrukcji USING lub EXISTS.*/

DELETE FROM products p
	WHERE EXISTS (SELECT 1 
				FROM products p1
				JOIN product_manufactured_region pmr ON p.id = p1.id
					   									  AND pmr.id = p1.product_man_region 
					  									  AND pmr.region_name = 'EMEA'
					   									  AND pmr.region_code = 'E_EMEA')
  RETURNING *;
 
/*9. OPCJONALNE: Korzystaj�c z konstrukcji WITH RECURSIVE stw�rz ci�g Fibonacciego,
kt�rego wyniki b�d� ograniczone do warto�ci poni�ej 100.*/
 
WITH RECURSIVE fibonacci_sequence(f,n) AS (
  VALUES (0,1)
  UNION ALL
  SELECT n+f,f
    FROM fibonacci_sequence
   WHERE n + f < 100
) SELECT f FROM fibonacci_sequence;
 
 