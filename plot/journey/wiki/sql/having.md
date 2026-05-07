# HAVING - фильтрация групп
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Команда HAVING фильтрует группы после применения GROUP BY.

Синтаксис:
SELECT column1, aggregate_function(column2) FROM table GROUP BY column1 HAVING condition;

Примеры:
- SELECT department, COUNT(*) FROM employees GROUP BY department HAVING COUNT(*) > 5;
- SELECT source_id, COUNT(*) FROM articles GROUP BY source_id HAVING COUNT(*) > 3;