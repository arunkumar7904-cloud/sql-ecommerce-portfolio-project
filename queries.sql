--running important queries

--1-full funnel by traffic source
WITH funnel AS (
  SELECT
    source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS added_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS started_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasers
  FROM events
  GROUP BY source
)
SELECT
  source,
  viewers,
  added_cart,
  ROUND(added_cart * 100.0 / NULLIF(viewers, 0), 1) AS view_to_cart_pct,
  started_checkout,
  ROUND(started_checkout * 100.0 / NULLIF(added_cart, 0), 1) AS cart_to_checkout_pct,
  purchasers,
  ROUND(purchasers * 100.0 / NULLIF(viewers, 0), 1) AS overall_conversion_pct
FROM funnel
ORDER BY overall_conversion_pct DESC;

--2.weekly cohort conversion trends
WITH weekly_cohorts AS (
  SELECT
    DATE_TRUNC('week', MIN(timestamp)) AS cohort_week,
    user_id
  FROM events
  GROUP BY user_id
)
SELECT
  wc.cohort_week,
  COUNT(DISTINCT wc.user_id) AS cohort_size,
  COUNT(DISTINCT o.user_id) AS purchasers,
  ROUND(COUNT(DISTINCT o.user_id) * 100.0 / COUNT(DISTINCT wc.user_id), 1) AS conversion_rate
FROM weekly_cohorts wc
LEFT JOIN orders o ON wc.user_id = o.user_id
  AND o.status = 'completed'
GROUP BY wc.cohort_week
ORDER BY wc.cohort_week;

--3.device drop-off analysis

WITH device_funnel AS (
  SELECT
    device,
    event_type,
    COUNT(DISTINCT user_id) AS users
  FROM events
  GROUP BY device, event_type
)
SELECT
  device,
  MAX(CASE WHEN event_type = 'page_view' THEN users END) AS page_views,
  MAX(CASE WHEN event_type = 'add_to_cart' THEN users END) AS add_to_cart,
  MAX(CASE WHEN event_type = 'purchase' THEN users END) AS purchases,
  ROUND(
    MAX(CASE WHEN event_type = 'purchase' THEN users END) * 100.0
    / NULLIF(MAX(CASE WHEN event_type = 'page_view' THEN users END), 0), 1
  ) AS conversion_rate
FROM device_funnel
GROUP BY device;

--4.daily conversion rate trend

SELECT
  DATE(timestamp) AS day,
  COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS viewers,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasers,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END), 0),
    2
  ) AS conversion_rate
FROM events
GROUP BY day
ORDER BY day;


--5.revenue by traffic source
SELECT
  e.source,
  COUNT(DISTINCT e.user_id) AS users,
  COUNT(o.order_id) AS orders,
  SUM(o.amount) AS total_revenue,
  ROUND(AVG(o.amount), 2) AS avg_order_value
FROM events e
JOIN orders o ON e.user_id = o.user_id
WHERE o.status = 'completed'
GROUP BY e.source
ORDER BY total_revenue DESC;

--6.user engagement distribution
WITH user_events AS (
  SELECT
    user_id,
    COUNT(*) AS event_count
  FROM events
  GROUP BY user_id
)
SELECT
  event_count,
  COUNT(*) AS number_of_users
FROM user_events
GROUP BY event_count
ORDER BY event_count;

--7.average time to purachse
WITH first_event AS (
  SELECT user_id, MIN(timestamp) AS first_seen
  FROM events GROUP BY user_id
),
purchase_time AS (
  SELECT user_id, MIN(timestamp) AS purchase_at
  FROM events WHERE event_type = 'purchase' GROUP BY user_id
)
SELECT
  AVG(purchase_at - first_seen) AS avg_time_to_purchase,
  MIN(purchase_at - first_seen) AS min_time,
  MAX(purchase_at - first_seen) AS max_time
FROM first_event fe
JOIN purchase_time pt ON fe.user_id = pt.user_id;

--8.average hours to purchase per cohort
WITH cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('week', MIN(timestamp)) AS cohort_week
  FROM events
  GROUP BY user_id
),
user_orders AS (
  SELECT
    o.user_id,
    c.cohort_week,
    EXTRACT(EPOCH FROM (o.timestamp - c.cohort_week)) / 3600 AS hours_diff
  FROM orders o
  JOIN cohorts c ON o.user_id = c.user_id
  WHERE o.status = 'completed'
)
SELECT
  cohort_week,
  COUNT(*) AS orders,
  ROUND(AVG(hours_diff), 1) AS avg_hours_to_purchase
FROM user_orders
GROUP BY cohort_week
ORDER BY cohort_week;
