# GRANT - предоставление прав
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда GRANT предоставляет пользователю или роли права на объекты.

Синтаксис:
GRANT privilege ON object TO user;

Примеры:
- GRANT SELECT, INSERT ON employees TO analyst;
- GRANT SELECT ON sources TO reader;