-- MAVEN FUZZY FACTORY CHANNEL PORTFOLIOS ANALYSIS

-- analyzing expanded channel portfolios
SELECT
	MIN(DATE(created_at)) AS date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM 
	website_sessions
WHERE 
	created_at > '2012-08-22' -- specified in the request
	AND created_at < '2012-11-29' -- dictated by the time of the request
    AND utm_campaign = 'nonbrand' -- limiting to nonbrand paid search
GROUP BY
	WEEK(created_at);
    
-- comparing channel characteristics
SELECT 
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS pct_mobile
FROM 
	website_sessions
WHERE 
	created_at > '2012-08-22' -- specified in the request
    AND created_at < '2012-11-30' -- dictated by the time of the request
    AND utm_campaign = 'nonbrand' -- limiting to nonbrand paid search
GROUP BY 1;

-- cross-channel bid optimization
SELECT 
	device_type,
	utm_source,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM 
	website_sessions ws
    LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at BETWEEN '2012-08-22' AND '2012-09-19'
    AND utm_campaign = 'nonbrand'
    AND utm_source IN ('bsearch','gsearch')
GROUP BY 1,2;

-- analyzing channel portfolio trends
SELECT 
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'bsearch' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM 
	website_sessions
WHERE 
	created_at > '2012-11-04'
    AND created_at < '2012-12-22'
    AND utm_source IN ('gsearch','bsearch')
    AND utm_campaign = 'nonbrand'
GROUP BY 
	WEEK(created_at);
    
-- analyzing direct traffic
-- site traffic breakdown
SELECT 
	YEAR(DATE(created_at)) AS yr,
    MONTH(DATE(created_at)) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer = 'https://www.gsearch.com' THEN website_session_id ELSE NULL END) 
		+ COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer = 'https://www.bsearch.com' THEN website_session_id ELSE NULL END) AS organic,
	(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer = 'https://www.gsearch.com' THEN website_session_id ELSE NULL END) 
		+ COUNT(DISTINCT CASE WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer = 'https://www.bsearch.com' THEN website_session_id ELSE NULL END))
        / COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM 
	website_sessions
WHERE 
	created_at < '2012-12-23'
GROUP BY 
	1,2;












