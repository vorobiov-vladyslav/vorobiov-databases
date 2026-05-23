-- ============================================================================
-- ПР4. JOIN-запити (вимога п.4: побудувати запити з JOIN)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано.
-- ============================================================================

USE publishing;

-- ===== 1. INNER JOIN: автори ↔ їх книги =====================================
SELECT a.Name AS Author, b.Title AS Book, b.PublishYear
FROM Authors a
INNER JOIN AuthorBook ab ON a.AuthorID = ab.AuthorID
INNER JOIN Books b       ON ab.BookID  = b.BookID
ORDER BY a.Name;

-- ===== 2. LEFT JOIN: усі автори + їх контракти (включно з тими, у кого нема) =
SELECT a.Name, c.ContractType, c.StartDate, c.EndDate
FROM Authors a
LEFT JOIN Contracts c ON a.AuthorID = c.AuthorID
ORDER BY a.Name;

-- ===== 3. JOIN з агрегацією: скільки книг працював кожен співробітник =======
SELECT e.Name AS Employee, e.Role, COUNT(eb.BookID) AS books_count
FROM Employees e
LEFT JOIN EmployeeBook eb ON e.EmployeeID = eb.EmployeeID
GROUP BY e.EmployeeID, e.Name, e.Role
ORDER BY books_count DESC;

-- ===== 4. JOIN 4 таблиці: замовлення → позиції → книги → автори =============
SELECT o.OrderID, o.ClientName, b.Title, a.Name AS Author,
       oi.Quantity, oi.UnitPrice,
       (oi.Quantity * oi.UnitPrice) AS LineTotal
FROM Orders o
JOIN OrderItem oi ON o.OrderID = oi.OrderID
JOIN Books b      ON oi.BookID = b.BookID
LEFT JOIN AuthorBook ab ON b.BookID = ab.BookID
LEFT JOIN Authors a     ON ab.AuthorID = a.AuthorID
ORDER BY o.OrderID;

-- ===== 5. Сума по кожному замовленню =======================================
SELECT o.OrderID, o.ClientName, o.OrderDate, o.Status,
       SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
FROM Orders o
LEFT JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY o.OrderID, o.ClientName, o.OrderDate, o.Status
ORDER BY OrderTotal DESC;
