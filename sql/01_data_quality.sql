-- DQ1: find wrong priorities
SELECT job_id,
    priority
FROM repair_jobs
WHERE priority NOT IN ('Emergency', 'Urgent', 'Routine')
OR priority IS NULL;

-- fix: update priorities with trim and initcap
UPDATE repair_jobs
    SET priority = INITCAP(TRIM(priority))
WHERE priority NOT IN ('Emergency', 'Urgent', 'Routine');

-- verify the fix
SELECT job_id,
    priority
FROM repair_jobs
WHERE priority NOT IN ('Emergency', 'Urgent', 'Routine')
OR priority IS NULL;


-- DQ2: checking for duplicate jobs
SELECT property_id,
    reported_date,
    description,
    COUNT(*) AS duplicates
FROM repair_jobs
GROUP BY property_id, reported_date, description
HAVING COUNT(*) > 1;

-- fix: delete duplicate job, removes the higher job_id from each duplicate pair (assumes at most two copies)
DELETE FROM repair_jobs
WHERE job_id IN (
    SELECT MAX(job_id)
    FROM repair_jobs
    GROUP BY property_id, reported_date, description
    HAVING COUNT(*) > 1
);

-- verify the fix
SELECT property_id,
    reported_date,
    description,
    COUNT(*) AS duplicates
FROM repair_jobs
GROUP BY property_id, reported_date, description
HAVING COUNT(*) > 1;
-- Result: 0 rows

-- DQ3: checking for jobs against unknown property id
SELECT r.job_id
FROM repair_jobs r
LEFT JOIN properties p
ON r.property_id = p.property_id
WHERE p.property_id IS NULL;

-- fix: delete job with unknown property
DELETE FROM repair_jobs
WHERE property_id NOT IN (
    SELECT property_id
    FROM properties
);

-- verify:
SELECT r.job_id
FROM repair_jobs r
LEFT JOIN properties p
    ON r.property_id = p.property_id
WHERE p.property_id IS NULL;
-- Result: 0 rows

-- DQ4: check for jobs with completion date before reported date
SELECT job_id
FROM repair_jobs
WHERE completed_date < reported_date;

-- fix: change completed date to the correct date
UPDATE repair_jobs
    SET completed_date = DATE '2026-03-24'
WHERE job_id = 1019;

-- verify:
SELECT job_id
FROM repair_jobs
WHERE completed_date < reported_date;
-- Result: 0 rows

-- DQ5: checking for negative costs
SELECT job_id,
    cost
FROM repair_jobs
WHERE cost < 0;

-- fix: updating the negative cost to a positive one
UPDATE repair_jobs
    SET cost = -cost
WHERE cost < 0;

-- verify:
SELECT job_id,
    cost
FROM repair_jobs
WHERE cost < 0;
-- Result: 0 rows
