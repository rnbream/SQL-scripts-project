/*
ADVANCED DBA FINAL COURSE PROJECT

THE SITUATION: 
There have been some exciting developments for Maven Bear Builders. The company is going
to start offering chat support on the website, and needs your help planning. The company has
also been approached by potential acquirers, and you'll be asked to help with due diligence.

THE OBJECTIVE:
- Create a plan for handling chat support, including the database infrastructure, EER
  diagrams explaining your plan, and reports to help management understand performance.
- Provide support for questions relating to the potential acquisition, to help your CEO keep
  them interested and hopefully close the deal.
*/

/*
YOUR OBJECTIVES:
- Update the database with the most recent data.
- Create a plan for the company's service expansion to include chat support.
- Help Sally with some support for asks related to the potential acquisition.
*/

/*
FINAL COURSE PROJECT QUESTIONS

1. Import the latest order_items and order_item_refunds data below into the database, and verify the
   order summary trigger you created previously still works (if not, recreate it)
   -- 17.order_items_2014_Mar
   -- 18.order_items_2014_Apr
   -- 19.order_item_refunds_2014_Mar
   -- 20.order_item_refunds_2014_Apr
*/
SELECT * FROM order_items;

SELECT
	COUNT(order_item_id) AS total_orders,
	MAX(created_at) AS recent_date
FROM order_items;

SELECT * FROM order_item_refunds;

SELECT
	COUNT(order_item_refund_id) AS total_order_refunds,
	MAX(created_at) AS recent_date
FROM order_item_refunds;

/*
2. Import the website_sessions and website_pageviews data for March and April, provided below:
   -- 21.website_sessions_2014_Mar
   -- 22.website_sessions_2014_Apr
   -- 23.website_pageviews_2014_Mar
   -- 24.website_pageviews_2014_Apr
*/
SELECT * FROM website_sessions;

SELECT
	COUNT(website_session_id) AS total_web_sessions,
	MAX(created_at) AS recent_date
FROM website_sessions;

SELECT * FROM website_pageviews;

SELECT
	COUNT(website_pageview_id) AS total_web_pageviews,
	MAX(created_at) AS recent_date
FROM website_pageviews;


/*
3. The company is adding chat support to the website. You'll need to design a database plan to track
   which customers and sessions utilize chat, and which chat representatives serve each customer.
   
   ANSWER:
   -- users table
		-- user_id
        -- created_at
        -- first_name
        -- last_name
        
	-- support_members
		-- support_member_id
        -- created_at
        -- first_name
        -- last_name
	
    -- chat_sessions
		-- chat_session_id
        -- created_at
        -- user_id
        -- support_member_id
        -- website_session_id
        
    -- chat_messages
		-- chat_message_id
        -- created_at
        -- chat_session_id
        -- user_id (will be null for support members)
        -- support_member_id (null for users)
        -- message_text
*/

/*
4. Based on your tracking plan for chat support, create an EER diagram that incorporates your new tables
   into the existing database schema (including table relationships).

5. Create the tables from your chat support tracking plan in the database, and include relationships to
   existing tables where applicable.
*/
CREATE TABLE users (
	user_id BIGINT,
    created_at DATETIME,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    PRIMARY KEY (user_id)
);

CREATE TABLE support_members (
	support_member_id BIGINT,
    created_at DATETIME,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    PRIMARY KEY (support_member_id)
);

CREATE TABLE chat_sessions (
	chat_session_id BIGINT,
    created_at DATETIME,
    user_id BIGINT,
    support_member_id BIGINT,
    website_session_id BIGINT,
    PRIMARY KEY (chat_session_id)
);

CREATE TABLE chat_messages (
	chat_messages_id BIGINT,
    created_at DATETIME,
    chat_session_id BIGINT,
    user_id BIGINT,
    support_member_id BIGINT,
    message_text VARCHAR(200),
    PRIMARY KEY (chat_session_id),
    FOREIGN KEY (chat_session_id) REFERENCES chat_sessions(chat_session_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (support_member_id) REFERENCES support_members(support_member_id)
);

/*
6. Using the new tables, create a stored procedure to allow the CEO to pull a count of chats handled by
   chat representative for a given time period, with a simple CALL statement which includes two dates.
*/
DELIMITER //

CREATE PROCEDURE support_member_chat
(IN supmemberid BIGINT, IN startdate DATE, IN enddate DATE)
BEGIN
	SELECT
		COUNT(chat_session_id) AS chats_handled
	FROM chat_sessions
    WHERE DATE(created_at) BETWEEN startdate AND enddate
		AND support_member_id = supmemberid;
END //

DELIMITER ;

CALL support_member_chat(1,'2014-01-01','2014-01-31');

/*
7. Create two VIEWS for the potential acquiring company; one detailing monthly order volume and revenue,
   the other showing monthly website traffic. The create a new User, with access restricted to these Views.
*/

CREATE VIEW monthly_orders_revenue AS
SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(order_id) AS monthly_orders,
    SUM(price_usd) AS monthly_revenue
FROM orders
GROUP BY 1,2;

SELECT * FROM monthly_orders_revenue;

CREATE VIEW monthly_website_sessions AS
SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(website_session_id) AS sessions
FROM website_sessions
GROUP BY 1,2;

SELECT * FROM monthly_website_sessions;
    
/*
8. The potential acquirer is commissioning a third-party security study, and your CEO wants to get in front
   of it. Provide her with a list of your top data security threats and recommendations for mitigating risk.
*/
/*
ANSWER: 
COMMON SECURITY THREATS AND ATTACKS
1. Weak Authentication
2. Denial of Service (DoS)
3. Privilege Escalation
4. SQL Injection
5. Buffer Overflow
6. Ransomware

SECURITY BEST PRACTICES
1. Practice Safe Data Storage
2. Limit Access to Systems and Data
3. Take Authentication Seriously
4. Dedicate Resources to Security
5. Backup, Log and Monitor Data as well as Perform Audits
*/





























