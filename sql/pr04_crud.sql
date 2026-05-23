-- ============================================================================
-- ПР4. CRUD: приклади INSERT/UPDATE/DELETE/SELECT
-- (вимога ПР4 п.3: типові DML-операції)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано.
-- ============================================================================

USE publishing;

-- ===== INSERT — додавання нового автора =====================================
INSERT INTO Authors (Name, Email, Country)
VALUES ('Newcomer Author', 'newcomer@ex.com', 'Poland');

SELECT * FROM Authors WHERE Email = 'newcomer@ex.com';

-- ===== UPDATE — змінити статус замовлення ===================================
UPDATE Orders SET Status = 'Completed' WHERE ClientName = 'TechBooks GmbH';
SELECT OrderID, ClientName, Status FROM Orders WHERE ClientName = 'TechBooks GmbH';

-- UPDATE з умовою по даті: всі "New" замовлення до 1 лютого → "InProgress"
UPDATE Orders SET Status = 'InProgress'
WHERE Status = 'New' AND OrderDate < DATE '2025-02-01';
SELECT OrderID, OrderDate, ClientName, Status FROM Orders ORDER BY OrderDate;

-- ===== DELETE — видалити щойно доданого автора ==============================
DELETE FROM Authors WHERE Email = 'newcomer@ex.com';
SELECT COUNT(*) AS authors_after_delete FROM Authors;

-- DELETE з підзапитом: видалити позиції з ціною нижче 30
DELETE FROM OrderItem WHERE UnitPrice < 30;
SELECT OrderItemID, OrderID, BookID, UnitPrice FROM OrderItem ORDER BY UnitPrice;

-- ===== SELECT — базова вибірка з фільтром, сортуванням ======================
SELECT Title, Genre, PublishYear
FROM Books
WHERE PublishYear >= 2023
ORDER BY PublishYear DESC, Title ASC;
