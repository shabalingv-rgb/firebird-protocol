# UPDATE - обновление данных
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда UPDATE изменяет существующие записи в таблице.

Синтаксис:
UPDATE table_name SET column1 = value1 WHERE condition;

Примеры:
- UPDATE employees SET salary = 80000 WHERE id = 5;
- UPDATE news_articles SET status = 'published' WHERE id = 10;