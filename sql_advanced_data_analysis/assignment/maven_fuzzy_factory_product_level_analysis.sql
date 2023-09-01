-- MAVEN FUZZY FACTORY PRODUCT-LEVEL ANALYSIS

-- product-level sales analysis
SELECT 
	YEAR(DATE(created_at)) AS yr,
    MONTH(DATE(created_at)) AS mo,
    COUNT(DISTINCT order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE 
	created_at < '2013-01-04' -- date of the request
GROUP BY
	1,2;

-- product launch sales analysis
SELECT 
	YEAR(DATE(ws.created_at)) AS yr,
    MONTH(DATE(ws.created_at)) AS mo,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate,
    SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON o.website_session_id = ws.website_session_id
WHERE 
	ws.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY
	1,2;

-- product level website analysis
-- product pathing analysis

-- STEP 1: find the relevant /products pageviews with website_session_id
CREATE TEMPORARY TABLE products_pageviews
SELECT
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'
        ELSE 'uh oh...check logic'
	END AS time_period
FROM 
	website_pageviews
WHERE 
	created_at < '2013-04-06' -- date of request
    AND created_at > '2012-10-06' -- start of 3 months prior product 2 launch
    AND pageview_url = '/products';

-- STEP 2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE session_w_next_pageview_id
SELECT
	pp.time_period,
    pp.website_session_id,
    MIN(wp.website_pageview_id) AS min_next_pageview_id
FROM 
	products_pageviews pp
    LEFT JOIN website_pageviews wp
		ON pp.website_session_id = wp.website_session_id
        AND wp.website_pageview_id > pp.website_pageview_id
GROUP BY
	1,2;
    
-- STEP 3: find the pageview_url associated with any applicable next pageview_id
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT
	snp.time_period,
    snp.website_session_id,
    wp.pageview_url AS next_pageview_url
FROM
	session_w_next_pageview_id snp
	LEFT JOIN website_pageviews wp
		ON wp.website_pageview_id = snp.min_next_pageview_id;
        
-- STEP 4: summarize the data and analyze the pre vs post periods
SELECT
	time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM 
	sessions_w_next_pageview_url
GROUP BY 1;

-- building product conversion funnels
-- STEP 1: select all pageviews for relevant sessions
CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT
	website_session_id,
	website_pageview_id,
    pageview_url AS product_page_seen
FROM website_pageviews
WHERE pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
	AND created_at > '2013-01-06' -- product 2 launch
    AND created_at < '2013-04-10' -- date of assignment
;
-- STEP 2: figure out which pageview urls to look for
SELECT DISTINCT 
	wp.pageview_url
FROM
	sessions_seeing_product_pages sspp
    LEFT JOIN website_pageviews wp
		ON sspp.website_session_id = wp.website_session_id
		AND wp.website_pageview_id > sspp.website_pageview_id;

-- looking at the inner query first to look over the pageview-level results
-- then, turn it into a subquery and make it the summary with flags
SELECT 
	sspp.website_session_id,
    sspp.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM
	sessions_seeing_product_pages sspp
    LEFT JOIN website_pageviews wp
		ON sspp.website_session_id = wp.website_session_id
        AND wp.website_pageview_id > sspp.website_pageview_id
ORDER BY
	sspp.website_session_id,
    wp.created_at;


CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'uh oh...check logic'
	END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT 
	sspp.website_session_id,
    sspp.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM
	sessions_seeing_product_pages sspp
    LEFT JOIN website_pageviews wp
		ON sspp.website_session_id = wp.website_session_id
        AND wp.website_pageview_id > sspp.website_pageview_id
ORDER BY
	sspp.website_session_id,
    wp.created_at
) AS pageview_level
GROUP BY
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'uh oh...check logic'
	END;
    
-- final output 1
SELECT 
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM
	session_product_level_made_it_flags splf
GROUP BY 
	product_seen;

-- final output 2 click rates
SELECT 
	product_seen,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS product_page_click_rt,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_product_level_made_it_flags splf
GROUP BY
	product_seen;

-- cross-selling & product portfolio analysis
-- cross-sell analysis
-- identify the relevant /cart pageviews and their sessions
CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
	CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Cross_Sell'
        ELSE 'uh oh...check logic'
	END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM
	website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
	AND pageview_url = '/cart';

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT 
	ssc.time_period,
    ssc.cart_session_id,
    MIN(wp.website_pageview_id) AS pv_id_after_cart
FROM
	sessions_seeing_cart ssc
    LEFT JOIN website_pageviews wp
		ON ssc.cart_session_id = wp.website_session_id
        AND wp.website_pageview_id > ssc.cart_pageview_id
GROUP BY
	ssc.time_period,
    ssc.cart_session_id
HAVING
	MIN(wp.website_pageview_id) IS NOT NULL;

CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM
	sessions_seeing_cart ssc
    INNER JOIN orders o
		ON ssc.cart_session_id = o.website_session_id;

-- first, we'll look at this select statement
-- then, turn it into a subquery

SELECT
	ssc.time_period,
    ssc.cart_session_id,
    CASE WHEN cssp.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN ppso.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    ppso.items_purchased,
    ppso.price_usd
FROM 
	sessions_seeing_cart ssc
    LEFT JOIN cart_sessions_seeing_another_page cssp
		ON ssc.cart_session_id = cssp.cart_session_id
	LEFT JOIN pre_post_sessions_orders ppso
		ON ssc.cart_session_id = ppso.cart_session_id
ORDER BY
	cart_session_id;
    
SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    SUM(price_usd)/SUM(placed_order) AS aov,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM
(
SELECT
	ssc.time_period,
    ssc.cart_session_id,
    CASE WHEN cssp.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN ppso.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    ppso.items_purchased,
    ppso.price_usd
FROM 
	sessions_seeing_cart ssc
    LEFT JOIN cart_sessions_seeing_another_page cssp
		ON ssc.cart_session_id = cssp.cart_session_id
	LEFT JOIN pre_post_sessions_orders ppso
		ON ssc.cart_session_id = ppso.cart_session_id
ORDER BY
	cart_session_id
) AS full_data
GROUP BY
	time_period;
   
   
-- product portfolio expansion analysis
SELECT 
	CASE
		WHEN ws.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
        WHEN ws.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
        ELSE 'uh oh...check logic'
	END AS time_period,
	-- COUNT(DISTINCT ws.website_session_id) AS sessions,
    -- COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
    -- SUM(o.price_usd) AS total_revenue,
    -- SUM(o.items_purchased) AS total_products_sold,
    SUM(o.price_usd)/COUNT(DISTINCT o.order_id) AS average_order_value,
    SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order,
    SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM
	website_sessions ws
    LEFT JOIN orders o
		ON o.website_session_id = ws.website_session_id
WHERE
	ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;


-- product refund rates analysis
SELECT
	YEAR(oi.created_at) AS yr,
    MONTH(oi.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN oi.order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT order_item_refund_id)/COUNT(DISTINCT CASE WHEN product_id = 1 THEN oi.order_item_id ELSE NULL END) AS p1_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN oi.order_item_id ELSE NULL END) AS p2_orders,
	COUNT(DISTINCT order_item_refund_id)/COUNT(DISTINCT CASE WHEN product_id = 2 THEN oi.order_item_id ELSE NULL END) AS p2_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN oi.order_item_id ELSE NULL END) AS p3_orders,
	COUNT(DISTINCT order_item_refund_id)/COUNT(DISTINCT CASE WHEN product_id = 3 THEN oi.order_item_id ELSE NULL END) AS p3_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN oi.order_item_id ELSE NULL END) AS p4_orders,
	COUNT(DISTINCT order_item_refund_id)/COUNT(DISTINCT CASE WHEN product_id = 4 THEN oi.order_item_id ELSE NULL END) AS p4_refund_rt
FROM 
	order_items oi
    LEFT JOIN order_item_refunds oif
		ON oi.order_item_id = oif.order_item_id
WHERE oi.created_at < '2014-10-15'
GROUP BY
	1,2;





    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    






    
    
