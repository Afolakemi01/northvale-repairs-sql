-- Northvale Homes: responsive repairs extract, January to June 2026
-- Raw export from the repairs system, loaded as-is. No keys or constraints yet.
-- Run from psql:  \i sql/00_setup.sql   (while connected to northvale_repairs)

DROP TABLE IF EXISTS repair_jobs;
DROP TABLE IF EXISTS contractors;
DROP TABLE IF EXISTS properties;

CREATE TABLE properties (
    property_id   INT,
    address       TEXT,
    ward          TEXT,
    property_type TEXT,
    bedrooms      INT
);

CREATE TABLE contractors (
    contractor_id   INT,
    contractor_name TEXT,
    trade           TEXT
);

CREATE TABLE repair_jobs (
    job_id          INT,
    property_id     INT,
    contractor_id   INT,
    priority        TEXT,
    description     TEXT,
    reported_date   DATE,
    completed_date  DATE,
    cost            NUMERIC(8, 2),
    tenant_rating   INT,
    original_job_id INT
);

INSERT INTO properties (property_id, address, ward, property_type, bedrooms) VALUES
    (101, '14 Pollard Street',   'Ancoats',     'Flat',  1),
    (102, '3 Bengal Street',     'Ancoats',     'Flat',  2),
    (103, '27 Cotton Lane',      'Ancoats',     'House', 3),
    (104, '8 Stockport Road',    'Levenshulme', 'House', 3),
    (105, '41 Barlow Road',      'Levenshulme', 'Flat',  1),
    (106, '19 Chapel Street',    'Levenshulme', 'House', 2),
    (107, '5 Princess Road',     'Moss Side',   'House', 4),
    (108, '62 Moss Lane East',   'Moss Side',   'Flat',  2),
    (109, '11 Claremont Road',   'Moss Side',   'Flat',  1),
    (110, '7 Beech Road',        'Chorlton',    'House', 3),
    (111, '23 Wilbraham Road',   'Chorlton',    'Flat',  2),
    (112, '2 Edge Lane',         'Chorlton',    'Flat',  1);

INSERT INTO contractors (contractor_id, contractor_name, trade) VALUES
    (1, 'Brightfix Plumbing',    'Plumbing'),
    (2, 'Volt North Electrical', 'Electrical'),
    (3, 'Oakline Joinery',       'Joinery'),
    (4, 'Dryhome Damp & Mould',  'Damp'),
    (5, 'Keystone Roofing',      'Roofing');

INSERT INTO repair_jobs (job_id, property_id, contractor_id, priority, description,
                         reported_date, completed_date, cost, tenant_rating, original_job_id) VALUES
    (1001, 101, 2, 'Emergency',  'No power to sockets',                     '2026-01-05', '2026-01-05', 180.00, 5,    NULL),
    (1002, 103, 3, 'Routine',    'Front door sticking',                     '2026-01-08', '2026-01-30', 120.00, 4,    NULL),
    (1003, 107, 1, 'Urgent',     'Leak under bathroom sink',                '2026-01-12', '2026-01-16',  95.00, 3,    NULL),
    (1004, 110, 5, ' urgent',    'Slipped roof tiles',                      '2026-01-19', '2026-01-29', 450.00, 2,    NULL),
    (1005, 108, 4, 'Routine',    'Mould in bedroom',                        '2026-01-22', '2026-02-27', 310.00, 2,    NULL),
    (1006, 101, 3, 'Routine',    'Window handle broken',                    '2026-01-26', '2026-02-10',  60.00, NULL, NULL),
    (1007, 105, 1, 'Emergency',  'Burst pipe in kitchen',                   '2026-02-02', '2026-02-03', 260.00, 4,    NULL),
    (1008, 111, 2, 'Urgent',     'Bathroom light not working',              '2026-02-04', '2026-02-09',  75.00, 3,    NULL),
    (1009, 109, 3, 'ROUTINE',    'Skirting board loose',                    '2026-02-09', '2026-03-09',  85.00, 4,    NULL),
    (1010, 104, 4, 'Routine',    'Damp patch on ceiling',                   '2026-02-11', '2026-03-04', 280.00, 3,    NULL),
    (1011, 102, 1, 'Urgent',     'Toilet not flushing',                     '2026-02-16', '2026-02-27', 110.00, 1,    NULL),
    (1012, 107, 1, 'Urgent',     'Leak under bathroom sink returned',       '2026-02-20', '2026-02-24',  95.00, 2,    1003),
    (1013, 103, 2, 'Emergency',  'Smell of burning from fuse box',          '2026-03-02', '2026-03-04', 520.00, 4,    NULL),
    (1014, 107, 5, 'emergency ', 'Roof leaking into bedroom',               '2026-03-05', '2026-03-06', 640.00, 5,    NULL),
    (1015, 104, 3, 'Routine',    'Kitchen cupboard door hanging off',       '2026-03-10', '2026-03-31',  70.00, 4,    NULL),
    (1016, 104, 3, 'Routine',    'Kitchen cupboard door hanging off',       '2026-03-10', '2026-03-31',  70.00, 4,    NULL),
    (1017, 111, 2, 'Urgent',     'Bathroom light not working again',        '2026-03-12', '2026-03-16',  75.00, NULL, 1008),
    (1018, 108, 3, 'Routine',    'Bedroom door off hinges',                 '2026-03-16', '2026-04-02',  90.00, 5,    NULL),
    (1019, 110, 1, 'Routine',    'Dripping outside tap',                    '2026-03-20', '2026-03-02',  65.00, 4,    NULL),
    (1020, 109, 4, 'Routine',    'Condensation on windows',                 '2026-04-01', '2026-05-06', 240.00, NULL, NULL),
    (1021, 107, 1, 'Urgent',     'Leak under bathroom sink - third visit',  '2026-04-06', '2026-04-09', 140.00, 1,    1012),
    (1022, 102, 3, 'Routine ',   'Wardrobe door broken',                    '2026-04-14', '2026-05-05', 110.00, 3,    NULL),
    (1023, 105, 2, 'Urgent',     'Extractor fan not working',               '2026-04-20', '2026-04-24', -85.00, 4,    NULL),
    (1024, 108, 4, 'Emergency',  'Ceiling collapsing from damp',            '2026-05-04', '2026-05-05', 640.00, 3,    NULL),
    (1025, 101, 1, 'Urgent',     'Boiler losing pressure',                  '2026-05-11', '2026-05-20', 210.00, 2,    NULL),
    (1026, 104, 4, 'Routine',    'Damp patch on ceiling returned',          '2026-06-10', NULL,         NULL,   NULL, 1010),
    (1027, 103, 2, 'Urgent',     'Doorbell and hall light out',             '2026-06-20', NULL,         NULL,   NULL, NULL),
    (1028, 111, 3, 'Routine',    'Kitchen worktop damaged',                 '2026-05-18', NULL,         NULL,   NULL, NULL),
    (1029, 999, 1, 'Routine',    'TEST JOB - ignore',                       '2026-02-01', '2026-02-01',   0.00, NULL, NULL),
    (1030, 109, 1, 'Emergency',  'No hot water or heating',                 '2026-06-29', NULL,         NULL,   NULL, NULL);
