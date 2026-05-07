# DELETE - удаление данных
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда DELETE удаляет строки из таблицы.

Синтаксис:
DELETE FROM table_name WHERE condition;

Примеры:
- DELETE FROM employees WHERE id = 99;
- DELETE FROM news_articles WHERE status = 'draft';