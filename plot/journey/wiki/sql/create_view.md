# CREATE VIEW - представления
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда CREATE VIEW создаёт виртуальную таблицу на основе запроса.

Синтаксис:
CREATE VIEW name AS SELECT ... WITH CHECK OPTION;

Примеры:
- CREATE VIEW V_PENDING_PROJECTS AS SELECT * FROM projects WHERE status = 'IN_PROGRESS' WITH CHECK OPTION;