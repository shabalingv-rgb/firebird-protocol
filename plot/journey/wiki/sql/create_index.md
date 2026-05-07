# CREATE INDEX - создание индекса
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда CREATE INDEX создаёт индекс для ускорения поиска.

Синтаксис:
CREATE INDEX index_name ON table_name (column_name);

Примеры:
- CREATE INDEX idx_emp_status ON employees (status);
- CREATE INDEX idx_source_name ON sources (name);