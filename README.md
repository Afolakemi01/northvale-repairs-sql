# Northvale Homes — Repairs Service Review (SQL)

A PostgreSQL analysis of six months of responsive repair jobs for Northvale Homes, a fictional housing association in Manchester. The raw extract from the repairs system is cleaned, locked down with constraints, and then used to answer nine questions for a board review of the repairs service (January–June 2026).

## Business context

The Repairs Manager needed board-ready figures on three things: whether repairs are completed within target, where work is still outstanding, and which contractors deliver lasting fixes. A previous quarter's figures had been wrong because of bad source data, so data quality and integrity were handled before any reporting.

**Repair targets** (days from reported to completed): Emergency ≤ 1, Urgent ≤ 7, Routine ≤ 28.
**Report date:** 30 June 2026.

## Data

| Table | Rows (after cleaning) | Description |
|---|---|---|
| `properties` | 12 | Homes managed by Northvale, with ward, type and bedrooms |
| `contractors` | 5 | Repair contractors and their trade |
| `repair_jobs` | 28 | One row per repair job: priority, dates, cost, tenant rating, and `original_job_id` when the job is a recall of an earlier one |

## Repository structure

```
sql/
├── 00_setup.sql           Creates the tables and loads the raw extract
├── 01_data_quality.sql    Checks and fixes for five data quality issues
├── 02_constraints.sql     Primary keys, foreign keys, NOT NULL and CHECK constraints
└── 03_repairs_report.sql  Business questions R1–R9
```

## Data quality fixes

Each issue has a check query, a rule-based fix, and a verification query that returns 0 rows.

| Issue | Rows affected | Fix |
|---|---|---|
| Priority values with inconsistent case and stray spaces | 4 | Trimmed and standardised to `Emergency`, `Urgent`, `Routine` |
| Job logged twice by the call centre | 1 | Kept the lower job number, removed the duplicate |
| Test job against a property not in the portfolio | 1 | Removed |
| Completion date earlier than reported date | 1 | Corrected to the date on the paper job sheet (24 March 2026) |
| Negative cost (sign error) | 1 | Sign reversed, amount kept |

## Constraints

| Type | Detail |
|---|---|
| Primary keys | `properties.property_id`, `contractors.contractor_id`, `repair_jobs.job_id` |
| Foreign keys | `repair_jobs.property_id` → `properties`, `repair_jobs.contractor_id` → `contractors` |
| NOT NULL | `repair_jobs.priority`, `repair_jobs.reported_date` |
| CHECK | Priority is one of the three allowed values; completion date is not before reported date; cost is not negative; tenant rating is between 1 and 5 |

The constraints file ends with two INSERT statements that are **expected to fail**, demonstrating that invalid priorities and out-of-range ratings are rejected.

## Key findings

- **R1 — Performance against target:** Urgent repairs performed worst, with 6 of 9 completed on target (66.7%). Emergency (4 of 5) and Routine (8 of 10) both reached 80.0%.
- **R2 — Open jobs:** 4 jobs were open on 30 June. Two were already overdue: a Routine job in Chorlton open for 43 days and an Urgent job in Ancoats open for 10 days.
- **R3 — Properties with no repairs:** 2 Edge Lane (Chorlton) and 19 Chapel Street (Levenshulme) had no repair jobs in the period.
- **R4 — Monthly cost:** Total spend on completed jobs was £5,005 across 28 jobs reported. March was the most expensive month (£1,460); June had no completed spend yet.
- **R5 — Most expensive job per ward:** Moss Side had the highest single cost, with two jobs tied at £640. Ties are shown in full.
- **R6 — Recalls:** 4 recalls were found. The longest gap was 98 days, on a damp repair by Dryhome Damp & Mould.
- **R7 — Recall chain:** Job 1003, a bathroom leak, needed three visits: the original job and two recalls between January and April 2026.
- **R8 — Contractor scorecard:** Oakline Joinery and Volt North Electrical share the highest average rating (4.00), with Oakline ahead on zero recalls. Brightfix Plumbing has the lowest rating (2.43) and the most recalls (2).
- **R9 — Urgent demand by ward:** Chorlton was the only ward with Urgent repairs in January–March and none in April–June.

## Design decisions

- **Fixes follow business rules, not specific rows.** Where the rule allows, fixes are written as conditions, so the script still works on a future extract.
- **Constraints are added after cleaning.** This guarantees that every rule holds for the existing data and for every future insert.
- **Average ratings ignore unrated jobs.** Unrated jobs are excluded rather than treated as zero, which would understate contractor performance.
- **`RANK` for most-expensive jobs.** `RANK` returns every job tied for first place, as the stakeholder requested; `ROW_NUMBER` would silently drop one.

## How to run

Requires PostgreSQL (developed on PostgreSQL 18).

```bash
createdb northvale_repairs
psql -d northvale_repairs
```

Then, inside psql, run the files in order:

```
\i sql/00_setup.sql
\i sql/01_data_quality.sql
\i sql/02_constraints.sql
\i sql/03_repairs_report.sql
```

Always run from `00_setup.sql`, which rebuilds the tables, so the full run is repeatable.

## Limitations and future improvements

- A single six-month extract; trends would need a longer history.
- Recalls are recorded only when staff fill in `original_job_id`, so some may be missing.
- `original_job_id` could be protected with a self-referencing foreign key.
- The duplicate check assumes at most two copies of a job; a `ROW_NUMBER`-based delete would handle any number.
