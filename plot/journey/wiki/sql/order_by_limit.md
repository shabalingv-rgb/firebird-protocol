# ORDER BY ... LIMIT - сортировка с ограничением
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Команда ORDER BY сортирует результаты, LIMIT ограничивает количество возвращаемых строк.

Синтаксис:
SELECT columns FROM table ORDER BY column [ASC|DESC] LIMIT count;

Примеры:
- SELECT * FROM employees ORDER BY salary DESC LIMIT 5;
- SELECT * FROM news_articles ORDER BY publish_date ASC LIMIT 10;