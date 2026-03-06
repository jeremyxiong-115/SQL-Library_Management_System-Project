# 图书管理系统 SQL 项目

## 项目概述

**项目名称**：图书管理系统
**难度等级**：中级
**数据库**：`SQL_Project_2`

本项目展示了如何使用 SQL 实现图书管理系统，包括创建和管理表、执行 CRUD 操作以及高级 SQL 查询。目标是展示数据库设计、操作和查询技能。

## 项目目标

1. **搭建图书管理系统数据库**：创建并填充分支、员工、会员、图书、借阅状态和归还状态等表。
2. **CRUD 操作**：对数据执行创建、读取、更新和删除操作。
3. **CTAS（Create Table As Select）**：利用 CTAS 基于查询结果创建新表。
4. **高级 SQL 查询**：开发复杂查询以分析和检索特定数据。

## 项目结构

### 1. 数据库设置

* **数据库创建**：创建名为 `SQL_Project_2` 的数据库。
* **表创建**：创建分支、员工、会员、图书、借阅状态和归还状态表，每个表包含相关列及外键关系。

```sql
-- Branch 表
CREATE TABLE branch
(
    branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no VARCHAR(15)
);

-- Employees 表
CREATE TABLE employees
(
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),
    position VARCHAR(30),
    salary DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Members 表
CREATE TABLE members
(
    member_id VARCHAR(10) PRIMARY KEY,
    member_name VARCHAR(30),
    member_address VARCHAR(30),
    reg_date DATE
);

-- Books 表
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

-- Issued Status 表
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

-- Return Status 表
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

### 2. CRUD 操作

* **创建 (Create)**：向 `books` 表插入示例记录。
* **读取 (Read)**：从各个表中检索并显示数据。
* **更新 (Update)**：更新会员地址等记录。
* **删除 (Delete)**：从 `issued_status` 表中删除记录。

**任务 1：创建新图书记录**

```sql
insert into books(isbn, book_title, category,rental_price, status, author, publisher)
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**任务 2：更新现有会员地址**

```sql
update members
set member_address = '125 Main St'
where member_id = 'C101';
```

**任务 3：删除借阅状态表中的记录**

```sql
delete from issued_status
where issued_id = 'IS107';
```

**任务 4：检索特定员工借出的所有图书**

```sql
select * from SQL_Project_2..issued_status
where issued_emp_id = 'E101';
```

**任务 5：列出借出超过一本书的会员**

```sql
select 
	issued_emp_id,
	count(issued_id) total_book_issued
from SQL_Project_2..issued_status
group by issued_emp_id;
```

### 3. CTAS（创建表作为查询结果）

* **任务 6：生成汇总表**：使用 CTAS 或 CTE 基于查询结果生成新表，统计每本书的借阅次数。

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

### 4. 数据分析与发现

**任务 7：按类别统计总租金收入**

```sql
select 
	b.category,
	sum(b.rental_price) total_rental_price
from books b
join issued_status iss 
	on iss.issued_book_isbn = b.isbn
group by b.category
order by total_rental_price desc;
```

**任务 8：列出员工及其分支经理信息和分支详情**

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

**任务 9：检索尚未归还的图书列表**

```sql
select distinct
	iss.issued_book_name
from issued_status iss
left join return_status rs
	on iss.issued_id = rs.issued_id
where rs.return_id is null;
```

**任务 10：识别逾期未还的会员**

```sql
select 
	iss.issued_member_id,
	m.member_name,
	b.book_title,
	iss.issued_date,
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

**任务 11：分支绩效报告**

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

**任务 12：找出处理借阅量最多的员工**

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

## 分析结果

* **会员洞察**：识别了活跃会员和逾期会员，帮助了解借书行为。
* **图书洞察**：根据借阅次数和总租金收入，识别了热门书籍和热门类别。
* **分支绩效**：按分支统计的借出/归还数量及总收入，可用于分支绩效对比。
* **员工效率**：根据处理借阅量识别高效员工，提供员工效率分析。
* **逾期与风险管理**：系统标记逾期图书及多次借出损坏书籍的会员，有助于图书馆执行规则及计算罚款。
* **整体系统分析**：查询和报告提供了对图书馆运营、会员行为和图书流通趋势的可操作性洞察，用于优化图书可用性、员工分配及收入生成。

---

