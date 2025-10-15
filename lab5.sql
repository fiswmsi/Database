--Mukhtarova Sarbinaz
--Id 24B031900

CREATE DATABASE lab5;

--PART 1
--Task 1.1

CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

--Task 1.2

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount
        CHECK (
            regular_price > 0
            AND discount_price > 0
            AND discount_price < regular_price
        )
);

--Task 1.3

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

--Task 1.4

INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES
(1, 'Sarbinaz', 'Mukhtarova', 19, 150000),
(2, 'Nazym', 'Sarsenbai', 32, 170000);

-- Violates: age CHECK (must be between 18 and 65)
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (3, 'Dilya', 'Lee', 15, 4000);

-- Violates: salary CHECK (must be > 0)
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (4, 'Dilya', 'Lee', 30, 0);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES
(1, 'Phone', 150000, 135000),
(2, 'Headphones', 50000, 40000);

-- Violates: regular_price > 0 and discount_price > 0
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (3, 'Monitor', 0, 0);

-- Violates: discount_price < regular_price
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (4, 'Keyboard', 50000, 55000);


INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES
(1, '2025-10-15', '2025-10-20', 2),
(2, '2025-11-01', '2025-11-05', 5);

-- Violates: num_guests CHECK (1–10)
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (3, '2025-10-10', '2025-10-15', 11);

-- Violates: check_out_date > check_in_date
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (4, '2025-10-20', '2025-10-18', 3);


--PART 2
--Task 2.1

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

--Task 2.2

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

--Task 2.3

--customers
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES
(1, 'maria@gmail.com', '87001234567', '2025-10-15'),
(2, 'alex@gmail.com', '87007654321', '2025-10-14');

-- Missing customer_id (NOT NULL)
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (NULL,  'dilya@gmail.com', '87001112233', '2025-10-12');

-- Missing registration_date (NOT NULL)
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (3, 'sofia@gmail.com', '87009998877', NULL);

-- Phone can be NULL
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (5, 'no_phone@mail.com', NULL, '2025-10-13');


--inventory

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES
(1, 'Laptop', 18, 150000, '2025-10-15 10:00:00'),
(2, 'Phone', 77, 249999, '2025-10-15 10:30:00');

-- item_name (NOT NULL)
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (3, NULL, 15, 40000, '2025-10-15 11:00:00');

-- last_updated (NOT NULL)
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (5, 'Monitor', 5, 200, NULL);

-- unit_price (NOT NULL)
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (4, 'Headphone', 20, NULL, '2025-10-15 11:10:00');

-- quantity < 0
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (6, 'TV', -3, 400000, '2025-10-15 11:30:00');

-- unit_price <= 0
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (7, 'USB', 25, 0, '2025-10-15 11:40:00');

--PART 3
--Task 3.1

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

--Task 3.2

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment
        UNIQUE (student_id, course_code, semester)
);

--Task 3.3

ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users (user_id, username, email, created_at)
VALUES
(1, 'Dilya', 'dilya@gmail.com', '2025-10-15 10:00:00'),
(2, 'nurdana', 'nurdana@mail.com', '2025-10-15 10:30:00');

-- Duplicate username
INSERT INTO users (user_id, username, email, created_at)
VALUES (3, 'Dilya', 'dily@gmail.com', '2025-10-15 11:00:00');

-- Duplicate email
INSERT INTO users (user_id, username, email, created_at)
VALUES (4, 'Nazym', 'dilya@gmail.com', '2025-10-15 11:10:00');


--PART 4
--Task 4.1

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments (dept_id, dept_name, location)
VALUES
(1, 'HR', 'A'),
(2, 'IT', 'B'),
(3, 'PR', 'C');

--Duplicate dept_id
INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'Sales', 'A');

--NULL dept_id
INSERT INTO departments (dept_id, dept_name, location)
VALUES (NULL, 'HR', 'B');

--Task 4.2

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

--Task 4.3

--1.PRIMARY KEY uniquely identifies each row and can’t be NULL (only one per table)
--UNIQUE also prevents duplicates but allows one NULL and you can have many UNIQUE columns

--2.Use a single key if one column is enough (e.g., dept_id)
--Use a composite key if two or more columns together must be unique (e.g., student_id + course_id)

--3.A table can have one PRIMARY KEY as its main identifier, but several UNIQUE constraints to keep other columns (like email or username) different


--PART 5
--Task 5.1

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Assuming departments table has dept_id 1, 2, 3

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES
(101, 'Dilnaz Lee', 1, '2025-10-15'),
(102, 'Nurdana Khan', 2, '2025-10-14');

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (103, 'Adel Kikbay', 7, '2025-10-13');

--Task 5.2

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors (author_id, author_name, country)
VALUES
(1, 'J.K. Rowling', 'United Kingdom'),
(2, 'George Orwell', 'United Kingdom'),
(3, 'Haruki Murakami', 'Japan');

INSERT INTO publishers (publisher_id, publisher_name, city)
VALUES
(1, 'Bloomsbury', 'London'),
(2, 'Penguin Books', 'New York'),
(3, 'Kodansha', 'Tokyo');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
VALUES
(1, '1984', 2, 2, 1949, 'ISBN-001'),
(2, 'Kafka on the Shore', 3, 3, 2002, 'ISBN-002'),
(3, 'Harry Potter and the Philosophers Stone', 1, 1, 1997, 'ISBN-003' );

--Task 5.3

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);


INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Books');

INSERT INTO products_fk VALUES
(101, 'Laptop', 1),
(102, 'Novel', 2);

INSERT INTO orders VALUES
(201, '2025-10-15'),
(202, '2025-10-16');

INSERT INTO order_items VALUES
(301, 201, 101, 2),
(302, 201, 102, 1),
(303, 202, 102, 3);

--1Try to delete a category that has products (should fail with RESTRICT)
DELETE FROM categories WHERE category_id = 1;
--ERROR: update or delete on table "categories" violates foreign key constraint

--2.Delete an order and observe that order_items are automatically deleted (CASCADE)
DELETE FROM orders WHERE order_id = 201;


--PART 6
--Task 6.1

CREATE DATABASE lab5_part6;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
(1, 'Dilya Khan', 'dilya@gmail.com', '87001112233', '2025-01-10'),
(2, 'Nurdana Lee', 'nurdana@gmail.com', '87002223344', '2025-02-12'),
(3, 'Sara Kim', 'sara@gmail.com', '87003334455', '2025-03-05'),
(4, 'John Smith', 'john@gmail.com', '87004445566', '2025-03-20'),
(5, 'Black White', 'black@gmail.com', '87005556677', '2025-04-10');

INSERT INTO products VALUES
(1, 'Laptop', '14-inch business laptop', 150000.00, 10),
(2, 'Mouse', 'Wireless mouse', 25999.99, 50),
(3, 'Keyboard', 'Mechanical keyboard', 89000.00, 30),
(4, 'Monitor', '27-inch LED display', 150000.00, 20),
(5, 'Headphones', 'Noise cancelling', 43000.00, 15);

INSERT INTO orders VALUES
(101, 1, '2025-05-01', 1625.99, 'pending'),
(102, 2, '2025-05-03', 239.00, 'processing'),
(103, 3, '2025-05-04', 300.00, 'shipped'),
(104, 4, '2025-05-06', 150.00, 'delivered'),
(105, 5, '2025-05-08', 89.00, 'cancelled');

INSERT INTO order_details VALUES
(1, 101, 1, 1, 150000.00),
(2, 101, 2, 1, 25999.99),
(3, 102, 3, 2, 89000.00),
(4, 103, 4, 1, 150000.00),
(5, 104, 5, 1, 43000.00);

--Test queries demonstrating that all constraints work correctly

--Price must be >= 0
INSERT INTO products VALUES (6, 'Test Item', 'Bad data', -50, 5);

-- customer_id 73 does not exist
INSERT INTO orders VALUES (106, 73, '2025-05-10', 100, 'pending');

-- duplicate email
INSERT INTO customers VALUES (6, 'Bob', 'dilya@gmail.com', '87006667788', '2025-05-10');

-- Deletes customer 1 and all their orders + order_details automatically
DELETE FROM customers WHERE customer_id = 1;
