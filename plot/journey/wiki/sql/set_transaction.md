# SET TRANSACTION - настройка транзакции
**Категория:** sql  
**Постоянная:** да  
**Уровень:** продвинутый

```
Команда SET TRANSACTION настраивает параметры текущей транзакции.

Синтаксис:
SET TRANSACTION [READ COMMITTED | SERIALIZABLE] [WAIT | NO WAIT];

Примеры:
- SET TRANSACTION READ COMMITTED;