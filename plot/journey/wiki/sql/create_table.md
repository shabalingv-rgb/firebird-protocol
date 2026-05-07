# CREATE TABLE - создание таблицы
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда CREATE TABLE создаёт новую таблицу в базе данных.

Синтаксис:
CREATE TABLE table_name (
    column1 datatype,
    column2 datatype
);

Примеры:
- CREATE TABLE project_logs (id INT, log_text VARCHAR(500));
- CREATE TABLE sources (id INT, name VARCHAR(100), url VARCHAR(200));