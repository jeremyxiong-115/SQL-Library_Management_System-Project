-- Library Management System Project


-- Create "branch" table
/*
drop table branch;
create table branch
(
	branch_id varchar(10) primary key,
	manager_id varchar(10),
	branch_address varchar(30),
	contact_no varchar(15)
);

-- Create "employees" table
drop table employees;
create table employees
(
	emp_id varchar(10) primary key,
	emp_name varchar(30),
	position varchar(30),
	salary decimal(10,2),
	branch_id varchar(10),
	foreign key (branch_id) references branch(branch_id)
);

-- Create "books" table
drop table books;
create table books
(
	isbn varchar(50) primary key,
	book_title varchar(80),
	category varchar(30),
	rental_price decimal(10,2),
	status varchar(10),
	author varchar(30),
	publisher varchar(30)
);

-- Create "members" table
drop table members;
create table members
(
	member_id varchar(10) primary key,
    member_name varchar(30),
    member_address varchar(30),
    reg_date date
);

-- Create "issued_status" table
drop table issued_status;
create table issued_status
(
	issued_id varchar(10) primary key,
	issued_member_id varchar(10),
	issued_book_name varchar(80),
	issued_date date,
	issued_book_isbn varchar(50),
	issued_emp_id varchar(10),
	foreign key (issued_member_id) references members(member_id),
	foreign key (issued_emp_id) references employees(emp_id),
	foreign key (issued_book_isbn) references books(isbn) 
);

-- Create table "return_status"
drop table return_status;
create table return_status
(
	return_id varchar(10) primary key,
	issued_id varchar(30),
	return_book_name varchar(80),
	return_date date,
	return_book_isbn varchar(50),
	foreign key (return_book_isbn) references books(isbn)	
);
*/


select * from SQL_Project_2.dbo.books
select * from SQL_Project_2.dbo.branch
select * from SQL_Project_2.dbo.employees
select * from SQL_Project_2.dbo.issued_status
select * from SQL_Project_2.dbo.members
select * from SQL_Project_2.dbo.return_status

alter table issued_status
alter column issued_date date

alter table members
alter column reg_date date

alter table return_status
alter column return_date date


-- Task 1. Create a New Book Record
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn, book_title, category,rental_price, status, author, publisher)
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- Task 2: Update an Existing Member's Address
update members
set member_address = '125 Main St'
where member_id = 'C101'

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS107' from the issued_status table.
delete from issued_status
where issued_id = 'IS107'

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from SQL_Project_2..issued_status
where issued_emp_id = 'E101'

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.
select 
	issued_emp_id,
	count(issued_id) total_book_issued
from SQL_Project_2..issued_status
group by issued_emp_id

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
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
select * from book_counts

-- Task 7: Find Total Rental Income by Category
select 
	b.category,
	sum(b.rental_price) total_rental_price
	--count(*)
from books b
join issued_status iss 
	on iss.issued_book_isbn = b.isbn
group by b.category
order by total_rental_price desc

-- Task 8: List Employees with Their Branch Manager's Name and their branch details
select
	e1.*,
	b.manager_id,
	e2.emp_name manager
from employees e1
join branch b
	on b.branch_id = e1.branch_id
join employees e2
	on b.manager_id = e2.emp_id

-- Task 9: Retrieve the List of Books Not Yet Returned
select distinct
	iss.issued_book_name
from issued_status iss
left join return_status rs
	on iss.issued_id = rs.issued_id
where rs.return_id is null

/* 
Task 10: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.
*/
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
order by 1

/* 
Task 11: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

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
select * from branch_reports


-- Task 12: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
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
having count(iss.issued_id) > 3