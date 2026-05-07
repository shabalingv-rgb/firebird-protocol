# IS NULL - проверка на пустое значение
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Оператор IS NULL проверяет, равно ли значение NULL.

Синтаксис:
SELECT columns FROM table WHERE column IS NULL;

Примеры:
- SELECT * FROM employees WHERE department IS NULL;
- SELECT * FROM articles WHERE author IS NULL;