# GROUP BY - группировка
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Команда GROUP BY группирует результаты по значению колонки.

Синтаксис:
SELECT column1, aggregate_function(column2) FROM table GROUP BY column1;

Примеры:
- SELECT department, COUNT(*) FROM employees GROUP BY department;
- SELECT source_id, COUNT(*) FROM articles GROUP BY source_id;