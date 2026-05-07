# CREATE CONSTRAINT - ограничения
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда CREATE CONSTRAINT добавляет ограничение на таблицу.

Синтаксис:
ALTER TABLE table ADD CONSTRAINT name CHECK (condition);

Примеры:
- ALTER TABLE projects ADD CONSTRAINT chk_budget CHECK (budget >= 0);