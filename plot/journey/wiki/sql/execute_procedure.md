# EXECUTE PROCEDURE - вызов процедуры
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда EXECUTE PROCEDURE запускает хранимую процедуру.

Синтаксис:
EXECUTE PROCEDURE name(params);

Примеры:
- EXECUTE PROCEDURE GET_TOP_ARTICLES(5);
- EXECUTE PROCEDURE UPDATE_PROJECT_STATUS(42, 'COMPLETED');