# CREATE PROCEDURE - хранимые процедуры
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда CREATE PROCEDURE создаёт хранимую процедуру для выполнения сложной логики.

Синтаксис:
CREATE PROCEDURE name(params) AS BEGIN ... END;

Примеры:
- CREATE PROCEDURE GET_TOP_ARTICLES(limit INT) AS ...;
- CREATE PROCEDURE UPDATE_PROJECT_STATUS(p_id INT, new_status VARCHAR(20)) AS ...;