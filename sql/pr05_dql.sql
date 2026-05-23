-- ============================================================================
-- ПР5. DQL: 19 задач — від простих SELECT до віконних функцій (MySQL 8+/MariaDB 10.2+)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано (БД publishing наповнена).
-- ============================================================================

USE publishing;

-- ===== Задача 1. Прості вибірки =============================================
SELECT * FROM Authors;
SELECT Name, Country FROM Authors WHERE Country = 'Ukraine';
SELECT Title, Genre, PublishYear FROM Books ORDER BY PublishYear DESC;

-- ===== Задача 2. Зв'язки між таблицями (JOIN) ==============================
SELECT a.Name AS Author, b.Title AS Book
FROM Authors a
JOIN AuthorBook ab ON a.AuthorID = ab.AuthorID
JOIN Books b ON b.BookID = ab.BookID;

-- ===== Задача 3. Фільтрація і сортування ====================================
SELECT Title, Genre, PublishYear
FROM Books
WHERE Genre = 'Technology'
ORDER BY PublishYear DESC;

-- ===== Задача 4. Агрегація і групування =====================================
SELECT b.Genre, COUNT(*) AS BooksCount
FROM Books b
GROUP BY b.Genre
ORDER BY BooksCount DESC;

-- ===== Задача 5. HAVING (фільтр по агрегату) ================================
SELECT b.Title, SUM(oi.Quantity * oi.UnitPrice) AS Revenue
FROM OrderItem oi
JOIN Books b ON b.BookID = oi.BookID
GROUP BY b.Title
HAVING Revenue > 100
ORDER BY Revenue DESC;

-- ===== Задача 6. Вкладені запити (IN) =======================================
SELECT b.Title
FROM Books b
WHERE b.BookID IN (
    SELECT BookID
    FROM OrderItem
);

-- ===== Задача 7. EXISTS — автори, чиї книги замовляли =======================
SELECT a.Name
FROM Authors a
WHERE EXISTS (
    SELECT 1
    FROM AuthorBook ab
    JOIN OrderItem oi ON oi.BookID = ab.BookID
    WHERE ab.AuthorID = a.AuthorID
);

-- ===== Задача 8. Аналітичні (віконні) функції — RANK у межах жанру ==========
WITH sales AS (
    SELECT b.Title, b.Genre,
           SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM OrderItem oi
    JOIN Books b ON b.BookID = oi.BookID
    GROUP BY b.Title, b.Genre
)
SELECT *,
       RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) AS GenreRank
FROM sales;

-- ===== Задача 9. Базові вибірки — все з трьох таблиць =======================
-- всі співробітники
SELECT EmployeeID, Name, Role, Email
FROM Employees;

-- всі автори
SELECT AuthorID, Name, Email, Country
FROM Authors;

-- всі книги
SELECT BookID, Title, Genre, ISBN, PublishYear
FROM Books;

-- ===== Задача 10. Фільтрація + сортування ===================================
-- книги певного жанру, від новіших до старіших
SELECT Title, Genre, PublishYear
FROM Books
WHERE Genre = 'Technology'
ORDER BY PublishYear DESC;

-- автори з конкретної країни
SELECT Name, Email
FROM Authors
WHERE Country = 'Ukraine'
ORDER BY Name;

-- ===== Задача 11. JOIN: автори ↔ книги — головний автор кожної ==============
SELECT b.BookID, b.Title, a.AuthorID, a.Name AS Author
FROM AuthorBook ab
JOIN Authors a ON a.AuthorID = ab.AuthorID
JOIN Books   b ON b.BookID   = ab.BookID
WHERE ab.AuthorOrder = 1
ORDER BY b.Title;

-- ===== Задача 12. JOIN: співробітники ↔ книги — Task ========================
SELECT e.Name  AS Employee,
       b.Title AS Book,
       eb.Task
FROM EmployeeBook eb
JOIN Employees e ON e.EmployeeID = eb.EmployeeID
JOIN Books     b ON b.BookID     = eb.BookID
ORDER BY e.Name, b.Title;

-- ===== Задача 13. Замовлення: деталізація + підсумок =======================
-- 13.1 позиції замовлень
SELECT o.OrderID, o.OrderDate, o.ClientName,
       b.Title,
       oi.Quantity, oi.UnitPrice,
       (oi.Quantity * oi.UnitPrice) AS LineTotal
FROM Orders o
JOIN OrderItem oi ON oi.OrderID = o.OrderID
JOIN Books b      ON b.BookID   = oi.BookID
ORDER BY o.OrderDate DESC, o.OrderID;

-- 13.2 підсумок по замовленню
SELECT o.OrderID, o.OrderDate, o.ClientName,
       SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
FROM Orders o
JOIN OrderItem oi ON oi.OrderID = o.OrderID
GROUP BY o.OrderID, o.OrderDate, o.ClientName
ORDER BY o.OrderDate DESC;

-- ===== Задача 14. Агрегації та рейтинги =====================================
-- 14.1 топ-автори за кількістю книжок
SELECT a.AuthorID, a.Name, COUNT(*) AS BooksCount
FROM AuthorBook ab
JOIN Authors a ON a.AuthorID = ab.AuthorID
GROUP BY a.AuthorID, a.Name
ORDER BY BooksCount DESC, a.Name;

-- 14.2 продажі за книжками (кількість і сума)
SELECT b.BookID, b.Title,
       SUM(oi.Quantity)                AS QtySold,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue
FROM OrderItem oi
JOIN Books b ON b.BookID = oi.BookID
GROUP BY b.BookID, b.Title
ORDER BY Revenue DESC;

-- ===== Задача 15. HAVING — книги з виручкою > 300 ===========================
SELECT b.Title,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue
FROM OrderItem oi
JOIN Books b ON b.BookID = oi.BookID
GROUP BY b.Title
HAVING Revenue > 300
ORDER BY Revenue DESC;

-- ===== Задача 16. NOT EXISTS — автори без замовлень =========================
SELECT a.AuthorID, a.Name
FROM Authors a
WHERE NOT EXISTS (
  SELECT 1
  FROM AuthorBook ab
  JOIN OrderItem oi ON oi.BookID = ab.BookID
  WHERE ab.AuthorID = a.AuthorID
);

-- ===== Задача 17. Дати + статуси (BETWEEN + IN) ============================
SELECT OrderID, OrderDate, ClientName, Status
FROM Orders
WHERE OrderDate BETWEEN DATE '2025-05-01' AND DATE '2025-05-31'
  AND Status IN ('New','Completed')
ORDER BY OrderDate DESC;

-- ===== Задача 18. LEFT JOIN — контракти авторів і співробітників ===========
SELECT
    c.ContractID,
    a.Name      AS Author,
    e.Name      AS Employee,
    c.ContractType,
    c.StartDate,
    c.EndDate
FROM Contracts c
LEFT JOIN Authors   a ON a.AuthorID   = c.AuthorID
LEFT JOIN Employees e ON e.EmployeeID = c.EmployeeID
ORDER BY c.StartDate DESC, c.ContractID;

-- ===== Задача 19. Віконна функція DENSE_RANK у межах жанру ==================
WITH sales AS (
  SELECT b.BookID, b.Title, b.Genre,
         SUM(oi.Quantity * oi.UnitPrice) AS Revenue
  FROM OrderItem oi
  JOIN Books b ON b.BookID = oi.BookID
  GROUP BY b.BookID, b.Title, b.Genre
)
SELECT *,
       DENSE_RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) AS GenreRank
FROM sales
ORDER BY Genre, GenreRank;
