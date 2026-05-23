-- ============================================================================
-- ПР4. DML: INSERT по 10 рядків у кожну таблицю publishing
-- Передумова: запущено pr04_ddl.sql, схема publishing існує.
-- ============================================================================

USE publishing;

-- ===== Базові таблиці =======================================================
START TRANSACTION;

-- AUTHORS (10)
INSERT INTO Authors (Name, Email, Phone, Country) VALUES
 ('Ірина Савчук',  'iryna.savchuk@ex.com',  '+380501111111', 'Ukraine'),
 ('Олег Петренко', 'oleg.petrenko@ex.com',  '+380671111112', 'Ukraine'),
 ('Maria Rossi',   'm.rossi@ex.com',        '+39061111111',  'Italy'),
 ('Jean Martin',   'jean.martin@ex.com',    '+33111111111',  'France'),
 ('Anna Müller',   'anna.mueller@ex.com',   '+41441111111',  'Switzerland'),
 ('Lukas Steiner', 'lukas.steiner@ex.com',  '+41441111112',  'Switzerland'),
 ('Sofia Garcia',  'sofia.garcia@ex.com',   '+34911111111',  'Spain'),
 ('Noah Johnson',  'noah.johnson@ex.com',   '+12025550111',  'USA'),
 ('Akira Tanaka',  'akira.tanaka@ex.com',   '+81311111111',  'Japan'),
 ('Eva Novak',     'eva.novak@ex.com',      '+42021111111',  'Czechia');

-- EMPLOYEES (10) — Role ∈ {Editor, Proofreader, Translator, Designer}
INSERT INTO Employees (Name, Role, Email) VALUES
 ('Alice Novak',     'Editor',      'alice@pub.ch'),
 ('Bohdan Petrenko', 'Proofreader', 'bohdan@pub.ch'),
 ('Chloe Martin',    'Translator',  'chloe@pub.ch'),
 ('Dmytro Savchuk',  'Designer',    'dmytro@pub.ch'),
 ('Emma Rossi',      'Editor',      'emma@pub.ch'),
 ('Felix Weber',     'Proofreader', 'felix@pub.ch'),
 ('Hanna Kovalenko', 'Translator',  'hanna@pub.ch'),
 ('Ivan Horak',      'Designer',    'ivan@pub.ch'),
 ('Julia Novakova',  'Editor',      'julia@pub.ch'),
 ('Karl Meier',      'Proofreader', 'karl@pub.ch');

-- BOOKS (10) — ISBN unique
INSERT INTO Books (Title, Genre, ISBN, PublishYear) VALUES
 ('Python для початківців', 'Навчальна',   '978-0-100000-001', 2023),
 ('SQL на практиці',        'Навчальна',   '978-0-100000-002', 2024),
 ('Data Analytics 101',     'Навчальна',   '978-0-100000-003', 2025),
 ('Story Craft',            'Fiction',     '978-0-100000-004', 2022),
 ('Mountains & Lakes',      'Travel',      '978-0-100000-005', 2021),
 ('AI for Editors',         'Technology',  '978-0-100000-006', 2025),
 ('Clean Data',             'Non-Fiction', '978-0-100000-007', 2020),
 ('Sci-Fi Tales',           'Sci-Fi',      '978-0-100000-008', 2019),
 ('Business Blue',          'Business',    '978-0-100000-009', 2024),
 ('Creative SQL',           'Technology',  '978-0-100000-010', 2023);

-- ORDERS (10) — Status ∈ {New, InProgress, Completed, Canceled}
INSERT INTO Orders (OrderDate, ClientName, Status) VALUES
 (DATE '2025-01-10', 'TechBooks GmbH', 'New'),
 (DATE '2025-01-15', 'EduLab SA',      'Completed'),
 (DATE '2025-02-01', 'DataWorks AG',   'InProgress'),
 (DATE '2025-02-18', 'Libra LLC',      'Completed'),
 (DATE '2025-03-03', 'Orion Labs',     'New'),
 (DATE '2025-03-20', 'Pixel Media',    'InProgress'),
 (DATE '2025-04-05', 'QuickLearn',     'Completed'),
 (DATE '2025-04-22', 'Read&Co',        'New'),
 (DATE '2025-05-09', 'Star Books',     'Completed'),
 (DATE '2025-05-25', 'Nova Print',     'Canceled');

COMMIT;

-- ===== Асоціативні таблиці (M:N) ===========================================
START TRANSACTION;

-- AUTHORBOOK (10) — звʼязок по Email + ISBN
INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='iryna.savchuk@ex.com' AND b.ISBN='978-0-100000-001';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='oleg.petrenko@ex.com' AND b.ISBN='978-0-100000-002';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='m.rossi@ex.com' AND b.ISBN='978-0-100000-003';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='jean.martin@ex.com' AND b.ISBN='978-0-100000-004';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='anna.mueller@ex.com' AND b.ISBN='978-0-100000-005';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='lukas.steiner@ex.com' AND b.ISBN='978-0-100000-006';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='sofia.garcia@ex.com' AND b.ISBN='978-0-100000-007';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='noah.johnson@ex.com' AND b.ISBN='978-0-100000-008';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='akira.tanaka@ex.com' AND b.ISBN='978-0-100000-009';

INSERT INTO AuthorBook (AuthorID, BookID, AuthorOrder)
SELECT a.AuthorID, b.BookID, 1
FROM Authors a JOIN Books b
WHERE a.Email='eva.novak@ex.com' AND b.ISBN='978-0-100000-010';

-- EMPLOYEEBOOK (10) — Task ∈ {Edit, Proofread, Translate, Design}
INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Edit'
FROM Employees e JOIN Books b
WHERE e.Email='alice@pub.ch' AND b.ISBN='978-0-100000-001';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Proofread'
FROM Employees e JOIN Books b
WHERE e.Email='bohdan@pub.ch' AND b.ISBN='978-0-100000-002';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Translate'
FROM Employees e JOIN Books b
WHERE e.Email='chloe@pub.ch' AND b.ISBN='978-0-100000-003';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Design'
FROM Employees e JOIN Books b
WHERE e.Email='dmytro@pub.ch' AND b.ISBN='978-0-100000-004';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Edit'
FROM Employees e JOIN Books b
WHERE e.Email='emma@pub.ch' AND b.ISBN='978-0-100000-005';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Proofread'
FROM Employees e JOIN Books b
WHERE e.Email='felix@pub.ch' AND b.ISBN='978-0-100000-006';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Translate'
FROM Employees e JOIN Books b
WHERE e.Email='hanna@pub.ch' AND b.ISBN='978-0-100000-007';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Design'
FROM Employees e JOIN Books b
WHERE e.Email='ivan@pub.ch' AND b.ISBN='978-0-100000-008';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Edit'
FROM Employees e JOIN Books b
WHERE e.Email='julia@pub.ch' AND b.ISBN='978-0-100000-009';

INSERT INTO EmployeeBook (EmployeeID, BookID, Task)
SELECT e.EmployeeID, b.BookID, 'Proofread'
FROM Employees e JOIN Books b
WHERE e.Email='karl@pub.ch' AND b.ISBN='978-0-100000-010';

COMMIT;

-- ===== CONTRACTS (10) — 5 авторам + 5 співробітникам ========================
START TRANSACTION;

-- 5 для авторів (тип Author)
INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT a.AuthorID, NULL, 'Author', DATE '2025-01-01', DATE '2025-12-31'
FROM Authors a WHERE a.Email='iryna.savchuk@ex.com';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT a.AuthorID, NULL, 'Author', DATE '2025-02-01', NULL
FROM Authors a WHERE a.Email='m.rossi@ex.com';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT a.AuthorID, NULL, 'Author', DATE '2025-03-01', NULL
FROM Authors a WHERE a.Email='anna.mueller@ex.com';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT a.AuthorID, NULL, 'Author', DATE '2025-03-15', DATE '2026-03-15'
FROM Authors a WHERE a.Email='akira.tanaka@ex.com';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT a.AuthorID, NULL, 'Author', DATE '2025-04-01', NULL
FROM Authors a WHERE a.Email='eva.novak@ex.com';

-- 5 для співробітників (тип Employee)
INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT NULL, e.EmployeeID, 'Employee', DATE '2025-01-10', NULL
FROM Employees e WHERE e.Email='alice@pub.ch';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT NULL, e.EmployeeID, 'Employee', DATE '2025-02-10', DATE '2025-12-31'
FROM Employees e WHERE e.Email='bohdan@pub.ch';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT NULL, e.EmployeeID, 'Employee', DATE '2025-03-05', NULL
FROM Employees e WHERE e.Email='chloe@pub.ch';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT NULL, e.EmployeeID, 'Employee', DATE '2025-03-20', NULL
FROM Employees e WHERE e.Email='emma@pub.ch';

INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate, EndDate)
SELECT NULL, e.EmployeeID, 'Employee', DATE '2025-04-15', NULL
FROM Employees e WHERE e.Email='karl@pub.ch';

COMMIT;

-- ===== ORDERITEM (10) — позиції у замовленнях ==============================
START TRANSACTION;

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 3, 49.90
FROM Orders o JOIN Books b
WHERE o.ClientName='TechBooks GmbH' AND o.OrderDate=DATE '2025-01-10'
  AND b.ISBN='978-0-100000-001';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 2, 59.00
FROM Orders o JOIN Books b
WHERE o.ClientName='EduLab SA' AND o.OrderDate=DATE '2025-01-15'
  AND b.ISBN='978-0-100000-002';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 1, 39.50
FROM Orders o JOIN Books b
WHERE o.ClientName='DataWorks AG' AND o.OrderDate=DATE '2025-02-01'
  AND b.ISBN='978-0-100000-003';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 5, 29.90
FROM Orders o JOIN Books b
WHERE o.ClientName='Libra LLC' AND o.OrderDate=DATE '2025-02-18'
  AND b.ISBN='978-0-100000-004';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 4, 54.00
FROM Orders o JOIN Books b
WHERE o.ClientName='Orion Labs' AND o.OrderDate=DATE '2025-03-03'
  AND b.ISBN='978-0-100000-005';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 3, 46.00
FROM Orders o JOIN Books b
WHERE o.ClientName='Pixel Media' AND o.OrderDate=DATE '2025-03-20'
  AND b.ISBN='978-0-100000-006';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 2, 32.00
FROM Orders o JOIN Books b
WHERE o.ClientName='QuickLearn' AND o.OrderDate=DATE '2025-04-05'
  AND b.ISBN='978-0-100000-007';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 6, 52.50
FROM Orders o JOIN Books b
WHERE o.ClientName='Read&Co' AND o.OrderDate=DATE '2025-04-22'
  AND b.ISBN='978-0-100000-008';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 2, 28.90
FROM Orders o JOIN Books b
WHERE o.ClientName='Star Books' AND o.OrderDate=DATE '2025-05-09'
  AND b.ISBN='978-0-100000-009';

INSERT INTO OrderItem (OrderID, BookID, Quantity, UnitPrice)
SELECT o.OrderID, b.BookID, 7, 44.00
FROM Orders o JOIN Books b
WHERE o.ClientName='Nova Print' AND o.OrderDate=DATE '2025-05-25'
  AND b.ISBN='978-0-100000-010';

COMMIT;

-- ===== Перевірка: очікуємо по 10 у кожній ==================================
SELECT 'Authors' AS tbl, COUNT(*) AS cnt FROM Authors
UNION ALL SELECT 'Employees',    COUNT(*) FROM Employees
UNION ALL SELECT 'Books',        COUNT(*) FROM Books
UNION ALL SELECT 'Orders',       COUNT(*) FROM Orders
UNION ALL SELECT 'AuthorBook',   COUNT(*) FROM AuthorBook
UNION ALL SELECT 'EmployeeBook', COUNT(*) FROM EmployeeBook
UNION ALL SELECT 'Contracts',    COUNT(*) FROM Contracts
UNION ALL SELECT 'OrderItem',    COUNT(*) FROM OrderItem;
