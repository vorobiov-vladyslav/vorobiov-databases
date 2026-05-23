#!/usr/bin/env python3
"""Fill ПР3 tables (Entities/Attributes/Relationships) in zoshyt docx XML."""
from lxml import etree
import sys

NS = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
}
W = '{%s}' % NS['w']

ENTITIES = [
    ("Authors",      "Автори книг",                       "Зберігає особисті дані авторів"),
    ("Books",        "Каталог книг видавництва",          "Кожна книга має унікальний ISBN"),
    ("Employees",    "Співробітники видавництва",         "Edit / Proofread / Translate / Design (ENUM Role)"),
    ("Orders",       "Замовлення клієнтів",               "Статус: New / InProgress / Completed / Canceled"),
    ("OrderItem",    "Позиції замовлення",                "Quantity + UnitPrice; одне замовлення має N позицій"),
    ("Contracts",    "Контракти з авторами/співробітниками", "Належить АБО автору АБО співробітнику (XOR)"),
    ("AuthorBook",   "Зв'язок автор ↔ книга (M:N)",       "Асоціативна сутність; зберігає AuthorOrder"),
    ("EmployeeBook", "Зв'язок співробітник ↔ книга (M:N)", "Асоціативна сутність; зберігає Task (роль)"),
]

ATTRIBUTES = [
    # (сутність, атрибут, тип, PK, FK, правила)
    ("Authors",      "AuthorID",     "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("Authors",      "Name",         "VARCHAR(200)",       "",  "",                              "NOT NULL"),
    ("Authors",      "Email",        "VARCHAR(255)",       "",  "",                              "UNIQUE"),
    ("Authors",      "Phone",        "VARCHAR(50)",        "",  "",                              ""),
    ("Authors",      "Country",      "VARCHAR(100)",       "",  "",                              ""),
    ("Books",        "BookID",       "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("Books",        "Title",        "VARCHAR(300)",       "",  "",                              "NOT NULL"),
    ("Books",        "Genre",        "VARCHAR(100)",       "",  "",                              ""),
    ("Books",        "ISBN",         "VARCHAR(32)",        "",  "",                              "NOT NULL, UNIQUE"),
    ("Books",        "PublishYear",  "YEAR",               "",  "",                              ""),
    ("Employees",    "EmployeeID",   "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("Employees",    "Name",         "VARCHAR(200)",       "",  "",                              "NOT NULL"),
    ("Employees",    "Role",         "ENUM(...)",          "",  "",                              "NOT NULL"),
    ("Employees",    "Email",        "VARCHAR(255)",       "",  "",                              "UNIQUE"),
    ("Orders",       "OrderID",      "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("Orders",       "OrderDate",    "DATE",               "",  "",                              "NOT NULL"),
    ("Orders",       "ClientName",   "VARCHAR(200)",       "",  "",                              "NOT NULL"),
    ("Orders",       "Status",       "ENUM(...)",          "",  "",                              "NOT NULL DEFAULT 'New'"),
    ("OrderItem",    "OrderItemID",  "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("OrderItem",    "OrderID",      "INT",                "",  "→ Orders.OrderID",              "NOT NULL"),
    ("OrderItem",    "BookID",       "INT",                "",  "→ Books.BookID",                "NOT NULL"),
    ("OrderItem",    "Quantity",     "INT",                "",  "",                              "NOT NULL, CHECK ≥ 1"),
    ("OrderItem",    "UnitPrice",    "DECIMAL(10,2)",      "",  "",                              "NOT NULL, CHECK ≥ 0"),
    ("Contracts",    "ContractID",   "INT AUTO_INCREMENT", "✅", "",                              "NOT NULL"),
    ("Contracts",    "AuthorID",     "INT",                "",  "→ Authors.AuthorID",            "NULL (XOR з EmployeeID)"),
    ("Contracts",    "EmployeeID",   "INT",                "",  "→ Employees.EmployeeID",        "NULL (XOR з AuthorID)"),
    ("Contracts",    "ContractType", "ENUM('Author','Employee')", "", "",                        "NOT NULL"),
    ("Contracts",    "StartDate",    "DATE",               "",  "",                              "NOT NULL"),
    ("Contracts",    "EndDate",      "DATE",               "",  "",                              "NULL, CHECK ≥ StartDate"),
    ("AuthorBook",   "AuthorID",     "INT",                "✅", "→ Authors.AuthorID",            "NOT NULL"),
    ("AuthorBook",   "BookID",       "INT",                "✅", "→ Books.BookID",                "NOT NULL"),
    ("AuthorBook",   "AuthorOrder",  "INT",                "",  "",                              "NULL"),
    ("EmployeeBook", "EmployeeID",   "INT",                "✅", "→ Employees.EmployeeID",        "NOT NULL"),
    ("EmployeeBook", "BookID",       "INT",                "✅", "→ Books.BookID",                "NOT NULL"),
    ("EmployeeBook", "Task",         "ENUM(...)",          "",  "",                              "NOT NULL"),
]

RELATIONSHIPS = [
    # (Від, До, Тип, Назва, Чи асоціативна, Коментар)
    ("Authors",   "Books",      "M:N", "пише",            "Так — AuthorBook",   "Зберігає порядок авторів (AuthorOrder)"),
    ("Employees", "Books",      "M:N", "працює над",      "Так — EmployeeBook", "Task = Edit / Proofread / Translate / Design"),
    ("Books",     "Orders",     "M:N", "входить у",       "Так — OrderItem",    "З атрибутами Quantity, UnitPrice"),
    ("Authors",   "Contracts",  "1:M", "має контракт",    "Ні (FK)",            "Контракт може належати автору АБО співробітнику"),
    ("Employees", "Contracts",  "1:M", "має контракт",    "Ні (FK)",            "Контракт може належати автору АБО співробітнику"),
    ("Orders",    "OrderItem",  "1:M", "складається з",   "Ні (FK)",            "ON DELETE CASCADE — видалення замовлення стирає позиції"),
    ("Books",     "OrderItem",  "1:M", "є в позиції",     "Ні (FK)",            "ON DELETE RESTRICT — не можна видалити книгу із замовлення"),
]


def find_table_by_anchor(root, anchor_text):
    """Знайти w:tbl, що містить вказаний текст у першому рядку."""
    for tbl in root.iter(f'{W}tbl'):
        for t in tbl.iter(f'{W}t'):
            if t.text and anchor_text in t.text:
                return tbl
    return None


def fill_cell(cell, text):
    """Замінити вміст комірки на параграф з текстом (Times New Roman 12pt)."""
    # Видалити старі параграфи
    for p in cell.findall(f'{W}p'):
        cell.remove(p)
    # Додати новий параграф з текстом
    p = etree.SubElement(cell, f'{W}p')
    pPr = etree.SubElement(p, f'{W}pPr')
    spacing = etree.SubElement(pPr, f'{W}spacing')
    spacing.set(f'{W}line', '240')
    spacing.set(f'{W}lineRule', 'auto')
    r = etree.SubElement(p, f'{W}r')
    rPr = etree.SubElement(r, f'{W}rPr')
    rFonts = etree.SubElement(rPr, f'{W}rFonts')
    for attr in ('ascii', 'cs', 'eastAsia', 'hAnsi'):
        rFonts.set(f'{W}{attr}', 'Times New Roman')
    sz = etree.SubElement(rPr, f'{W}sz'); sz.set(f'{W}val', '22')
    szCs = etree.SubElement(rPr, f'{W}szCs'); szCs.set(f'{W}val', '22')
    rtl = etree.SubElement(rPr, f'{W}rtl'); rtl.set(f'{W}val', '0')
    t = etree.SubElement(r, f'{W}t')
    t.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
    t.text = text


def fill_table(tbl, data, name=""):
    """Заповнити таблицю даними. data = список кортежів. Перший рядок — заголовок (не чіпаємо).
    Якщо порожніх рядків недостатньо, клонуємо останній і вставляємо."""
    from copy import deepcopy
    rows = tbl.findall(f'{W}tr')
    header_row = rows[0]
    empty_rows = rows[1:]
    n_cols = len(header_row.findall(f'{W}tc'))
    template = deepcopy(empty_rows[-1]) if empty_rows else None
    # Якщо рядків замало — клонуємо
    while len(empty_rows) < len(data):
        new_row = deepcopy(template)
        # Очистити w14:paraId, щоб не дублювалось
        for p in new_row.iter(f'{W}p'):
            for attr in list(p.attrib):
                if 'paraId' in attr or 'textId' in attr:
                    del p.attrib[attr]
        tbl.append(new_row)
        empty_rows.append(new_row)
    print(f"  Table '{name}': header + {len(empty_rows)} rows (after expand), {n_cols} cols, {len(data)} data rows to fill")
    for row_idx, row_data in enumerate(data):
        cells = empty_rows[row_idx].findall(f'{W}tc')
        for col_idx, value in enumerate(row_data):
            if col_idx >= len(cells):
                break
            fill_cell(cells[col_idx], value)


def main():
    path = '/home/vlad/learning/university/databases/notebook/unpacked/word/document.xml'
    parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False)
    tree = etree.parse(path, parser)
    root = tree.getroot()

    print("Filling Entities table...")
    tbl = find_table_by_anchor(root, "Сутність (Entity)")
    fill_table(tbl, ENTITIES, "Entities")

    print("Filling Attributes table...")
    # Атрибути таблиці має заголовок "Атрибут" — знайду таблицю з ним
    tbl = find_table_by_anchor(root, "Атрибут")
    fill_table(tbl, ATTRIBUTES, "Attributes")

    print("Filling Relationships table...")
    tbl = find_table_by_anchor(root, "Від (Entity A)")
    fill_table(tbl, RELATIONSHIPS, "Relationships")

    tree.write(path, xml_declaration=True, encoding='UTF-8', standalone=True)
    print(f"\n✅ Saved {path}")


if __name__ == '__main__':
    main()
