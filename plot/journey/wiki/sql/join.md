# JOIN - соединение таблиц
**Категория:** sql  
**Постоянная:** да  
**Уровень:** средний

```
Команда JOIN соединяет две или более таблиц по связанному полю.

Синтаксис:
SELECT columns FROM table1 JOIN table2 ON table1.column = table2.column;

Примеры:
- SELECT e.name, p.project_name FROM employees e JOIN projects p ON e.id = p.employee_id;
- SELECT a.title, s.source_name FROM articles a JOIN sources s ON a.source_id = s.id;