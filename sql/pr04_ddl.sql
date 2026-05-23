-- ============================================================================
-- ПР4. DDL: створення схеми publishing (видавнича компанія)
-- Курс: GoIT «Бази даних», ІПЗ 4 семестр
-- Цей файл є основою для ПР3 (EER діаграма через Reverse Engineer) та ПР4 (DDL/DML).
-- Сумісно з MySQL 8.0+ та MariaDB 10.2+ (всі CHECK у MariaDB enforced з 10.2).
-- ============================================================================

DROP DATABASE IF EXISTS publishing;
CREATE DATABASE publishing
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE publishing;

-- ===== Базові таблиці =======================================================

CREATE TABLE Authors (
  AuthorID  INT AUTO_INCREMENT PRIMARY KEY,
  Name      VARCHAR(200) NOT NULL,
  Email     VARCHAR(255) UNIQUE,
  Phone     VARCHAR(50),
  Country   VARCHAR(100)
) ENGINE=InnoDB COMMENT='Автори книжок';

CREATE TABLE Employees (
  EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
  Name       VARCHAR(200) NOT NULL,
  Role       ENUM('Editor','Proofreader','Translator','Designer') NOT NULL,
  Email      VARCHAR(255) UNIQUE
) ENGINE=InnoDB COMMENT='Співробітники видавництва';

CREATE TABLE Books (
  BookID      INT AUTO_INCREMENT PRIMARY KEY,
  Title       VARCHAR(300) NOT NULL,
  Genre       VARCHAR(100),
  ISBN        VARCHAR(32) NOT NULL,
  PublishYear YEAR,
  CONSTRAINT uq_books_isbn UNIQUE (ISBN)
) ENGINE=InnoDB COMMENT='Книги';

CREATE TABLE Orders (
  OrderID    INT AUTO_INCREMENT PRIMARY KEY,
  OrderDate  DATE NOT NULL,
  ClientName VARCHAR(200) NOT NULL,
  Status     ENUM('New','InProgress','Completed','Canceled') NOT NULL DEFAULT 'New'
) ENGINE=InnoDB COMMENT='Замовлення клієнтів';

-- Контракт належить АВТОРУ або СПІВРОБІТНИКУ (рівно одне). Ексклюзивність
-- забезпечується тригером у ПР6; тут — CHECK + FK.
CREATE TABLE Contracts (
  ContractID   INT AUTO_INCREMENT PRIMARY KEY,
  AuthorID     INT NULL,
  EmployeeID   INT NULL,
  ContractType ENUM('Author','Employee') NOT NULL,
  StartDate    DATE NOT NULL,
  EndDate      DATE NULL,
  CONSTRAINT fk_contract_author   FOREIGN KEY (AuthorID)   REFERENCES Authors(AuthorID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_contract_employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_contract_dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
  -- Ексклюзивність власника (Author XOR Employee) реалізована тригером у ПР6.
  INDEX ix_contract_author   (AuthorID),
  INDEX ix_contract_employee (EmployeeID)
) ENGINE=InnoDB COMMENT='Контракти з авторами/співробітниками';

-- ===== Асоціативні (M:N) таблиці ============================================

CREATE TABLE AuthorBook (
  AuthorID    INT NOT NULL,
  BookID      INT NOT NULL,
  AuthorOrder INT NULL,
  PRIMARY KEY (AuthorID, BookID),
  CONSTRAINT fk_ab_author FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ab_book   FOREIGN KEY (BookID)   REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Зв''язок автор ↔ книга (M:N)';

CREATE TABLE EmployeeBook (
  EmployeeID INT NOT NULL,
  BookID     INT NOT NULL,
  Task       ENUM('Edit','Proofread','Translate','Design') NOT NULL,
  PRIMARY KEY (EmployeeID, BookID),
  CONSTRAINT fk_eb_employee FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_eb_book     FOREIGN KEY (BookID)    REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Зв''язок співробітник ↔ книга (M:N)';

CREATE TABLE OrderItem (
  OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
  OrderID     INT NOT NULL,
  BookID      INT NOT NULL,
  Quantity    INT NOT NULL,
  UnitPrice   DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_oi_order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_book  FOREIGN KEY (BookID)  REFERENCES Books(BookID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_oi_qty   CHECK (Quantity  >= 1),
  CONSTRAINT chk_oi_price CHECK (UnitPrice >= 0),
  INDEX ix_oi_order (OrderID),
  INDEX ix_oi_book  (BookID)
) ENGINE=InnoDB COMMENT='Позиції замовлень';

-- ===== Швидка перевірка =====================================================
-- SELECT table_name, table_comment FROM information_schema.tables WHERE table_schema='publishing';
