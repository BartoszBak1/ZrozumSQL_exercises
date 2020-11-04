--- Modu� 6 Data Query Language � Zadania Teoria SQL

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

-- 1. Wy�wietl unikatowe daty stworzenia produkt�w (wed�ug atrybutu manufactured_date)

SELECT DISTINCT ON (manufactured_date) manufactured_date 
FROM products;


-- 2. Jak sprawdzisz czy 10 wstawionych produkt�w to 10 unikatowych kod�w produkt�w?

SELECT  count(product_code) number_of_product_code, count(DISTINCT products.product_code) number_of_unique_product_code
FROM  products;

-- 3. Korzystaj�c ze sk�adni IN wy�wietl produkty od kodach PRD1 i PRD9

SELECT *
FROM products
WHERE product_code IN ('PRD1', 'PRD9');

/*4. Wy�wietl wszystkie atrybuty z danych sprzeda�owych, takie �e data sprzeda�y jest w
zakresie od 1 sierpnia 2020 do 31 sierpnia 2020 (w��cznie). Dane wynikowe maj� by�
posortowane wed�ug warto�ci sprzeda�y malej�co i daty sprzeda�y rosn�co.*/

SELECT *
FROM sales
WHERE sales.sal_date BETWEEN '2020-08-01' AND '2020-08-31'
ORDER BY sales.sal_value DESC , sales.sal_date ASC;

/* 5. Korzystaj�c ze sk�adni NOT EXISTS wy�wietl te produkty z tabeli PRODUCTS, kt�re nie
bior� udzia�u w transakcjach sprzeda�owych (tabela SALES). ID z tabeli Products i
SAL_PRODUCT_ID to klucz ��czenia.*/

SELECT *
FROM products p 
WHERE NOT EXISTS (SELECT 1
					FROM sales s
					WHERE s.sal_product_id = p.id);



/* 6. Korzystaj�c ze sk�adni ANY i operatora = wy�wietl te produkty, kt�rych wyst�puj� w
transakcjach sprzeda�owych (wed�ug klucza Products ID, Sales SAL_PRODUCT_ID)
takich, �e warto�� sprzeda�y w transakcji jest wi�ksza od 100.*/

SELECT *
FROM products p
WHERE p.id = ANY(SELECT 1
		   FROM sales s
		   WHERE  s.sal_value>100);
				
/*7. Stw�rz now� tabel� PRODUCTS_OLD_WAREHOUSE o takich samych kolumnach jak
istniej�ca tabela produkt�w (tabela PRODUCTS). Wstaw do nowej tabeli kilka wierszy -
dowolnych wed�ug Twojego uznania.*/
		  
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
		  
/*8. Na podstawie tabeli z zadania 7, korzystaj�c z operacji UNION oraz UNION ALL po��cz
tabel� PRODUCTS_OLD_WAREHOUSE z 5 dowolnym produktami z tabeli
PRODUCTS, w wyniku wy�wietl jedynie nazw� produktu (kolumna PRODUCT_NAME)
i kod produktu (kolumna PRODUCT_CODE). Czy w przypadku wykorzystania UNION
jakie� wierszy zosta�y pomini�te?*/

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

-- UNION ��czy bez powielania tych samych warto�ci, UNION ALL nie usuwa duplikat�w
/* 9. Na podstawie tabeli z zadania 7, korzystaj�c z operacji EXCEPT znajd� r�nic� zbior�w
pomi�dzy tabel� PRODUCTS_OLD_WAREHOUSE a PRODUCTS, w wyniku wy�wietl
jedynie kod produktu (kolumna PRODUCT_CODE).*/

SELECT product_code 
FROM products p 
EXCEPT 
SELECT product_code
FROM products_old_warehouse pow ;


/*10. Wy�wietl 10 rekord�w z tabeli sprzeda�owej sales. Dane powinny by� posortowane
wed�ug warto�ci sprzeda�y (kolumn SAL_VALUE) malej�co. */

SELECT *
FROM sales s 
ORDER BY s.sal_value DESC
LIMIT 10; 

/*11. Korzystaj�c z funkcji SUBSTRING na atrybucie SAL_DESCRIPTION, wy�wietl 3 dowolne
wiersze z tabeli sprzeda�owej w taki spos�b, aby w kolumnie wynikowej dla
SUBSTRING z SAL_DESCRIPTION wy�wietlonych zosta�o tylko 3 pierwsze znaki.*/

SELECT *, substring(s.sal_description,1, 3) 
FROM sales s 
LIMIT 3

/*12. Korzystaj�c ze sk�adni LIKE znajd� wszystkie dane sprzeda�owe, kt�rych opis sprzeda�y
(SAL_DESCRIPTION) zaczyna si� od c4c.*/

SELECT *
FROM sales s
WHERE sal_description LIKE 'c4c%';

