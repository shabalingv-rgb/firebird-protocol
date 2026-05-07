# IN - проверка на принадлежность списку
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Оператор IN проверяет, находится ли значение в указанном списке.

Синтаксис:
SELECT columns FROM table WHERE column IN (value1, value2, ...);

Примеры:
- SELECT * FROM projects WHERE code IN (101, 102, 103);
- SELECT * FROM articles WHERE id IN (12, 15, 18, 22);