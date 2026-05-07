# REVOKE - отзыв прав
**Категория:** sql  
**Постоянная:** да  
**Уровень:** начальный

```
Команда REVOKE отменяет ранее предоставленные права.

Синтаксис:
REVOKE privilege ON object FROM user;

Примеры:
- REVOKE INSERT ON employees FROM intern;
- REVOKE SELECT ON confidential FROM public;