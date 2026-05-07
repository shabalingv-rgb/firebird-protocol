# BETWEEN - проверка на принадлежность диапазону
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Оператор BETWEEN проверяет, находится ли значение в указанном диапазоне (включительно).

Синтаксис:
SELECT columns FROM table WHERE column BETWEEN value1 AND value2;

Примеры:
- SELECT * FROM projects WHERE start_date BETWEEN '2023-01-01' AND '2023-12-31';
- SELECT * FROM articles WHERE publish_date BETWEEN '2023-06-01' AND '2023-06-30';