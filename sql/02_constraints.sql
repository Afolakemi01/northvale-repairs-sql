-- C1: Primary keys on all three tables.
ALTER TABLE repair_jobs
ADD CONSTRAINT pk_repair_jobs
PRIMARY KEY (job_id);

ALTER TABLE properties
ADD CONSTRAINT pk_properties
PRIMARY KEY (property_id);

ALTER TABLE contractors
ADD CONSTRAINT pk_contractors
PRIMARY KEY (contractor_id);

-- verify:
\d repair_jobs
\d properties
\d contractors

-- C2: Foreign keys from repair_jobs to properties and to contractors.
ALTER TABLE repair_jobs
ADD CONSTRAINT fk_repair_jobs_contractor_id
    FOREIGN KEY (contractor_id)
    REFERENCES contractors(contractor_id),

ADD CONSTRAINT fk_repair_jobs_property_id
    FOREIGN KEY (property_id)
    REFERENCES properties(property_id);

-- verify:
\d repair_jobs

-- C3: NOT NULL on priority and reported_date
ALTER TABLE repair_jobs
ALTER COLUMN priority SET NOT NULL;

ALTER TABLE repair_jobs
ALTER COLUMN reported_date SET NOT NULL;

-- verify:
\d repair_jobs

-- C4: CHECKs: priority is one of the three values; completed date is not before the reported date; cost is not negative; rating is between 1 and 5.
ALTER TABLE repair_jobs
ADD CONSTRAINT chk_repair_jobs_priority
CHECK (priority IN ('Emergency', 'Urgent', 'Routine')),

ADD CONSTRAINT chk_repair_jobs_dates
CHECK (completed_date >= reported_date),

ADD CONSTRAINT chk_repair_jobs_cost
CHECK (cost >= 0),

ADD CONSTRAINT chk_repair_jobs_rating
CHECK (tenant_rating BETWEEN 1 AND 5);

-- verify:
\d repair_jobs

-- Confirmation of constraints:
-- Verify: an invalid priority is rejected (expected to fail)
INSERT INTO repair_jobs (
    job_id, property_id, contractor_id, priority,
    description, reported_date, completed_date,
    cost, tenant_rating, original_job_id
)
VALUES (
    2001, 101, 2, 'personal',
    'Test constraint', '2026-01-05', '2026-01-05',
    180.00, 3, NULL
);
-- ERROR:  new row for relation "repair_jobs" violates check constraint "chk_repair_jobs_priority"


-- Verify: an out-of-range rating is rejected (expected to fail)
INSERT INTO repair_jobs (
    job_id, property_id, contractor_id, priority,
    description, reported_date, completed_date,
    cost, tenant_rating, original_job_id
)
VALUES (
    2001, 101, 2, 'Urgent',
    'Test constraint', '2026-01-05', '2026-01-05',
    180.00, 9, NULL
);
-- ERROR:  new row for relation "repair_jobs" violates check constraint "chk_repair_jobs_rating"
