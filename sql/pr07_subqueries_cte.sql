-- ============================================================================
-- ПР7. Підзапити, CTE, VIEW (MySQL 8+/MariaDB 10.2+)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано.
-- ============================================================================

USE publishing;

-- ===== Задача 1. Підзапит — автори, чиї книги не замовляли =================
-- Очікувано: 2 автори (без жодного OrderItem на їхніх книгах).
SELECT a.AuthorID, a.Name
FROM Authors a
WHERE NOT EXISTS (
    SELECT 1
    FROM AuthorBook ab
    JOIN OrderItem oi ON oi.BookID = ab.BookID
    WHERE ab.AuthorID = a.AuthorID
);

-- ===== Задача 2. Книги з продажами вище середнього =========================
-- Порівнюємо виручку кожної книги із середньою сумою по позиції OrderItem.
SELECT b.Title, SUM(oi.Quantity * oi.UnitPrice) AS Revenue
FROM OrderItem oi
JOIN Books b ON b.BookID = oi.BookID
GROUP BY b.Title
HAVING Revenue > (
    SELECT AVG(Quantity * UnitPrice) FROM OrderItem
)
ORDER BY Revenue DESC;

-- ===== Задача 3. Рейтинг книг у межах жанру (CTE + RANK) ===================
-- Найприбутковіша книга в кожному жанрі отримує GenreRank=1.
WITH sales AS (
    SELECT b.Title, b.Genre,
           SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM Books b
    JOIN OrderItem oi ON oi.BookID = b.BookID
    GROUP BY b.Title, b.Genre
)
SELECT Title, Genre, Revenue,
       RANK() OVER (PARTITION BY Genre ORDER BY Revenue DESC) AS GenreRank
FROM sales
ORDER BY Genre, GenreRank;

-- ===== Задача 4. VIEW для повторного використання ==========================
-- Створюємо подання з продажами по книгах.
CREATE OR REPLACE VIEW v_book_sales AS
SELECT b.BookID, b.Title,
       COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0) AS Revenue
FROM Books b
LEFT JOIN OrderItem oi ON oi.BookID = b.BookID
GROUP BY b.BookID, b.Title;

-- Використання VIEW.
SELECT * FROM v_book_sales ORDER BY Revenue DESC;
