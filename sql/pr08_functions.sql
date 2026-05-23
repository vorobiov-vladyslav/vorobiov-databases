-- ============================================================================
-- ПР8. Додаткові вбудовані SQL-функції (MySQL 8+/MariaDB 10.2+)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано.
-- ============================================================================

USE publishing;

-- ===== Задача 1. Текстові (рядкові) функції ================================
-- 1.1 Повне ім'я автора у верхньому регістрі.
SELECT UPPER(Name) AS AuthorNameUpper
FROM Authors;

-- 1.2 Електронний підпис працівника: "Ім'я <email>".
SELECT CONCAT(Name, ' <', Email, '>') AS Signature
FROM Employees;

-- 1.3 Пошук співробітників, чий email містить домен 'pub.ch'.
SELECT Name, Email
FROM Employees
WHERE Email LIKE '%pub.ch%';

-- 1.4 Довжина назви книги.
SELECT Title, LENGTH(Title) AS TitleLength
FROM Books;

-- ===== Задача 2. Числові функції ===========================================
-- 2.1 Загальний дохід по кожному замовленню (округлено до копійок).
SELECT OrderID, ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue
FROM OrderItem
GROUP BY OrderID
ORDER BY OrderID;

-- 2.2 Середня ціна книги у продажах.
SELECT ROUND(AVG(UnitPrice), 2) AS AvgBookPrice
FROM OrderItem;

-- 2.3 Позиції замовлень з непарною кількістю (MOD).
SELECT OrderItemID, Quantity, MOD(Quantity, 2) AS IsOdd
FROM OrderItem
ORDER BY OrderItemID;

-- ===== Задача 3. Часові функції (дата/час) =================================
-- 3.1 Поточна дата сервера.
SELECT CURDATE() AS Today;

-- 3.2 Замовлення старші за 100 днів.
SELECT OrderID, OrderDate, DATEDIFF(CURDATE(), OrderDate) AS DaysAgo
FROM Orders
WHERE DATEDIFF(CURDATE(), OrderDate) > 100
ORDER BY OrderDate;

-- 3.3 Рік і місяць початку контракту.
SELECT ContractID,
       YEAR(StartDate)  AS YearStart,
       MONTH(StartDate) AS MonthStart
FROM Contracts
ORDER BY StartDate;

-- ===== Задача 4. Логічні та умовні функції =================================
-- 4.1 Статус контракту: Active / Closed.
SELECT ContractID,
       IF(EndDate IS NULL, 'Active', 'Closed') AS ContractStatus
FROM Contracts
ORDER BY ContractID;

-- 4.2 Категоризація книг за роком видання (CASE).
SELECT Title, PublishYear,
       CASE
         WHEN PublishYear >= 2025 THEN 'Нові видання'
         WHEN PublishYear BETWEEN 2020 AND 2024 THEN 'Сучасні'
         ELSE 'Архів'
       END AS Category
FROM Books
ORDER BY PublishYear DESC;

-- ===== Задача 5. Службові функції ==========================================
-- 5.1 Заміна NULL у Phone авторів.
SELECT Name, IFNULL(Phone, '— не вказано —') AS PhoneDisplay
FROM Authors;

-- 5.2 Перевірка коректності email-у співробітників.
SELECT Name, Email,
       IF(Email LIKE '%@%', 'Valid email', 'Invalid email') AS CheckEmail
FROM Employees;
