--Task 1.1: Database Creation with Parameters

CREATE DATABASE university_main
    WITH OWNER = fiswmsi
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    WITH CONNECTION LIMIT = 50
    TEMPLATE = template0;

CREATE DATABASE university_test
    WITH CONNECTION LIMIT = 10
    IS_TEMPLATE = TRUE;

--Task 1.2: Tablespace Operations

CREATE TABLESPACE student_data
    LOCATION '/Users/fiswmsi/pg_tablespaces/students';
CREATE TABLESPACE course_data
    LOCATION '/Users/fiswmsi/pg_tablespaces/courses';

CREATE DATABASE university_distributed
  TEMPLATE = template0
  TABLESPACE = student_data
  ENCODING = 'LATIN9';

--Task 2.1: University Management System
\c university_main;


CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(3,2) CHECK (gpa >= 0.00 AND gpa <= 4.00),
    is_active BOOLEAN,
    graduation_year SMALLINT
);


CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(12,2),
    is_tenured BOOLEAN,
    years_experience INT
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE,
    course_title VARCHAR(100) NOT NULL,
    description TEXT,
    credits SMALLINT,
    max_enrollment INT,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

--Task 2.2: Time-based and Specialized Tables

CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INT REFERENCES courses(course_id),
    professor_id INT REFERENCES professors(professor_id),
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME WITHOUT TIME ZONE,
    end_time TIME WITHOUT TIME ZONE,
    duration INTERVAL
);

CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    semester VARCHAR(20),
    year INT CHECK (year >= 2000),
    grade CHAR(2),
    attendance_percentage NUMERIC(4,1) CHECK (attendance_percentage >= 0 AND attendance_percentage <= 100),
    submission_timestamp TIMESTAMPTZ,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


--Task 3.1: Modifying Existing Tables
--Modify students table:

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS middle_name VARCHAR(30);

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS student_status VARCHAR(20);

ALTER TABLE students
  ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE students
  ALTER COLUMN student_status SET DEFAULT 'ACTIVE';

ALTER TABLE students
  ALTER COLUMN gpa SET DEFAULT 0.00;


-- Modify professors table:

ALTER TABLE professors
  ADD COLUMN IF NOT EXISTS department_code CHAR(5);

ALTER TABLE professors
  ADD COLUMN IF NOT EXISTS research_area TEXT;

ALTER TABLE professors
  ALTER COLUMN years_experience TYPE SMALLINT
  USING years_experience::SMALLINT;

ALTER TABLE professors
  ALTER COLUMN is_tenured SET DEFAULT FALSE;

ALTER TABLE professors
  ADD COLUMN IF NOT EXISTS last_promotion_date DATE;


-- Modify courses table:

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS prerequisite_course_id INT;

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS difficulty_level SMALLINT;

ALTER TABLE courses
  ALTER COLUMN course_code TYPE VARCHAR(10);

ALTER TABLE courses
  ALTER COLUMN credits SET DEFAULT 3;

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS lab_required BOOLEAN DEFAULT FALSE;


--Task 3.2: Column Management Operations
    --For class_schedule table:

ALTER TABLE class_schedule
  ADD COLUMN IF NOT EXISTS room_capacity INT;

ALTER TABLE class_schedule
  DROP COLUMN IF EXISTS duration;

ALTER TABLE class_schedule
  ADD COLUMN IF NOT EXISTS session_type VARCHAR(15);

ALTER TABLE class_schedule
  ALTER COLUMN classroom TYPE VARCHAR(30);

ALTER TABLE class_schedule
  ADD COLUMN IF NOT EXISTS equipment_needed TEXT;

    --For student_records table:

ALTER TABLE student_records
  ADD COLUMN IF NOT EXISTS extra_credit_points NUMERIC(3,1);

ALTER TABLE student_records
  ALTER COLUMN grade TYPE VARCHAR(5);

ALTER TABLE student_records
  ALTER COLUMN extra_credit_points SET DEFAULT 0.0;

ALTER TABLE student_records
  ADD COLUMN IF NOT EXISTS final_exam_date DATE;

ALTER TABLE student_records
  DROP COLUMN IF EXISTS last_updated;


--Task 4.1: Additional Supporting Tables

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code CHAR(5) UNIQUE,
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(14,2) CHECK (budget >= 0),
    established_year INT
);

CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10,2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    book_id INT REFERENCES library_books(book_id),
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount NUMERIC(10,2),
    loan_status VARCHAR(20)
);


--Task 4.2: Table Modifications for Integration

ALTER TABLE professors
  ADD COLUMN IF NOT EXISTS department_id INT;

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS advisor_id INT;

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS department_id INT;


CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL,
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2)
);

CREATE TABLE semester_calendar(
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ NOT NULL,
    is_current BOOLEAN
);

--Task 5.1: Conditional Table Operations

DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL,
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2),
    description TEXT
);

DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT CHECK (academic_year >= 2000),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    is_current BOOLEAN DEFAULT FALSE
);


--Task 5.2: Database Cleanup

\c postgres;

UPDATE pg_database
SET datistemplate = FALSE
WHERE datname = 'university_test';

DROP DATABASE IF EXISTS university_test;

DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
    WITH TEMPLATE = university_main
    OWNER = fiswmsi;

SELECT current_database();