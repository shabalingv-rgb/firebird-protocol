# INTERSECT - пересечение запросов
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Оператор INTERSECT возвращает строки, которые присутствуют в обоих запросах.

Синтаксис:
SELECT column FROM table1 INTERSECT SELECT column FROM table2;

Примеры:
- SELECT * FROM articles INTERSECT SELECT * FROM top_articles;