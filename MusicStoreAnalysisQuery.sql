USE music_database;

SELECT * FROM album;

SELECT * FROM artist;

SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM track;
-- ---------------------------------------------------------------
/* Business Questions Set 1 
1. Who is the senior most employee based on the job title? */

SELECT employee_id,
		first_name,
        last_name,
        levels
FROM employee 
ORDER BY levels Desc;

/* ANS: 1 Andrew Adams - L6*/

-- Q2. Which countries have the most invoices?

SELECT * FROM invoice;

SELECT billing_country,
		COUNT(invoice_id) AS Total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY Total_invoices DESC;

-- ANS - USA -131

-- Q3: What Are top 3 values of total invoices
SELECT distinct total FROM invoice
ORDER BY total DESC
Limit 4;
-- ANS: 23.76, 19.8, 18.81




-- ANS : USA - 131, Canada - 76, Brazil - 61

-- Q4 Which city has the best customers ? Who would like to throw a promotional music festical in the city 
--   we made the most money.write a query that returns one city that has the highest sum of invoices totals. 
--  Return the city name and the sum of all invoice totals.
SELECT * FROM
invoice;

SELECT billing_city,
SUM(total) AS total_invoices
FROM invoice
GROUP BY billing_city
ORDER BY total_invoices DESC; -- Prague - 273.2400

-- Q5. Who is the best customer who has spent the most


SELECT customer.first_name, customer.last_name, customer.customer_id,
 SUM(invoice.total) As Total_spent
FROM customer
JOIN invoice ON 
customer.customer_id= invoice.customer_id
GROUP BY customer.customer_id,
customer.first_name,customer.last_name
ORDER BY Total_spent Desc;



-- ANS: 'František', 'Wichterlová', '5', '144.5399980545044'

-- Q6: Write a query to return the email, first name and last name and genre of all the rock music listeners .
-- genre linked to track (through genre_id), inturn linked to invoice_line through track_id
-- invoice_loine is connected to invoice through invoice. from which we get the customer information through customer_id
SELECT * FROM customer;

SELECT  DISTINCT customer.first_name,customer.last_name, customer.email
FROM customer
LEFT JOIN invoice on customer.customer_id = invoice.customer_id
LEFT JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
SELECT track_id FROM track
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = "Rock")
ORDER BY customer.email;

-- ANS:  Aaron Mitchell aaronmitchell@yahoo.ca

-- Q7:Lets invite the artists who have written the most rock musicin our data set.wrte a query that returns the 
-- artist name and total track count of the top 10 rock bands.

SELECT * FROM artist;
SELECT * FROM track;

SELECT artist.name AS Artist_name, COUNT(artist.artist_id)AS CountofTracks
FROM track
LEFT JOIN album ON album.album_id = track.album_id
LEFT JOIN artist ON artist.artist_id = album.artist_id
LEFT JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name = "Rock"
GROUP BY Artist_name
Order BY CountofTracks DESC
Limit 10;

/* ANS: # Artist_name, CountofTracks
			'Led Zeppelin', '114'
			'U2', '112'
			'Deep Purple', '92'
			'Iron Maiden', '81'
			'Pearl Jam', '54'
			'Van Halen', '52'
            'Queen', '45'
			'The Rolling Stones', '41'
			'Creedence Clearwater Revival', '40'
			'Kiss', '35'  */
-- Q8: Return all track names with durations longer than average song length.
-- Return the name and milliseconds for each track. order by song length desc.

SELECT name, milliseconds
FROM track
WHERE milliseconds >
(SELECT AVG(milliseconds) AS avg_song_duration
FROM track)
ORDER BY milliseconds DESC;

-- Q9: Find how much amount spent by each customer on Artists?Write a query to return
-- customer name , artist name ,`and total spent.

SELECT * FROM invoice;
SELECT * FROM invoice_line;
SELECT * FROm track;
SELECT * FROm album;
SELeCT * FROm artist;

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
    )
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/*  ANS : # customer_id	first_name	last_name	artist_name	amount_spent
46	Hugh	O'Reilly	Queen	27.719999999999985
42	Wyatt	Girard	Frank Sinatra	23.75999999999999
6	Helena	Holý	Red Hot Chili Peppers	19.799999999999997
3	François	Tremblay	The Who	19.799999999999997
29	Robert	Brown	Creedence Clearwater Revival	19.799999999999997 */

-- Q10. We want to find out the most popular music genre for each coumtry. we determine
-- the most popular genre as the genre with the highest amount of purchases. Write a query that returns 
-- each coumtry along the top genre.for countries where most purchases are done, return all genres.

SELECT * FROM genre;
SELECT * FROM customer;
SELECT * FROM invoice_line;
SELECT * FROM track;



WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;



/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Ans # purchases_per_genre	country	name	genre_id
17	Argentina	Alternative & Punk	4
34	Australia	Rock	1
40	Austria	Rock	1
26	Belgium	Rock	1
205	Brazil	Rock	1
333	Canada	Rock	1
61	Chile	Rock	1
143	Czech Republic	Rock	1
24	Denmark	Rock	1
46	Finland	Rock	1
211	France	Rock	1
194	Germany	Rock	1
44	Hungary	Rock	1
102	India	Rock	1
72	Ireland	Rock	1
35	Italy	Rock	1
33	Netherlands	Rock	1
40	Norway	Rock	1
40	Poland	Rock	1
108	Portugal	Rock	1
46	Spain	Rock	1
60	Sweden	Rock	1
166	United Kingdom	Rock	1
561	USA	Rock	1  */


 -- Q 11: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 

WITH RECURSIVE
	customer_with_country AS (
	SELECT customer.customer_id, customer.first_name, customer.last_name, invoice.billing_country AS country,
	SUM(total) AS total_spent
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY total_spent DESC 
),

country_with_top_spent AS(
	SELECT country, MAX(total_spent) AS max_spent
    FROM customer_with_country
    GROUP BY country)
    
SELECT cc.country, cc.total_spent, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_with_top_spent ct
ON cc.country = ct.country
WHERE cc.total_spent = ct.max_spent
ORDER BY 1;


-- --------------------------------------------------------------------------------------






 



