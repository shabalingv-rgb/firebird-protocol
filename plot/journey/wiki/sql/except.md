# EXCEPT - разность запросов
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Оператор EXCEPT возвращает строки из первого запроса, которых нет во втором.

Синтаксис:
SELECT column FROM table1 EXCEPT SELECT column FROM table2;

Примеры:
- SELECT * FROM articles EXCEPT SELECT * FROM top_10_articles;