--- Modu³ 6 Data Query Language – Zadania Teoria SQL

DROP TABLE IF EXISTS products;
CREATE TABLE products (
id SERIAL,
product_name VARCHAR(100),
product_code VARCHAR(10),
product_quantity NUMERIC(10,2),
manufactured_date DATE,
added_by TEXT DEFAULT 'admin',
created_date TIMESTAMP DEFAULT now()
);

INSERT INTO products (product_name, product_code, product_quantity,
manufactured_date)
 SELECT 'Product '||floor(random() * 10 + 1)::int,
 'PRD'||floor(random() * 10 + 1)::int,
 random() * 10 + 1,
 CAST((NOW() - (random() * (interval '90 days')))::timestamp AS date)
 FROM generate_series(1, 10) s(i);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
id SERIAL,
sal_description TEXT,
sal_date DATE,
sal_value NUMERIC(10,2),
sal_qty NUMERIC(10,2),
sal_product_id INTEGER,
added_by TEXT DEFAULT 'admin',
created_date TIMESTAMP DEFAULT now()
);

INSERT INTO sales (sal_description, sal_date, sal_value, sal_qty, sal_product_id)
 SELECT left(md5(i::text), 15),
 CAST((NOW() - (random() * (interval '60 days'))) AS DATE),
 random() * 100 + 1,
 floor(random() * 10 + 1)::int,
 floor(random() * 10)::int
 FROM generate_series(1, 10000) s(i);

-- 1. Wyœwietl unikatowe daty stworzenia produktów (wed³ug atrybutu manufactured_date)

SELECT DISTINCT ON (manufactured_date) manufactured_date 
FROM products;


-- 2. Jak sprawdzisz czy 10 wstawionych produktów to 10 unikatowych kodów produktów?

SELECT  count(product_code) number_of_product_code, count(DISTINCT products.product_code) number_of_unique_product_code
FROM  products;

-- 3. Korzystaj¹c ze sk³adni IN wyœwietl produkty od kodach PRD1 i PRD9

SELECT *
FROM products
WHERE product_code IN ('PRD1', 'PRD9');

/*4. Wyœwietl wszystkie atrybuty z danych sprzeda¿owych, takie ¿e data sprzeda¿y jest w
zakresie od 1 sierpnia 2020 do 31 sierpnia 2020 (w³¹cznie). Dane wynikowe maj¹ byæ
posortowane wed³ug wartoœci sprzeda¿y malej¹co i daty sprzeda¿y rosn¹co.*/

SELECT *
FROM sales
WHERE sales.sal_date BETWEEN '2020-08-01' AND '2020-08-31'
ORDER BY sales.sal_value DESC , sales.sal_date ASC;

/* 5. Korzystaj¹c ze sk³adni NOT EXISTS wyœwietl te produkty z tabeli PRODUCTS, które nie
bior¹ udzia³u w transakcjach sprzeda¿owych (tabela SALES). ID z tabeli Products i
SAL_PRODUCT_ID to klucz ³¹czenia.*/

SELECT *
FROM products p 
WHERE NOT EXISTS (SELECT 1
					FROM sales s
					WHERE s.sal_product_id = p.id);



/* 6. Korzystaj¹c ze sk³adni ANY i operatora = wyœwietl te produkty, których wystêpuj¹ w
transakcjach sprzeda¿owych (wed³ug klucza Products ID, Sales SAL_PRODUCT_ID)
takich, ¿e wartoœæ sprzeda¿y w transakcji jest wiêksza od 100.*/

SELECT *
FROM products p
WHERE p.id = ANY(SELECT 1
		   FROM sales s
		   WHERE  s.sal_value>100);
				
/*7. Stwórz now¹ tabelê PRODUCTS_OLD_WAREHOUSE o takich samych kolumnach jak
istniej¹ca tabela produktów (tabela PRODUCTS). Wstaw do nowej tabeli kilka wierszy -
dowolnych wed³ug Twojego uznania.*/
		  
DROP TABLE IF EXISTS products_old_warehouse;
CREATE TABLE products_old_warehouse (id SERIAL,
product_name VARCHAR(100),
product_code VARCHAR(10),
product_quantity NUMERIC(10,2),
manufactured_date DATE,
added_by TEXT DEFAULT 'admin',
created_date TIMESTAMP DEFAULT now()
);

INSERT INTO products_old_warehouse (product_name, product_code, product_quantity,
manufactured_date)
 SELECT 'Product '||floor(random() * 10 + 1)::int,
 'PRD'||floor(random() * 10 + 1)::int,
 random() * 10 + 1,
 CAST((NOW() - (random() * (interval '90 days')))::timestamp AS date)
 FROM generate_series(1, 5) s(i);
		  
/*8. Na podstawie tabeli z zadania 7, korzystaj¹c z operacji UNION oraz UNION ALL po³¹cz
tabelê PRODUCTS_OLD_WAREHOUSE z 5 dowolnym produktami z tabeli
PRODUCTS, w wyniku wyœwietl jedynie nazwê produktu (kolumna PRODUCT_NAME)
i kod produktu (kolumna PRODUCT_CODE). Czy w przypadku wykorzystania UNION
jakieœ wierszy zosta³y pominiête?*/

SELECT p.product_name , p.product_code 
FROM (SELECT product_name , product_code
		FROM products
		LIMIT 5) p
UNION 
SELECT pow.product_name, pow.product_code 
FROM products_old_warehouse pow; 

SELECT p.product_name , p.product_code 
FROM products p 
UNION ALL
SELECT pow.product_name, pow.product_code 
FROM products_old_warehouse pow; 

-- UNION ³¹czy bez powielania tych samych wartoœci, UNION ALL nie usuwa duplikatów
/* 9. Na podstawie tabeli z zadania 7, korzystaj¹c z operacji EXCEPT znajdŸ ró¿nicê zbiorów
pomiêdzy tabel¹ PRODUCTS_OLD_WAREHOUSE a PRODUCTS, w wyniku wyœwietl
jedynie kod produktu (kolumna PRODUCT_CODE).*/

SELECT product_code 
FROM products p 
EXCEPT 
SELECT product_code
FROM products_old_warehouse pow ;


/*10. Wyœwietl 10 rekordów z tabeli sprzeda¿owej sales. Dane powinny byæ posortowane
wed³ug wartoœci sprzeda¿y (kolumn SAL_VALUE) malej¹co. */

SELECT *
FROM sales s 
ORDER BY s.sal_value DESC
LIMIT 10; 

/*11. Korzystaj¹c z funkcji SUBSTRING na atrybucie SAL_DESCRIPTION, wyœwietl 3 dowolne
wiersze z tabeli sprzeda¿owej w taki sposób, aby w kolumnie wynikowej dla
SUBSTRING z SAL_DESCRIPTION wyœwietlonych zosta³o tylko 3 pierwsze znaki.*/

SELECT *, substring(s.sal_description,1, 3) 
FROM sales s 
LIMIT 3

/*12. Korzystaj¹c ze sk³adni LIKE znajdŸ wszystkie dane sprzeda¿owe, których opis sprzeda¿y
(SAL_DESCRIPTION) zaczyna siê od c4c.*/

SELECT *
FROM sales s
WHERE sal_description LIKE 'c4c%';

