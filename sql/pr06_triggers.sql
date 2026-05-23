-- ============================================================================
-- ПР6. Тригери: бізнес-правила таблиці Contracts (MySQL 8+/MariaDB 10.2+)
-- Передумова: pr04_ddl.sql + pr04_dml.sql виконано.
-- ============================================================================

USE publishing;

-- ===== Задача 1. Створення тригерів (BI + BU) ==============================
-- Ідемпотентно — спочатку видаляємо, якщо вже існують.
DROP TRIGGER IF EXISTS trg_contracts_bi;
DROP TRIGGER IF EXISTS trg_contracts_bu;

DELIMITER $$

CREATE TRIGGER trg_contracts_bi
BEFORE INSERT ON Contracts
FOR EACH ROW
BEGIN
  -- Рівно один із AuthorID/EmployeeID має бути NOT NULL (XOR).
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
     OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  -- ContractType має відповідати встановленому FK.
  IF (NEW.AuthorID IS NOT NULL AND NEW.ContractType <> 'Author')
     OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  -- EndDate (якщо задана) >= StartDate.
  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;
END$$

CREATE TRIGGER trg_contracts_bu
BEFORE UPDATE ON Contracts
FOR EACH ROW
BEGIN
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
     OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  IF (NEW.AuthorID IS NOT NULL AND NEW.ContractType <> 'Author')
     OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;
END$$

DELIMITER ;

-- Переглянути, що тригери створено.
SHOW TRIGGERS LIKE 'Contracts';

-- ===== Задача 2. Тільки BEFORE INSERT (детальний приклад з шаблону) ========
-- Альтернативна версія Task 1 — лише BI, з докладними коментарями.
-- (Якщо вже створено в Task 1, цей блок безпечно перезаписує його через DROP).
DROP TRIGGER IF EXISTS trg_contracts_bi;

DELIMITER $$

CREATE TRIGGER trg_contracts_bi
BEFORE INSERT ON Contracts
FOR EACH ROW
BEGIN
  -- 1) Власник — рівно один.
  IF (NEW.AuthorID IS NULL AND NEW.EmployeeID IS NULL)
     OR (NEW.AuthorID IS NOT NULL AND NEW.EmployeeID IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Exactly one of AuthorID or EmployeeID must be set';
  END IF;

  -- 2) ContractType ↔ FK.
  IF (NEW.AuthorID IS NOT NULL AND NEW.ContractType <> 'Author')
     OR (NEW.EmployeeID IS NOT NULL AND NEW.ContractType <> 'Employee') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ContractType must match owner (Author/Employee)';
  END IF;

  -- 3) Послідовність дат.
  IF NEW.EndDate IS NOT NULL AND NEW.EndDate < NEW.StartDate THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'EndDate must be >= StartDate';
  END IF;
END$$

DELIMITER ;

SHOW CREATE TRIGGER trg_contracts_bi;

-- ===== Задача 3. Перевірка роботи тригерів =================================
-- 3.1 Коректна вставка — має пройти.
INSERT INTO Contracts (AuthorID, ContractType, StartDate, EndDate)
VALUES (1, 'Author', DATE '2025-06-01', DATE '2025-12-31');

-- 3.2 Помилка 1: два власники (AuthorID + EmployeeID).
-- Очікується: Error 1644 'Exactly one of AuthorID or EmployeeID must be set'.
INSERT INTO Contracts (AuthorID, EmployeeID, ContractType, StartDate)
VALUES (1, 1, 'Author', DATE '2025-06-01');

-- 3.3 Помилка 2: ContractType не відповідає власнику.
-- Очікується: 'ContractType must match owner (Author/Employee)'.
INSERT INTO Contracts (AuthorID, ContractType, StartDate)
VALUES (1, 'Employee', DATE '2025-06-01');

-- 3.4 Помилка 3: EndDate < StartDate.
-- Очікується: 'EndDate must be >= StartDate'.
INSERT INTO Contracts (AuthorID, ContractType, StartDate, EndDate)
VALUES (1, 'Author', DATE '2025-12-01', DATE '2025-01-01');

-- ===== Задача 4. Аналітична перевірка ======================================
-- Усі контракти, відсортовано за StartDate (новіші зверху).
SELECT ContractID, ContractType, StartDate, EndDate
FROM Contracts
ORDER BY StartDate DESC;
