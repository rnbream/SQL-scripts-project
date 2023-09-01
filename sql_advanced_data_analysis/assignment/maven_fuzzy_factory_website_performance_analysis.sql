-- MAVEN FUZZY FACTORY TOP WEBSITE PAGES & ENTRY PAGES ANALYSIS

-- Finding Top Website Pages
SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC;

-- Finding Top Entry Pages
-- STEP 1: Find the first pageview for each session
CREATE TEMPORARY TABLE first_pv_per_session
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_pv
FROM 
	website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1;

-- STEP 2: Find the URL the customer saw on that first pageview
SELECT 
	wp.pageview_url AS landing_page_url,
    COUNT(DISTINCT fpv.website_session_id) AS sessions_hitting_page
FROM first_pv_per_session fpv
	LEFT JOIN website_pageviews wp
		ON fpv.first_pv = wp.website_pageview_id
GROUP BY 1;

-- Analyzing Bounce Rates & Landing Page Tests
-- calculating bounce rates
CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1;

CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT
	fw.website_session_id,
    wp.pageview_url AS landing_page
FROM first_pageviews fw
	LEFT JOIN website_pageviews wp
		ON fw.min_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url = '/home';

CREATE TEMPORARY TABLE bounced_sessions
SELECT
	s.website_session_id,
    s.landing_page,
    COUNT(wp.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_home_landing_page s
	LEFT JOIN website_pageviews wp
		ON s.website_session_id = wp.website_session_id
GROUP BY 
	1,2
HAVING
	count_of_pages_viewed = 1;

-- final output
SELECT 
	COUNT(DISTINCT s.website_session_id) AS sessions,
    COUNT(DISTINCT bs.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bs.website_session_id)/COUNT(DISTINCT s.website_session_id) AS bounced_rate
FROM sessions_w_home_landing_page s
	LEFT JOIN bounced_sessions bs
		ON s.website_session_id = bs.website_session_id;

-- Analyzing Landing Page Tests
-- finding the new page /lander launched
SELECT 
	MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
	AND created_at IS NOT NULL;
-- first_created_at = '2012-06-19 00:35:54'
-- first_pageview_id = 23504
CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
    INNER JOIN website_sessions ws
		ON wp.website_session_id = ws.website_session_id
        AND ws.created_at < '2012-07-28'
        AND wp.website_pageview_id > 23504
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand' 
GROUP BY 1;

--
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_page
SELECT 
	ftp.website_session_id,
	wp.pageview_url AS landing_page
FROM first_test_pageviews ftp
	LEFT JOIN website_pageviews wp
		ON ftp.min_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1');

--
CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT
	nbt.website_session_id,
    nbt.landing_page,
    COUNT(wp.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_sessions_w_landing_page nbt
	LEFT JOIN website_pageviews wp
		ON nbt.website_session_id = wp.website_session_id
GROUP BY 1,2
HAVING
	count_of_pages_viewed = 1;

-- SELECT * FROM nonbrand_test_sessions_w_landing_page; -- QA only

--
SELECT 
	nbt.landing_page,
    COUNT(DISTINCT nbt.website_session_id) AS sessions,
    COUNT(DISTINCT ntb.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT ntb.website_session_id)/COUNT(DISTINCT nbt.website_session_id) AS bounced_rate
FROM nonbrand_test_sessions_w_landing_page nbt
	LEFT JOIN nonbrand_test_bounced_sessions ntb
		ON nbt.website_session_id = nbt.website_session_id
GROUP BY 1;

-- Landing Page Trend Analysis
-- finding the first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE sessions_w_min_pv
SELECT
	ws.website_session_id,
    MIN(wp.website_pageview_id) AS first_pageview_id,
    COUNT(wp.website_pageview_id) AS count_pageviews
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at > '2012-06-01' -- asked by requestor
	AND ws.created_at < '2012-08-31' -- prescribed by assignment date
    AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
GROUP BY
	1;

-- identifying the landing page of each session
CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT 
	swmp.website_session_id,
    swmp.first_pageview_id,
    swmp.count_pageviews,
    wp.pageview_url AS landing_page,
    wp.created_at AS session_created_at
FROM sessions_w_min_pv swmp
	LEFT JOIN website_pageviews wp
		ON swmp.website_session_id = wp.website_session_id
        AND pageview_url IN ('/home','/lander-1');

-- counting pageviews for each session, to identify "bounces"
-- summarizing by week (bounce rate, sessions to each lander)
SELECT 
	MIN(DATE(session_created_at)) AS week_start_date,
    -- COUNT(DISTINCT website_session_id) AS total_sessions,
    -- COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)*1.0 / COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_w_counts_lander_and_created_at swcl
GROUP BY
	WEEK(session_created_at);

-- Building Conversion Funnels
CREATE TEMPORARY TABLE session_pageview_level_made_it
SELECT 
	website_session_id,
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(order_placed_page) AS order_placed_made_it
FROM 
(
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    wp.created_at AS pageview_created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS order_placed_page
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source IN ('gsearch','nonbrand')
	AND ws.created_at > '2012-08-05' 
    AND ws.created_at < '2012-09-05'
    AND wp.pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
ORDER BY 1
) AS pageview_level
GROUP BY 1;

-- counting all the sessions who made it
-- SELECT * FROM session_level_made_it; -- QA only
SELECT 
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy, 
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping, 
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing, 
    COUNT(DISTINCT CASE WHEN order_placed_made_it = 1 THEN website_session_id ELSE NULL END) AS to_order_placed
FROM session_pageview_level_made_it;

-- clicked rates
SELECT 
	COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) 
		/  COUNT(DISTINCT website_session_id) AS lander_click_rt,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt, 
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)  AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt, 
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)  AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN order_placed_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_pageview_level_made_it;

-- Analyzing Conversion Funnel Tests
-- finding the first time /billing-2 was seen
SELECT
	MIN(DATE(created_at)) AS first_created_at,
    MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';
-- first_pv_id = 53550

--
SELECT 
	wp.website_session_id,
    wp.pageview_url AS billing_version_seen,
    o.order_id
FROM website_pageviews wp
	LEFT JOIN orders o
		ON o.website_session_id = wp.website_session_id
WHERE wp.website_pageview_id >= 53550 -- first pageview_id where test was live
	AND wp.created_at < '2012-11-10' -- time of assignment
	AND wp.pageview_url IN ('/billing','/billing-2');

--
SELECT 
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM
(
SELECT 
	wp.website_session_id,
    wp.pageview_url AS billing_version_seen,
    o.order_id
FROM website_pageviews wp
	LEFT JOIN orders o
		ON o.website_session_id = wp.website_session_id
WHERE wp.website_pageview_id >= 53550 -- first pageview_id where test was live
	AND wp.created_at < '2012-11-10' -- time of assignment
	AND wp.pageview_url IN ('/billing','/billing-2')
) AS billing_sessions_w_orders
GROUP BY 1;
	














        









    







