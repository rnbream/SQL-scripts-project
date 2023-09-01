/*
ADVANCED SQL ANALYSIS 
MID COURSE PROJECT

THE SITUATION: 
	Maven Fuzzy Factory has been live for 8 months, and your CEO is due to present company
    performance metrics to the board next week. You'll be the one tasked with preparing relevant
    metrics to show the company's promising growth.

THE OBJECTIVE:
	Use SQL to extract and analyze website traffic and performance data from the Maven Fuzzy Factory
    database to quantify the company's growth, and to tell the story of how you have been
    able to generate that growth.
    
    As an analyst, the first part of your job is extracting and analyzing the data, and the next
    part of your job is effectively communicating the story to your stakeholders.
*/

/*
MID COURSE PROJECT QUESTIONS

1. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions
	and orders so that we can showcase the growth there?
*/
-- SELECT * FROM website_sessions;
-- SELECT * FROM orders;

SELECT
	MIN(DATE(ws.created_at)) AS date,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT  order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rt
FROM 
	website_sessions ws
    LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE 
	utm_source = 'gsearch'
    AND ws.created_at < '2012-11-27'
GROUP BY
	MONTH(ws.created_at);

/*
2. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and
	brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell.
*/
SELECT 
	MIN(DATE(ws.created_at)) AS date,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS brand_orders
FROM 
	website_sessions ws
    LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE
	utm_source = 'gsearch'
    AND utm_campaign IN ('nonbrand','brand')
    AND ws.created_at < '2012-11-27'
GROUP BY
	MONTH(ws.created_at);

/*
3. While we're on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device
	type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/
-- SELECT DISTINCT device_type FROM website_sessions;
SELECT
	MIN(DATE(ws.created_at)) AS date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS nonbrand_desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN order_id ELSE NULL END) AS nonbrand_desktop_orders,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS nonbrand_mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN order_id ELSE NULL END) AS nonbrand_mobile_orders,
    COUNT(DISTINCT order_id) AS total_orders
FROM 
	website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	MONTH(ws.created_at);

/*
4. I'm worried that one of our more pessimistic board members may be concerned about the large % of traffic from
	Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/
-- SELECT DISTINCT utm_source FROM website_sessions;
SELECT DISTINCT
	utm_source,
    utm_campaign,
    http_referer
FROM 
	website_sessions
WHERE
	created_at < '2012-11-27';

--
SELECT 
	MIN(DATE(created_at)) AS date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS gsearch_nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS gsearch_brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS bsearch_nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS bsearch_brand_sessions,
    COUNT(DISTINCT CASE WHEN (utm_source IS NULL AND utm_campaign IS NULL) AND http_referer = 'https://www.gsearch.com' THEN website_session_id ELSE NULL END) AS gsearch_http_referer_sessions,
    COUNT(DISTINCT CASE WHEN (utm_source IS NULL AND utm_campaign IS NULL) AND http_referer = 'https://www.bsearch.com' THEN website_session_id ELSE NULL END) AS bsearch_http_referer_sessions,
    COUNT(DISTINCT CASE WHEN (utm_source IS NULL AND utm_campaign IS NULL) AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS other_sessions
FROM 
	website_sessions
WHERE
	created_at < '2012-11-27'
GROUP BY
	MONTH(created_at);

/*
5. I'd like to tell the story of our website performance improvements over the course of the first 8 months. 
	Could you pull session to order conversion rates by month?
*/
SELECT
	MIN(DATE(ws.created_at)) date,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rt
FROM 
	website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-11-27'
GROUP BY 
	MONTH(ws.created_at);

/*
6. For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR
	from the test (Jun 19 - Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value)
*/
-- finding the first pageview id 
SELECT
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	wp.website_session_id, 
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
	INNER JOIN website_sessions ws
		ON ws.website_session_id = wp.website_session_id
		AND ws.created_at < '2012-07-28' -- prescribed by the assignment
		AND wp.website_pageview_id >= 23504 -- first page_view
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- next, bringing in the landing page to each session, but restricting to home or lander-1
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT 
	ftp.website_session_id, 
    wp.pageview_url AS landing_page
FROM first_test_pageviews ftp
	LEFT JOIN website_pageviews wp 
		ON wp.website_pageview_id = ftp.min_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1'); 

-- creating table to bring in orders
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT
	ntsl.website_session_id, 
    ntsl.landing_page, 
    o.order_id AS order_id

FROM nonbrand_test_sessions_w_landing_pages ntsl
LEFT JOIN orders o
	ON o.website_session_id = ntsl.website_session_id;
    
-- to find the difference between conversion rates 
SELECT
	landing_page, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders ntso
GROUP BY 1; 

-- .0319 for /home, vs .0406 for /lander-1 
-- .0087 additional orders per session

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
SELECT 
	MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview 
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON wp.website_session_id = ws.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND ws.created_at < '2012-11-27'
;
-- max website_session_id = 17145

SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145 -- last /home session
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand';
    
-- 22,972 website sessions since the test

-- X .0087 incremental conversion = 202 incremental orders since 7/29
	-- roughly 4 months, so roughly 50 extra orders per month. Not bad!

/*
7. For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each
	of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 - Jul 28)
*/
SELECT
	ws.website_session_id, 
    wp.pageview_url, 
    -- website_pageviews.created_at AS pageview_created_at, 
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page, 
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON ws.website_session_id = wp.website_session_id
WHERE utm_source = 'gsearch' 
	AND utm_campaign = 'nonbrand' 
    AND ws.created_at < '2012-07-28'
		AND ws.created_at > '2012-06-19'
ORDER BY 
	1,2;

--
CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
	website_session_id, 
    MAX(homepage) AS saw_homepage, 
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it, 
    MAX(mrfuzzy_page) AS mrfuzzy_made_it, 
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM
(
SELECT
	ws.website_session_id, 
    wp.pageview_url, 
    -- website_pageviews.created_at AS pageview_created_at, 
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page, 
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON ws.website_session_id = wp.website_session_id
WHERE utm_source = 'gsearch' 
	AND utm_campaign = 'nonbrand' 
    AND ws.created_at < '2012-07-28'
		AND ws.created_at > '2012-06-19'
ORDER BY 
	1,2
) AS pageview_level
GROUP BY 1;

--
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic' 
	END AS segment, 
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged 
GROUP BY 1
;

-- clicked rates
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic' 
	END AS segment, 
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flagged
GROUP BY 1
;

/*
8. I'd love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test
(Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions
for the past month tho understand monthly impact.
*/
SELECT
	billing_version_seen, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM
(
SELECT 
	wp.website_session_id, 
    wp.pageview_url AS billing_version_seen, 
    o.order_id, 
    o.price_usd
FROM website_pageviews wp
	LEFT JOIN orders o
		ON o.website_session_id = wp.website_session_id
WHERE wp.created_at > '2012-09-10' -- prescribed in assignment
	AND wp.created_at < '2012-11-10' -- prescribed in assignment
    AND wp.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1;

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: $8.51 per billing page view

SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27' -- past month

-- 1,194 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: $10,160 over the past month







