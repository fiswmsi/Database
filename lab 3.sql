--1. Create database and tables

CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    department TEXT,
    salary INT,
    hire_date DATE,
    status TEXT DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name TEXT,
    budget INT,
    manager_id INT
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name TEXT,
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget INT
);

--2. INSERT with column specification

INSERT INTO employees (first_name, last_name, department)
VALUES
('Adel', 'Kikbay', 'Project'),
('Nariman', 'Bakitbekov', 'IT'),
('Beksultan', 'Yessengali', 'HR');

--3. INSERT with DEFAULT values

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Sarbinaz', 'Mukhtarova', 'IT', DEFAULT, '2025-10-01', DEFAULT);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Temirlan', 'Nusipkozha', 'Project', 600001, '2019-07-30', DEFAULT);

-- 4. INSERT multiple rows in single statement

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
('Project', 50000, 1),
('HR', 30000, 2),
('IT', 70000, 3);

--5. INSERT with expressions

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Nazym', 'Sarsenbai', 'Project', 50000 * 1.1, CURRENT_DATE, DEFAULT);

--6. INSERT from SELECT (subquery)

CREATE TEMP TABLE temp_employees AS
SELECT *
FROM employees
WHERE department = 'IT';

--Part C: Complex UPDATE Operations
--7. UPDATE with arithmetic expressions

UPDATE employees
SET salary = salary * 1.1;

--8. UPDATE with WHERE clause and multiple conditions

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

--9. UPDATE using CASE expression

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

--10. UPDATE with DEFAULT

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

--11. UPDATE with subquery

UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
);

--12. UPDATE multiple columns

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

--Part D: Advanced DELETE Operations
--13. DELETE with simple WHERE condition

DELETE FROM employees
WHERE status = 'Terminated';

--14. DELETE with complex WHERE clause

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

--15. DELETE with subquery

DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT d.dept_id
    FROM departments d
    JOIN employees e ON e.department = d.dept_name
    WHERE e.department IS NOT NULL
);

--16. DELETE with RETURNING clause

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--Part E: Operations with NULL Values
--17. INSERT with NULL values

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Omar', 'Urazakov', NULL, NULL, CURRENT_DATE, 'Active');

--18. UPDATE NULL handling

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

--19. DELETE with NULL conditions

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL
RETURNING *;

--Part F: RETURNING Clause Operations
--20. INSERT with RETURNING

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Dilnaz', 'Beisenova', 'IT', 75500, CURRENT_DATE, 'Active')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--21. UPDATE with RETURNING

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

--22. DELETE with RETURNING all columns

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--23. Conditional INSERT

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Gulinur', 'Mukhtarova', 'HR', 45000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Gulinur'
      AND last_name = 'Mukhtarova'
);

--24. UPDATE with JOIN logic using subqueries

UPDATE employees e
SET salary = salary * CASE
    WHEN d.budget > 100000 THEN 1.10
    ELSE 1.05
END
FROM departments d
WHERE e.department = d.dept_name;

--25. Bulk operations

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
('Adik', 'Hairhan', 'Project', 55600, CURRENT_DATE, 'Active'),
('Alim', 'Bakanbaev', 'HR', 40000, CURRENT_DATE, 'Active'),
('Aliya', 'Omarova', 'Finance', 60000, CURRENT_DATE, 'Active'),
('Nursultan', 'Bekov', 'IT', 45000, CURRENT_DATE, 'Active'),
('Aigerim', 'Kairatova', 'IT', 55000, CURRENT_DATE, 'Active');

UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
    ('Aruzhan', 'Tulegen'),
    ('Dias', 'Saparov'),
    ('Madina', 'Omarova'),
    ('Nursultan', 'Bekov'),
    ('Aigerim', 'Kairatova')
);

--26. Data migration simulation

CREATE TABLE employee_archive AS
TABLE employees WITH NO DATA;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

--27. Complex business logic

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND p.dept_id IN (
      SELECT d.dept_id
      FROM departments d
      JOIN employees e ON e.department = d.dept_name
      GROUP BY d.dept_id
      HAVING COUNT(*) > 3
  );