# Library Management System SQL Project

## Project Overview

**Project Title**: Library Management System  
**Level**: Intermediate  
**Database**: `SQL_Project_2`

This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup

- **Database Creation**: Created a database named `SQL_Project_2`.
- **Table Creation**: Created tables for branches, employees, members, books, issued status, and return status. Each table includes relevant columns and foreign key relationships.

```sql
-- Branch Table
CREATE TABLE branch
(
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no VARCHAR(15)
);

-- Employees Table
CREATE TABLE employees
(
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),
    position VARCHAR(30),
    salary DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Members Table
CREATE TABLE members
(
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(30),
    member_address VARCHAR(30),
    reg_date DATE
);

-- Books Table
CREATE TABLE books
(
    isbn VARCHAR(50) PRIMARY KEY,
    book_title VARCHAR(80),
    category VARCHAR(30),
    rental_price DECIMAL(10,2),
    status VARCHAR(10),
    author VARCHAR(30),
    publisher VARCHAR(30)
);

-- Issued Status Table
CREATE TABLE issued_status
(
    issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(30),
    issued_book_name VARCHAR(80),
    issued_date DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

-- Return Status Table
CREATE TABLE return_status
(
    return_id VARCHAR(10) PRIMARY KEY,
    issued_id VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.
- **Read**: Retrieved and displayed data from various tables.
- **Update**: Updated records such as member addresses.
- **Delete**: Removed records from the `issued_status` table.

**Task 1. Create a New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
insert into books(isbn, book_title, category,rental_price, status, author, publisher)
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**Task 2: Update an Existing Member's Address**

```sql
update members
set member_address = '125 Main St'
where member_id = 'C101';
```

**Task 3: Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS107' from the issued_status table.

```sql
delete from issued_status
where issued_id = 'IS107';
```

**Task 4: Retrieve All Books Issued by a Specific Employee**
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
```sql
select * from SQL_Project_2..issued_status
where issued_emp_id = 'E101';
```

**Task 5: List Members Who Have Issued More Than One Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.
```sql
select 
	issued_emp_id,
	count(issued_id) total_book_issued
from SQL_Project_2..issued_status
group by issued_emp_id;
```

### 3. CTAS (Create Table As Select)

- **Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_counts
```sql
with book_counts as
(
	select 
		b.isbn,
		b.book_title,
		count(iss.issued_id) no_issued
	from books b
	join issued_status iss 
		on iss.issued_book_isbn = b.isbn
	group by b.isbn, b.book_title
)
select * from book_counts;
```

### 4. Data Analysis & Findings

**Task 7: Find Total Rental Income by Category**:
```sql
select 
	b.category,
	sum(b.rental_price) total_rental_price
	--count(*)
from books b
join issued_status iss 
	on iss.issued_book_isbn = b.isbn
group by b.category
order by total_rental_price desc;
```

**Task 8: List Employees with Their Branch Manager's Name and their branch details**:
```sql
select
	e1.*,
	b.manager_id,
	e2.emp_name manager
from employees e1
join branch b
	on b.branch_id = e1.branch_id
join employees e2
	on b.manager_id = e2.emp_id;
```

**Task 9: Retrieve the List of Books Not Yet Returned**:
```sql
select distinct
	iss.issued_book_name
from issued_status iss
left join return_status rs
	on iss.issued_id = rs.issued_id
where rs.return_id is null;
```

**Task 10: Identify Members with Overdue Books**: Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue:
```sql
-- issued_status = memebers = books = return_status, filter books which is return, overdue > 30
select 
	iss.issued_member_id,
	m.member_name,
	b.book_title,
	iss.issued_date,
	--rs.return_date,
	datediff(day, iss.issued_date, '2024-5-01') over_dues_days
from issued_status iss
join members m
	on iss.issued_member_id = m.member_id
join books b
	on iss.issued_book_isbn = b.isbn
left join return_status rs
	on iss.issued_id = rs.issued_id
where 
	rs.return_date is null and datediff(day, iss.issued_date, '2024-5-01') > 30
order by 1;
```

**Task 11: Branch Performance Report**: Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals:
```sql
with branch_reports as
(
	select 
		br.branch_id,
		br.manager_id,
		count(iss.issued_id) number_book_issued,
		count(rs.return_id) number_book_returned,
		sum(b.rental_price) total_revenue
	from issued_status iss
	join employees e
		on iss.issued_emp_id = e.emp_id
	join branch br
		on e.branch_id = br.branch_id
	left join return_status rs
		on iss.issued_id = rs.issued_id
	join books b
		on iss.issued_book_isbn = b.isbn
	group by br.branch_id, br.manager_id
)
select * from branch_reports;
```

**Task 12: Find Employees with the Most Book Issues Processed**: Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch:
```sql
select 
	e.emp_name,
	br.*,
	count(iss.issued_id) books_processed
from issued_status iss
join employees e
	on iss.issued_emp_id = e.emp_id
join branch br
	on br.branch_id = e.branch_id
group by 
	e.emp_name, 
	br.branch_address,
	br.branch_id,
	br.contact_no,
	br.manager_id
having count(iss.issued_id) > 3;
```

## Findings

- **Member Insights**: The analysis identifies active members who frequently borrow books, as well as members with overdue books, helping understand borrowing behavior.
- **Book Insights**: Popular books and categories were identified based on issue counts and total rental income, highlighting high-demand titles and categories.
- **Branch Performance**: Branch-wise reports reveal the number of books issued and returned, along with total revenue generated, enabling performance comparison across branches.
- **Employee Productivity**: Top-performing employees were identified based on the number of books processed, providing insight into staff efficiency.
- **Overdue and Risk Management**: The system flags overdue books and members issuing damaged books multiple times, supporting library management in enforcing rules and calculating fines.
- **Overall System Analysis**: The queries and reports provide actionable insights into library operations, member behavior, and book circulation trends, which can be used to optimize book availability, staff allocation, and revenue generation.


