# CAST - приведение типов
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Команда CAST приводит значение к указанному типу данных.

Синтаксис:
SELECT CAST(column AS new_type) FROM table;

Примеры:
- SELECT CAST(budget AS DECIMAL(15,2)) FROM projects;
- SELECT CAST(text AS VARCHAR(2000)) FROM articles;