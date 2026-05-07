# COALESCE - замена NULL
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Функция COALESCE возвращает первое не-NULL значение из списка.

Синтаксис:
SELECT COALESCE(column, default_value) FROM table;

Примеры:
- SELECT COALESCE(author_name, 'Аноним') FROM articles;
- SELECT COALESCE(department, 'Не указано') FROM employees;