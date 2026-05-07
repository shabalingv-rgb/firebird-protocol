# CREATE TABLE AS SELECT - копирование данных
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда CREATE TABLE AS SELECT создаёт новую таблицу на основе результатов запроса.

Синтаксис:
CREATE TABLE new_table AS SELECT ... FROM existing_table;

Примеры:
- CREATE TABLE ARCHIVE_PROJECTS AS SELECT * FROM projects WHERE status = 'COMPLETED';