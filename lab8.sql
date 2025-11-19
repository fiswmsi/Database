--PART 1

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

--PART 2
--TASK 2.1

CREATE INDEX emp_salary_idx
ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

/*
   ans: There are 2 indexes:  employees_pkey - CREATE UNIQUE INDEX employees_pkey ON public.employees USING btree (emp_id),
   emp_salary_idx - CREATE INDEX emp_salary_idx ON public.employees USING btree (salary)
*/

--TASK 2.2

CREATE INDEX emp_dept_idx
ON employees(dept_id);

SELECT *
FROM employees
WHERE dept_id = 101;

/*
  Indexing foreign keys speeds up JOINs and queries that filter by the foreign key,
  and makes referential integrity checks faster by avoiding full table scans.
*/

--TASK 2.3

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

 /*
    ans:
    Indexes in my database:
	departments_pkey
    emp_dept_idx
    emp_salary_idx
    employees_pkey
    projects_pkey

    Automatically created:  Primary keys automatically generate B-tree indexes
    employees_pkey
    departments_pkey
    projects_pkey
 */

 --PART 3
 --TASK 3.1

CREATE INDEX emp_dept_salary_idx
ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

/*
No, because composite indexes work in order
Composite index (dept_id, salary) is ordered by dept_id first
 */

 --TASK 3.2

CREATE INDEX emp_salary_dept_idx
ON employees(salary, dept_id);

SELECT *
FROM employees
WHERE dept_id = 102 AND salary > 50000;

SELECT *
FROM employees
WHERE salary > 50000 AND dept_id = 102;

/*
 Yes. The index (salary, dept_id) works well for queries starting with salary,
 but not for queries starting with dept_id.
 Column order defines how the B-tree is sorted, so it determines which filters can use the index
*/

--PART 4
--TASK 4.1

ALTER TABLE employees
ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx
ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

/*
  [23505] ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
  Detail: Key (email)=(john.smith@company.com) already exists.
*/

--4.2

ALTER TABLE employees
ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees'
  AND indexname LIKE '%phone%';

/*
 Yes. employees_phone_key
 */

 --PART 5
--TASK 5.1

CREATE INDEX emp_salary_desc_idx
ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

/*
  It eliminates the need to sort the rows, because the index already stores salaries in descending order.
*/

--TASK 5.2

CREATE INDEX proj_budget_nulls_first_idx
ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

--PART 6
--TASK 6.1

CREATE INDEX emp_name_lower_idx
ON employees(LOWER(emp_name));

SELECT *
FROM employees
WHERE LOWER(emp_name) = 'john smith';

/*
 Without the function-based index,
 would perform a full table scan, applying LOWER() to every row to compare values.
*/

--TASK 6.2

ALTER TABLE employees
ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx
ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--PART 7
--TASK 7.1

ALTER INDEX emp_salary_idx
RENAME TO employees_salary_index;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'employees';

--TASK 7.2

DROP INDEX emp_salary_dept_idx;

/*
 Indexes consume disk space and add overhead to write operations
 Dropping unused or redundant indexes improves performance and keeps the database efficient.
 */


--TASK 7.3
REINDEX INDEX employees_salary_index;

/*
  REINDEX is useful when an index becomes bloated or inefficient,
  often after many INSERTs, UPDATEs, DELETEs, or bulk data operations.
*/

--PART 8
--TASK 8.1

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

--TASK 8.2

CREATE INDEX proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

/*
   A partial index is smaller, uses less storage, and is faster because it only indexes rows that match a specific condition.
*/

--TASK 8.3

EXPLAIN SELECT *
FROM employees
WHERE salary > 52000;

/*
      Output shows Seq Scan because the table is very small. For small tables, scanning all rows is cheaper than using an index.
*/

--PART 9
--TASK 9.1

CREATE INDEX dept_name_hash_idx
ON departments USING HASH (dept_name);

SELECT *
FROM departments
WHERE dept_name = 'IT';

/*
   Use a HASH index for fast equality comparisons (=), when you don’t need range searches or ORDER BY.
*/

--TASK 9.2

CREATE INDEX proj_name_btree_idx
ON projects(proj_name);

CREATE INDEX proj_name_hash_idx
ON projects USING HASH (proj_name);

SELECT *
FROM projects
WHERE proj_name = 'Website Redesign';

SELECT *
FROM projects
WHERE proj_name > 'Database';

--Because B-tree indexes maintain sorted order and support range comparisons, while Hash indexes only support equality (=) operations.

--PART 10
--TASK 10.1

SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

/*
The largest indexes are:
    dept_name_hash_idx - 32kB
    proj_name_hash_idx - 32kB

Hash indexes take more space than B-tree indexes because they store hashed buckets and extra metadata.
That’s why they are larger in size.
*/

--TASK 10.2

DROP INDEX IF EXISTS proj_name_hash_idx;

--TASK 10.3

CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

/*
    Summary questions:
    1) B-tree is the default index type
    2) When a column is frequently used in WHERE filters, JOIN conditions
	   When queries frequently sort by a column (ORDER BY)
    3) When the table is very small
       When the column is rarely queried or has very low selectivity
    4) Indexes must also be updated, which makes writes slower
    5) Use EXPLAIN - the plan will show Index Scan instead of Seq Scan if the index is being used
*/