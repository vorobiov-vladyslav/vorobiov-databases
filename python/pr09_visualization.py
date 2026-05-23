"""ПР9. Обробка та візуалізація даних засобами Python.

5 задач:
1. Імпорт таблиць у pandas
2. Об'єднання таблиць (merge) і збереження у CSV
3. Bar chart — дохід по книгах
4. Line chart — динаміка продажів за датами
5. KPI (ключові показники) + графік

Запуск:
    cd python/
    python pr09_visualization.py

Передумови:
    pip install pandas sqlalchemy pymysql matplotlib
    БД publishing наповнена (pr04_ddl.sql + pr04_dml.sql).
"""

from pathlib import Path
from sqlalchemy import create_engine, text
import pandas as pd
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# Налаштування
# ---------------------------------------------------------------------------
# MariaDB локально: користувач vlad, пароль vlad, БД publishing.
ENGINE_URL = "mysql+pymysql://vlad:vlad@localhost:3306/publishing?charset=utf8mb4"

BASE = Path(__file__).parent
DATA_RAW = BASE / "data" / "raw"
DATA_OUT = BASE / "data" / "processed"
FIGS = BASE / "figs"
for d in (DATA_RAW, DATA_OUT, FIGS):
    d.mkdir(parents=True, exist_ok=True)

engine = create_engine(ENGINE_URL)

# Перевірка підключення.
with engine.connect() as conn:
    now = conn.execute(text("SELECT NOW()")).scalar()
    print(f"OK: підключено до publishing, час сервера = {now}")


# ===========================================================================
# Задача 1. Імпорт таблиць у pandas
# ===========================================================================
print("\n===== Задача 1. Імпорт таблиць у pandas =====")
books     = pd.read_sql("SELECT * FROM Books",     engine)
orders    = pd.read_sql("SELECT * FROM Orders",    engine)
orderitem = pd.read_sql("SELECT * FROM OrderItem", engine)

print(f"Книги:             {books.shape}")
print(f"Замовлення:        {orders.shape}")
print(f"Позиції замовлень: {orderitem.shape}")

# Зберегти сирі дані (Задача 1 артефакт).
books.to_csv(DATA_RAW / "books.csv", index=False, encoding="utf-8")
orders.to_csv(DATA_RAW / "orders.csv", index=False, encoding="utf-8")
orderitem.to_csv(DATA_RAW / "orderitem.csv", index=False, encoding="utf-8")


# ===========================================================================
# Задача 2. Об'єднання таблиць та збереження у CSV
# ===========================================================================
print("\n===== Задача 2. Merge у єдину аналітичну таблицю =====")
df = (
    orderitem
    .merge(orders, on="OrderID", how="left")
    .merge(books,  on="BookID",  how="left")
)
df["Revenue"]   = df["Quantity"] * df["UnitPrice"]
df["OrderDate"] = pd.to_datetime(df["OrderDate"])

print(df.head())

csv_out = DATA_OUT / "sales_data.csv"
df.to_csv(csv_out, index=False, encoding="utf-8")
print(f"Файл збережено: {csv_out}")


# ===========================================================================
# Задача 3. Простий графік: дохід по книгах (bar chart)
# ===========================================================================
print("\n===== Задача 3. Bar chart — дохід по книгах =====")
top_books = (
    df.groupby("Title")["Revenue"]
      .sum()
      .sort_values(ascending=False)
      .reset_index()
)
print(top_books)

plt.figure(figsize=(10, 6))
plt.bar(top_books["Title"], top_books["Revenue"], color="skyblue")
plt.title("Дохід по книгах", fontsize=14)
plt.xlabel("Назва книги")
plt.ylabel("Дохід (CHF)")
plt.xticks(rotation=30, ha="right")
plt.tight_layout()
fig_bar = FIGS / "revenue_by_book.png"
plt.savefig(fig_bar, dpi=150)
print(f"Графік збережено: {fig_bar}")
plt.close()


# ===========================================================================
# Задача 4. Динаміка продажів за датами (line chart)
# ===========================================================================
print("\n===== Задача 4. Line chart — динаміка продажів =====")
sales_by_date = (
    df.groupby("OrderDate")["Revenue"]
      .sum()
      .reset_index()
      .sort_values("OrderDate")
)
print(sales_by_date)

plt.figure(figsize=(10, 5))
plt.plot(sales_by_date["OrderDate"], sales_by_date["Revenue"],
         marker="o", color="teal", linewidth=2)
plt.title("Динаміка продажів за датами", fontsize=14)
plt.xlabel("Дата замовлення")
plt.ylabel("Виручка (CHF)")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()
fig_line = FIGS / "revenue_by_date.png"
plt.savefig(fig_line, dpi=150)
print(f"Графік збережено: {fig_line}")
plt.close()


# ===========================================================================
# Задача 5. Ключові показники (KPI)
# ===========================================================================
print("\n===== Задача 5. KPI =====")
kpi = {
    "total_orders":    df["OrderID"].nunique(),
    "total_units":     int(df["Quantity"].sum()),
    "total_revenue":   float(df["Revenue"].sum()),
    "avg_order_value": float(df.groupby("OrderID")["Revenue"].sum().mean()),
}
kpi_series = pd.Series(kpi, name="Value")
kpi_csv = DATA_OUT / "kpi.csv"
kpi_series.to_csv(kpi_csv)
print(kpi_series)
print(f"KPI збережено: {kpi_csv}")

# Бонус: heatmap жанрів по роках (топ-візуалізація з опису ПР9).
pivot = df.pivot_table(index="Genre", columns=df["OrderDate"].dt.to_period("M").astype(str),
                       values="Revenue", aggfunc="sum", fill_value=0)
plt.figure(figsize=(10, 6))
plt.imshow(pivot.values, aspect="auto", cmap="YlGnBu")
plt.colorbar(label="Виручка (CHF)")
plt.xticks(range(len(pivot.columns)), pivot.columns, rotation=45, ha="right")
plt.yticks(range(len(pivot.index)), pivot.index)
plt.title("Heatmap: виручка за жанром і місяцем")
plt.tight_layout()
fig_heat = FIGS / "heatmap_genre_month.png"
plt.savefig(fig_heat, dpi=150)
print(f"Heatmap збережено: {fig_heat}")
plt.close()

print("\n✅ ПР9 завершено. Артефакти:")
print(f"   CSV: {DATA_RAW}/ та {DATA_OUT}/")
print(f"   PNG: {FIGS}/")
