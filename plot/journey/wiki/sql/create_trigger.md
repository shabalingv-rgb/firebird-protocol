# CREATE TRIGGER - триггеры
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда CREATE TRIGGER создаёт триггер, срабатывающий при определённом событии.

Синтаксис:
CREATE TRIGGER name FOR table ACTIVE BEFORE/AFTER INSERT/UPDATE AS BEGIN ... END;

Примеры:
- CREATE TRIGGER audit_trigger FOR articles AFTER UPDATE AS ...;