-- R1: For each priority, how many jobs were completed, how many were on target, and what percentage was on target
WITH priority_summary AS (
    SELECT priority,
    COUNT(*) AS completed_jobs,
    COUNT(
        CASE
            WHEN priority = 'Emergency'
            AND completed_date - reported_date <= 1
            THEN 1

            WHEN priority = 'Urgent'
            AND completed_date - reported_date <= 7
            THEN 1

            WHEN priority = 'Routine'
            AND completed_date - reported_date <= 28
            THEN 1

            END) AS within_target

    FROM repair_jobs
    WHERE completed_date IS NOT NULL
    GROUP BY priority
)
SELECT priority,
    completed_jobs,
    within_target,
    ROUND(100.0 * within_target / completed_jobs, 1) AS pct_within_target
FROM priority_summary
ORDER BY pct_within_target, priority;
-- Result: Urgent repairs had the lowest on-target performance, with 6 of 9 completed jobs meeting the target (66.7%). Emergency and Routine repairs both achieved 80.0%, with 4 of 5 Emergency jobs and 8 of 10 Routine jobs completed within their respective targets.

-- R2: Every job still open on 30 June: where it is, who has it, how long it has been open, and whether it is already past its target. Longest open first.
WITH open_repairs AS (
    SELECT r.job_id,
        p.address,
        p.ward,
        r.priority,
        DATE '2026-06-30' - reported_date AS days_open,
        c.contractor_name
    FROM repair_jobs r
    JOIN properties p
    ON r.property_id = p.property_id
    JOIN contractors c
    ON c.contractor_id = r.contractor_id
    WHERE r.completed_date IS NULL)

SELECT job_id,
    address,
    ward,
    priority,
    days_open,
    contractor_name,
    CASE
    WHEN priority = 'Emergency'
            AND days_open > 1
            THEN 'Yes'

            WHEN priority = 'Urgent'
            AND days_open > 7
            THEN 'Yes'

            WHEN priority = 'Routine'
            AND days_open > 28
            THEN 'Yes'

            ELSE 'No'

            END AS overdue
FROM open_repairs
ORDER BY days_open DESC;
-- Result: As at 30 June 2026, there were 4 open repair jobs. Two were overdue: job 1028 in Chorlton, open for 43 days, and job 1027 in Ancoats, open for 10 days. The remaining two jobs, 1026 in Levenshulme and 1030 in Moss Side, were still within their respective targets. Oakline Joinery had the longest-open job, at 43 days.

-- R3: Which properties had no repair jobs at all? Sort by ward, then address.
SELECT p.address,
    p.ward
FROM properties p
WHERE NOT EXISTS (
    SELECT 1
    FROM repair_jobs r
    WHERE r.property_id = p.property_id
)
ORDER BY p.ward, p.address;
-- Result: Two properties had no repair jobs recorded: 2 Edge Lane in Chorlton and 19 Chapel Street in Levenshulme.

-- R4: For each month (by reported date): jobs reported, total cost, and cost so far this year.
WITH monthly_cost AS (
    SELECT DATE_TRUNC('month', reported_date):: DATE  AS months,
        COUNT(*) AS jobs_reported,
        COALESCE(SUM(cost), 0.00):: NUMERIC(10,2) AS total_cost
    FROM repair_jobs
    GROUP BY DATE_TRUNC('month', reported_date):: DATE)

SELECT TO_CHAR(months, 'Month') AS month,
    jobs_reported,
    total_cost,
    SUM(total_cost) OVER (ORDER BY months) AS cumulative_cost
FROM monthly_cost
ORDER BY months;
-- Result: Between January and June 2026, Northvale Homes recorded 28 repair jobs with a cumulative cost of £5,005. March had the highest monthly spend at £1,460, while June recorded no spend.

-- R5: The most expensive completed job in each ward.
WITH ward_ranking AS (
    SELECT r.job_id,
        p.ward,
        r.description,
        r.cost,
        RANK() OVER(PARTITION BY p.ward ORDER BY r.cost DESC NULLs LAST) AS rnk
    FROM repair_jobs r
    JOIN properties p
    ON r.property_id = p.property_id
    WHERE r.completed_date IS NOT NULL)
SELECT ward,
    job_id,
    description,
    cost
FROM ward_ranking
WHERE rnk = 1
ORDER BY ward, job_id;
-- Result: The most expensive completed repair jobs varied by ward. Ancoats recorded £520, Chorlton £450, Levenshulme £280, and Moss Side £640. Moss Side had two equally expensive jobs (1014 and 1024), both costing £640.

-- R6: Every recall: which job it went back to, who did that original job, and how many days passed between the original being completed and the recall being reported
SELECT r.job_id AS recall_job_id,
    o.job_id AS original_job_id,
    c.contractor_name AS original_contractor,
    r.reported_date - o.completed_date AS days_to_recall
FROM repair_jobs r
JOIN repair_jobs o
ON r.original_job_id = o.job_id
JOIN contractors c
ON o.contractor_id = c.contractor_id
ORDER BY days_to_recall DESC;
-- Result: Four recall jobs were identified. Job 1026 had the longest gap, occurring 98 days after the original job (1010) was completed. This was followed by job 1021 at 41 days, job 1012 at 35 days, and job 1017 at 31 days. Dryhome Damp & Mould completed the original job associated with the longest recall gap.

-- R7:Job 1003 was recalled, and then the recall was recalled too. Show the whole chain starting at 1003, with step 0 for the original.
WITH RECURSIVE recall AS (
    SELECT job_id,
        reported_date,
        0 AS step
    FROM repair_jobs
    WHERE job_id = 1003

    UNION ALL

    SELECT r.job_id,
        r.reported_date,
        re.step + 1
    FROM repair_jobs r
    JOIN recall re
    ON r.original_job_id = re.job_id
)
SELECT step,
    job_id,
    reported_date
FROM recall
ORDER BY step;
-- Result: The recall chain began with original job 1003, reported on 12 January 2026. It was first recalled as job 1012 on 20 February 2026, and that recall was subsequently recalled as job 1021 on 6 April 2026. The chain therefore contains three jobs across two recall stages.

-- R8: Contractor scorecard, only for contractors with at least 3 completed jobs: completed jobs, average tenant rating (2 decimal places), and how many of their completed jobs were later recalled.
SELECT c.contractor_name,
    COUNT(*) AS jobs_completed,
    ROUND(AVG(r.tenant_rating),2) AS avg_rating,
    COUNT(
        CASE
        WHEN r.job_id IN(
            SELECT original_job_id
            FROM repair_jobs
            WHERE original_job_id IS NOT NULL)
            THEN 1
            END
        ) AS recall_count
FROM contractors c
JOIN repair_jobs r
    ON c.contractor_id = r.contractor_id
WHERE r.completed_date IS NOT NULL
GROUP BY c.contractor_id, c.contractor_name
HAVING COUNT(*) >= 3
ORDER BY avg_rating DESC, recall_count;
-- Result: Oakline Joinery had the highest average rating (4.00) with no recalls, followed by Volt North Electrical (4.00) with 1 recall. Dryhome Damp & Mould averaged 3.00 with 1 recall, while Brightfix Plumbing had the lowest average rating (2.17) and the most recalls (2). Keystone Roofing was excluded because it had fewer than 3 completed jobs.

-- R9: Which wards reported Urgent jobs in January–March but none in April–June?
SELECT
    p.ward
FROM properties p
JOIN repair_jobs r
ON p.property_id = r.property_id
WHERE priority = 'Urgent'
    AND r.reported_date >= DATE '2026-01-01'
    AND r.reported_date <= DATE '2026-03-31'

EXCEPT

SELECT
    p.ward
FROM properties p
JOIN repair_jobs r
ON p.property_id = r.property_id
WHERE priority = 'Urgent'
    AND r.reported_date >= DATE '2026-04-01'
    AND r.reported_date <= DATE '2026-06-30'

ORDER BY ward;
-- Result: Chorlton was the only ward that reported Urgent repairs between January and March 2026 but reported no Urgent repairs between April and June 2026.
