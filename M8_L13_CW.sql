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
       
      
/*1. Oblicz œredni¹ iloœæ jednostek produktów (PRODUCTS) w podziale na regiony z tabeli
PRODUCT_MANUFACTURED_REGION (atrybut region_name). W wynikach wyœwietl
tylko nazwê regionu (REGION_NAME) i obliczon¹ œredni¹. Dane posortuj wed³ug
œredniej malej¹co.*/

SELECT
	   pmr.region_name,
	   avg(p.product_quantity) average_product_quantity
FROM products p  
JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
GROUP BY pmr.region_name 
ORDER BY average_product_quantity DESC;


/*2. Korzystaj¹c z funkcji STRING_AGG, dla ka¿dej nazwy regionu z tabeli
PRODUCT_MANUFACTURED_REGION stwórz listê nazw produktów (product_name)
w tych regionach. SprawdŸ czy wewn¹trz funkcji STRING_AGG mo¿esz u¿yæ ORDER
BY i jak ewentualnie to wp³ynie na wyniki?*/

SELECT pmr.region_name,
	   string_agg(p.product_name,', ' 
	   ORDER BY pmr.region_name, p.product_name ) 
FROM products p 
LEFT JOIN product_manufactured_region pmr  ON p.product_man_region = pmr.id
GROUP BY pmr.region_name;


/*3. Wyœwietl iloœæ sprzedanych produktów COUNT(s.sal_prd_id), które wziê³y udzia³ w
transakcjach sprzeda¿owych, filtruj¹c dane jedynie do regionu EMEA, wed³ug tabeli
PRODUCT_MANUFACTURED_REGION. W danych wynikowych powinien siê znaleŸæ
region (REGION_NAME), nazwa produktu (PRODUCT_NAME) oraz ca³kowita liczba z
danych sprzeda¿owych.*/

SELECT 
	pmr.region_name ,
	p.product_name,
	count(s.sal_prd_id) amount_of_sold_products
FROM sales s 
JOIN products p ON p.id = s.sal_prd_id 
JOIN product_manufactured_region pmr ON  pmr.id = p.product_man_region 
									 AND pmr.region_name = 'EMEA'
GROUP BY pmr.region_name, p.product_name;

/*4. Wyœwietl sumê sprzeda¿y na podstawie danych sprzeda¿owych (SALES) w podziale na
nowy atrybut ROK_MIESIAC stworzony na podstawie kolumny SAL_DATE. Dane
wynikowe posortuj od najwiêkszej do najmniejszej sprzeda¿y.*/

SELECT EXTRACT(YEAR FROM s.sal_date) ||'.'|| EXTRACT(MONTH FROM s.sal_date) year_month_sales,
	sum(s.sal_value) sum_sal_value
FROM sales s 
GROUP BY year_month_sales
ORDER BY sum_sal_value DESC;

/*5. Korzystaj¹c z konstrukcji GROUPING SETS oblicz œredni¹ iloœæ jednostek produktów w
grupach - kod produktu (PRODUCT_CODE), rok produkcji (na podstawie atrybutu
MANUFACTURED_DATE) oraz regionu produkcji (REGION_NAME z tabeli
PRODUCT_MANUFACTURED_REGION). Do danych wynikowych do³ó¿ kolumnê z
grup¹ rekordów korzystaj¹c ze sk³adni GROUPING.*/

SELECT p.product_code, 
	   EXTRACT(YEAR FROM p.manufactured_date) AS year_of_manufactured, 
	   pmr.region_name, 
	   GROUPING(p.product_code, EXTRACT(YEAR FROM p.manufactured_date), pmr.region_name) AS group,
	   avg(p.product_quantity) avarage_of_product_quantity
FROM products p 
JOIN product_manufactured_region pmr ON p.product_man_region  = pmr.id
GROUP BY GROUPING SETS (p.product_code,
						year_of_manufactured,
						pmr.region_name)
ORDER BY p.product_code;
	
/*6. Dla ka¿dego PRODUCT_NAME oblicz sumê iloœci jednostek w podziale na region_name
z tabeli PRODUCT_MANUFACTURED_REGION. Skorzystaj z funkcji okna.
W wynikach wyœwietl: PRODUCT_NAME, PRODUCT_CODE,
MANUFACTURED_DATE, PRODUCT_MAN_REGION, REGION_NAME i obliczon¹
sumê.*/

SELECT p.product_name,
	   p.manufactured_date,
	   p.product_man_region,
	   pmr.region_name,
	   sum(p.product_quantity) OVER (PARTITION BY pmr.region_name) sum_of_product_qty
FROM products p 
JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region;

/*7. Na podstawie zapytania i wyników z zadania 6. Stwórz ranking wed³ug posiadanej iloœci
produktów od najwiêkszej do najmniejszej, w taki sposób, aby w rankingu nie by³o
brakuj¹cych elementów (liczb). W wyniku wyœwietl te produkty, których iloœæ jest 2
najwiêksz¹ iloœci¹. Atrybuty do wyœwietlenia, PRODUCT_NAME, REGION_NAME,
suma iloœci per region (obliczona w zadaniu 6)*/

WITH ranking_per_qty AS (
	SELECT *,
	  dense_rank() OVER (ORDER BY sum_qty_per_region.sum_of_product_qty desc) ranking
	FROM (SELECT p.product_name,
		 	     pmr.region_name,
	   	 	     sum(p.product_quantity) OVER (PARTITION BY pmr.region_name) sum_of_product_qty
	  	FROM products p 
	  	JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region) sum_qty_per_region
)
SELECT ranking_per_qty.product_name,
	   ranking_per_qty.region_name,
	   ranking_per_qty.sum_of_product_qty,
	   ranking_per_qty.ranking
FROM ranking_per_qty
WHERE ranking = 2;

