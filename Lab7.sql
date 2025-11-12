--PART 1

CREATE TABLE employees(
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects(
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);


INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

--PART 2
--TASK 2.1

CREATE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- 4, because Tom Brown's dept_id is NULL

-- TASK 2.2

CREATE VIEW dept_statistics AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS avg_salary,
    MAX(e.salary) AS max_salary,
    MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

--TASK 2.3

CREATE VIEW project_overview AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY
    p.project_id,
    p.project_name,
    p.budget,
    d.dept_name,
    d.location;

SELECT * FROM project_overview;

--TASK 2.4

CREATE VIEW high_earners AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;

--You will see only employees earning more than $55,000
--You will not see high-earners who don’t have a department, because the INNER JOIN removes them.


--PART 3
--TASK 3.1

CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

--TASK 3.2

ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

--TASK 3.3

CREATE VIEW temp_view AS
SELECT emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;

DROP VIEW IF EXISTS temp_view;

--PART 4
--TASK 4.1

CREATE VIEW employee_salaries AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees;

SELECT * FROM employee_salaries;

--TASK 4.2

UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT *
FROM employees
WHERE emp_name = 'John Smith';

--YES

--TASK 4.3

INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees;

--YES

--TASK 4.4

CREATE VIEW it_employees AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

SELECT * FROM it_employees;

INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);

--[44000] ERROR: new row violates check option for view "it_employees"
-- Detail: Failing row contains (7, Bob Wilson, 103, 60000.00).

--Because dept_id = 103 doesn’t match the view condition dept_id = 101, so it violates the CHECK OPTION rule and is rejected.

--PART 5
--TASK 5.1

CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    COALESCE(COUNT(DISTINCT e.emp_id), 0) AS total_employees,
    COALESCE(SUM(e.salary), 0) AS total_salaries,
    COALESCE(COUNT(DISTINCT p.project_id), 0) AS total_projects,
    COALESCE(SUM(p.budget), 0) AS total_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

SELECT *
FROM dept_summary_mv
ORDER BY total_employees DESC;


--TASK 5.2

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

/*
Before refresh:The materialized view still showed old data (2 employees in IT, total salary 105000).

After refresh:The view was updated to include Charlie Brown, showing 3 employees and total salary 159000.
 */

--TASK 5.3

CREATE UNIQUE INDEX dept_summary_mv_idx
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

--The CONCURRENTLY option lets you refresh a materialized view without blocking reads, so users can keep using it during the refresh.

--TASK 5.4

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_name, p.budget, d.dept_name
WITH NO DATA;

SELECT * FROM project_stats_mv;

/*
 [55000] ERROR: materialized view "project_stats_mv" has not been populated
  Hint: Use the REFRESH MATERIALIZED VIEW command.
 */

REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;

--WITH NO DATA means the materialized view is created, but it’s not yet populated — no query results are stored in it.

--PART 6
--TASK 6.1

CREATE ROLE analyst;

CREATE ROLE data_viewer
LOGIN
PASSWORD 'viewer123';

CREATE USER report_user
WITH PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

--TASK 6.2

CREATE ROLE db_creator
WITH
    LOGIN
    CREATEDB
    PASSWORD 'creator789';

CREATE ROLE user_manager
WITH
    LOGIN
    CREATEROLE
    PASSWORD 'manager101';

CREATE ROLE admin_user
WITH
    LOGIN
    SUPERUSER
    PASSWORD 'admin999';

SELECT rolname, rolcreatedb, rolcreaterole, rolsuper
FROM pg_roles
WHERE rolname IN ('db_creator', 'user_manager', 'admin_user');


--TASK 6.3

GRANT SELECT ON employees, departments, projects TO analyst;

GRANT ALL PRIVILEGES ON employee_details TO data_viewer;

GRANT SELECT, INSERT ON employees TO report_user;


--TASK 6.4

CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1 WITH PASSWORD 'hr001';
CREATE USER hr_user2 WITH PASSWORD 'hr002';
CREATE USER finance_user1 WITH PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;

GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;

GRANT SELECT ON dept_statistics TO finance_team;

--TASK 6.5

REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

--TASK 6.6

ALTER ROLE analyst
WITH LOGIN PASSWORD 'analyst123';

ALTER ROLE user_manager
WITH SUPERUSER;

ALTER ROLE analyst
WITH PASSWORD NULL;

ALTER ROLE data_viewer
WITH CONNECTION LIMIT 5;

--PART 7
--TASK 7.1

CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;


--TASK 7.2

CREATE ROLE project_manager
WITH LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

--TASK 7.3

CREATE ROLE temp_owner WITH LOGIN;

CREATE TABLE temp_table (
    id INT
);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO fiswmsi;

DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

SELECT tablename, tableowner
FROM pg_tables
WHERE tablename = 'temp_table';

--TASK 7.4

CREATE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


--PART 8
--TASK 8.1

CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,

    COUNT(e.emp_id) AS employee_count,

    ROUND(AVG(e.salary), 2) AS avg_salary,

    COUNT(DISTINCT p.project_id) AS active_projects,

    COALESCE(SUM(p.budget), 0) AS total_budget,

    ROUND(COALESCE(SUM(p.budget) / NULLIF(COUNT(e.emp_id), 0), 0), 2)
        AS budget_per_employee

FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name, d.location;

--TASK 8.2

ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,

    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status

FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects
ORDER BY budget DESC;

--TASK 8.3

CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;


CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;


CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;


CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;


CREATE USER alice WITH PASSWORD 'alice123';
CREATE USER bob WITH PASSWORD 'bob123';
CREATE USER charlie WITH PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;