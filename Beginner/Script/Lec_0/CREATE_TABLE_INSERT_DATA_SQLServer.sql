-- Table: departments
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100)
);

-- Table: teachers
CREATE TABLE teachers (
    teacher_id INT PRIMARY KEY
);

-- Table: courses
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    teacher_id INT,
    department_id INT,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Table: students
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Table: enrollments
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    score FLOAT,
    student_id INT,
    course_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);


-- Departments

INSERT INTO departments VALUES (1, 'Computer Science');
INSERT INTO departments VALUES (2, 'Mathematics');
INSERT INTO departments VALUES (3, 'Literature');

-- Teachers

INSERT INTO teachers VALUES (1001);
INSERT INTO teachers VALUES (1002);
INSERT INTO teachers VALUES (1003);

-- Courses (Some with NULLs)

INSERT INTO courses VALUES (2001, 1001, 1);
INSERT INTO courses VALUES (2002, 1002, 2);
INSERT INTO courses VALUES (2003, NULL, 3);         -- Teacher is NULL
INSERT INTO courses VALUES (2004, 1003, NULL);      -- Department is NULL

-- Students (Some with NULLs)

INSERT INTO students VALUES (3001, 'Alice', 20, 'Female', 1);
INSERT INTO students VALUES (3002, 'Bob', 21, 'Male', 2);
INSERT INTO students VALUES (3003, 'Charlie', NULL, 'Male', NULL);  -- Age and department are NULL
INSERT INTO students VALUES (3004, NULL, 22, 'Female', 3);          -- Name is NULL

-- Enrollments (Some with NULLs)

INSERT INTO enrollments VALUES (4001, 88.5, 3001, 2001);
INSERT INTO enrollments VALUES (4002, NULL, 3002, 2002);            -- Score is NULL
INSERT INTO enrollments VALUES (4003, 95.0, NULL, 2003);            -- Student is NULL
INSERT INTO enrollments VALUES (4004, 75.0, 3003, NULL);            -- Course is NULL
