-- MAVEN FUZZY FACTORY BUSINESS PATTERNS & SEASONALITY ANALYSIS

-- understanding & analyzing seasonality
-- 2012 monthly volume patterns
SELECT 
	YEAR(DATE(ws.created_at)) AS yr,
    MONTH(DATE(ws.created_at)) AS mo,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM 
	website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE
	ws.created_at BETWEEN '2012-01-01' AND '2012-12-31'
GROUP BY
	1,2;

-- 2012 weekly volume patterns
SELECT 
	MIN(DATE(ws.created_at)) AS week_start_date,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM 
	website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE
	ws.created_at BETWEEN '2012-01-01' AND '2012-12-31'
GROUP BY
	WEEK(ws.created_at);

-- analyzing business patterns
SELECT 
	hr,
    -- ROUND(AVG(sessions),1) AS avg_sessions,
    ROUND(AVG(CASE WHEN week_day = 0 THEN sessions ELSE NULL END),1) AS mon,
    ROUND(AVG(CASE WHEN week_day = 1 THEN sessions ELSE NULL END),1) AS tue,
    ROUND(AVG(CASE WHEN week_day = 2 THEN sessions ELSE NULL END),1) AS wed,
    ROUND(AVG(CASE WHEN week_day = 3 THEN sessions ELSE NULL END),1) AS thu,
    ROUND(AVG(CASE WHEN week_day = 4 THEN sessions ELSE NULL END),1) AS fri,
    ROUND(AVG(CASE WHEN week_day = 5 THEN sessions ELSE NULL END),1) AS sat,
    ROUND(AVG(CASE WHEN week_day = 6 THEN sessions ELSE NULL END),1) AS sun
FROM
(
SELECT
    DATE(created_at) AS date,
	WEEKDAY(created_at) AS week_day,
	HOUR(created_at) AS hr,
	COUNT(DISTINCT website_session_id) AS sessions
FROM 
	website_sessions
WHERE 
	created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY
	1,2,3
) AS daily_hourly_sessions
GROUP BY 1
ORDER BY 1;

