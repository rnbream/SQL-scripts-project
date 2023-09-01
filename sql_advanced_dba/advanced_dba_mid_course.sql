/*
ADVANCED DBA MID COURSE PROJECT

THE SITUATION: 
Maven Bear Builders has been up and running for a little over a year. You and your CEO
have made some improvements to the database, but as the business continues to change,
she needs more help tweaking the structure and importing additional datasets.

THE OBJECTIVE:
- Import additional data into the bearbuilders database
- Enhance the data structure to accommodate new tracking needs for the business

As a Database Administrator, part of your job is executing on specific tasks like altering
tables. Another major focus area is staying on top of things like backup, recovery, and
database security. Use any opportunities you see as chance to flex your muscle as a 
thought leader in these areas!
*/


-- MID COURSE PROJECT QUESTIONS

-- 1. Import 'Q2 orders and refunds' into the database using the given files:
SELECT
	COUNT(*) AS total_records
FROM order_items;

SELECT
	COUNT(*) AS total_records
FROM order_item_refunds;


/*
2. Next, help update the structure of the order_items table:
- The company is going to start cross-selling products and will want to track whether each item sold is the
	'primary' item (the first one put into the user's shopping cart) or a 'cross-sold' item
- Add a binary column to the 'order_items' table called 'is_primary_item'
*/
SELECT * FROM order_items;

ALTER TABLE order_items
ADD COLUMN is_primary_item BIGINT;

/*
3. Update all previous records in the 'order_items' table, setting 'is_primary_item = 1' for all records
- Up until now, all items sold were the primary item (since cross-selling is new)
- 'Confirm this change has executed successfully'
*/
UPDATE order_items
SET is_primary_item = 1
WHERE order_item_id > 0;

/*
4. 'Add two new products' to the 'products' table, then 'import the remainder of 2013 orders and refunds', 
using the given product details and files shown below:
*/
INSERT INTO products VALUES
(3,'2013-12-12 09:00:00','The Birthday Sugar Panda'),
(4,'2014-02-05 10:00:00','The Hudson River Mini Bear');

SELECT * FROM products;

/*
5. Your CEO would like to make sure the database has a high degree of data integrity and avoid potential
issues as more people to start using the database. If you see any opportunities to 'ensure data integrity
by using constraints like NON-NULL', add them to the relevant columns in the tables you have created.
*/
-- I just added a check to Non-Null constraint in 'is_primary_item' column.

/*
6. One of the company's board advisors is pressuring your CEO on data risks and making sure she has a
great backup and recovery plan. 'Prepare a report on possible risks for data loss and steps the
company can take to mitigate these concerns.'
*/
-- I just created a logical backup using mysql dump
















