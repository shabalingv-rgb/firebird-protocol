# LIKE - поиск по шаблону
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Оператор LIKE ищет совпадения по шаблону.

Синтаксис:
SELECT columns FROM table WHERE column LIKE pattern;

Примеры:
- SELECT * FROM employees WHERE name LIKE 'Ив%';
- SELECT * FROM news_articles WHERE title LIKE '%кризис%';