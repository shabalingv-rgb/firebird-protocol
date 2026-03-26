extends Node

var unlocked_topics: Array[String] = []
var read_articles: Array[String] = []

var guide_database: Dictionary = {
	# ==================== ОСНОВЫ SQL ====================
	
	"sql_basics_select": {
		"title": "SELECT - выборка данных",
		"category": "basics",
		"content": """
[b]SELECT[/b] — основная команда для чтения данных из таблиц.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT [DISTINCT] column1, column2, ...
FROM table_name
WHERE condition
ORDER BY column [ASC|DESC][/color][/code]

[b]Примеры:[/b]
[indent]• Выбрать все столбцы:
[code][color=00ff00]SELECT * FROM employees[/color][/code]

• Выбрать конкретные столбцы:
[code][color=00ff00]SELECT name, salary FROM employees[/color][/code]

• Выбрать уникальные значения:
[code][color=00ff00]SELECT DISTINCT department FROM employees[/color][/code][/indent]
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees
SELECT name, salary FROM employees
SELECT DISTINCT department FROM employees[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_1_start"
	},
	
	"sql_basics_from": {
		"title": "FROM - указание таблицы",
		"category": "basics",
		"content": """
[b]FROM[/b] указывает таблицу для запроса.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT columns FROM table_name[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT * FROM employees
SELECT name FROM employees
SELECT id, name, salary FROM employees[/color][/code]

Можно указывать несколько таблиц (для JOIN):
[code][color=00ff00]SELECT * FROM employees, departments[/color][/code]
		""",
		"example": "[code][color=00ff00]SELECT * FROM employees[/color][/code]",
		"firebird_specific": false,
		"unlock_condition": "day_1_start"
	},
	
	"sql_where_clause": {
		"title": "WHERE - фильтрация данных",
		"category": "basics",
		"content": """
[b]WHERE[/b] фильтрует записи по условию.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT columns FROM table
WHERE condition[/color][/code]

[b]Операторы сравнения:[/b]
[indent][b]=[/b] равно
[b]<>[/b] или [b]!=[/b] не равно
[b]>[/b], [b]<[/b] больше/меньше
[b]>=[/b], [b]<=[/b] больше/меньше или равно[/indent]

[b]Примеры:[/b]
[code][color=00ff00]SELECT * FROM employees WHERE salary > 80000
SELECT * FROM employees WHERE department = 'IT'
SELECT * FROM employees WHERE salary <> 50000[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees WHERE salary > 80000
SELECT * FROM employees WHERE department = 'IT'[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_1_start"
	},
	
	"sql_logical_operators": {
		"title": "Логические операторы",
		"category": "basics",
		"content": """
[b]AND, OR, NOT[/b] — комбинация условий.

[b]AND[/b] — оба условия истинны:
[code][color=00ff00]SELECT * FROM employees 
WHERE department = 'IT' AND salary > 75000[/color][/code]

[b]OR[/b] — хотя бы одно истинно:
[code][color=00ff00]SELECT * FROM employees 
WHERE department = 'IT' OR department = 'HR'[/color][/code]

[b]NOT[/b] — отрицание:
[code][color=00ff00]SELECT * FROM employees 
WHERE NOT department = 'IT'[/color][/code]

[b]Скобки для группировки:[/b]
[code][color=00ff00]SELECT * FROM employees 
WHERE (department = 'IT' OR department = 'HR') 
  AND salary > 70000[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees 
WHERE department = 'IT' AND salary > 75000[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_1_start"
	},
	
	"sql_insert": {
		"title": "INSERT - добавление записей",
		"category": "basics",
		"content": """
[b]INSERT INTO[/b] добавляет новые записи.

[b]Синтаксис:[/b]
[code][color=00ff00]INSERT INTO table (column1, column2)
VALUES (value1, value2)[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]INSERT INTO employees (id, name, department, salary)
VALUES (6, 'Новиков Дмитрий', 'IT', 90000)

INSERT INTO departments (id, name, budget)
VALUES (4, 'Marketing', 500000)[/color][/code]

[b]Вставка нескольких записей:[/b]
[code][color=00ff00]INSERT INTO employees (id, name, department, salary)
VALUES (7, 'Иванов А.', 'HR', 60000),
       (8, 'Петров Б.', 'IT', 85000)[/color][/code]
		""",
		"example": """[code][color=00ff00]INSERT INTO employees (id, name, department, salary)
VALUES (6, 'Новиков Дмитрий', 'IT', 90000)[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	},
	
	"sql_update": {
		"title": "UPDATE - обновление записей",
		"category": "basics",
		"content": """
[b]UPDATE[/b] изменяет существующие записи.

[b]Синтаксис:[/b]
[code][color=00ff00]UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]UPDATE employees 
SET salary = 85000 
WHERE id = 3

UPDATE employees 
SET salary = salary * 1.1, department = 'Senior IT'
WHERE department = 'IT'[/color][/code]

[b][color=ff0000]⚠️ Важно![/color][/b] Всегда используйте WHERE, иначе обновятся ВСЕ записи!
[code][color=00ff00]UPDATE employees SET salary = 100000[/color][/code] — обновит всех!
		""",
		"example": """[code][color=00ff00]UPDATE employees 
SET salary = 85000 
WHERE id = 3[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	},
	
	"sql_delete": {
		"title": "DELETE - удаление записей",
		"category": "basics",
		"content": """
[b]DELETE[/b] удаляет записи.

[b]Синтаксис:[/b]
[code][color=00ff00]DELETE FROM table_name
WHERE condition[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]DELETE FROM employees WHERE id = 5

DELETE FROM employees 
WHERE department = 'IT' AND salary < 50000[/color][/code]

[b][color=ff0000]⚠️ Важно![/color][/b] Без WHERE удалится всё!
[code][color=00ff00]DELETE FROM employees[/color][/code] — удалит ВСЕ записи!

[b]DELETE vs TRUNCATE:[/b]
[indent]• DELETE — можно откатить, медленнее
• TRUNCATE — нельзя откатить, быстрее[/indent]
		""",
		"example": "[code][color=00ff00]DELETE FROM employees WHERE id = 5[/color][/code]",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	},
	
	# ==================== ФИЛЬТРАЦИЯ И СОРТИРОВКА ====================
	
	"sql_order_by": {
		"title": "ORDER BY - сортировка",
		"category": "filtering",
		"content": """
[b]ORDER BY[/b] сортирует результаты.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT columns FROM table
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC][/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT * FROM employees 
ORDER BY salary DESC

SELECT * FROM employees 
ORDER BY department ASC, salary DESC[/color][/code]

[b]ASC[/b] — по возрастанию (по умолчанию)
[b]DESC[/b] — по убыванию

Можно сортировать по нескольким столбцам!
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees 
ORDER BY salary DESC, name ASC[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_1_completed"
	},
	
	"sql_group_by": {
		"title": "GROUP BY - группировка",
		"category": "filtering",
		"content": """
[b]GROUP BY[/b] группирует записи по столбцу.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT column, AGG_FUNC(column)
FROM table
GROUP BY column[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT department, COUNT(*) 
FROM employees 
GROUP BY department

SELECT department, AVG(salary)
FROM employees
GROUP BY department[/color][/code]

[b]Важно![/b] В SELECT можно указывать:
[indent]1. Столбцы из GROUP BY
2. Агрегатные функции (COUNT, SUM, AVG...)[/indent]
		""",
		"example": """[code][color=00ff00]SELECT department, COUNT(*) 
FROM employees 
GROUP BY department[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_2_start"
	},
	
	"sql_having": {
		"title": "HAVING - фильтр групп",
		"category": "filtering",
		"content": """
[b]HAVING[/b] фильтрует результаты GROUP BY.

[b]Отличие от WHERE:[/b]
[indent]• WHERE — фильтрует записи ДО группировки
• HAVING — фильтрует группы ПОСЛЕ группировки[/indent]

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT column, AGG_FUNC(column)
FROM table
GROUP BY column
HAVING condition[/color][/code]

[b]Пример:[/b]
[code][color=00ff00]SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 2[/color][/code]

Покажет только отделы с более чем 2 сотрудниками.
		""",
		"example": """[code][color=00ff00]SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 2[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_2_completed"
	},
	
	"sql_distinct": {
		"title": "DISTINCT - уникальные значения",
		"category": "filtering",
		"content": """
[b]DISTINCT[/b] возвращает только уникальные значения.

[b]Синтаксис:[/b]
[code][color=00ff00]SELECT DISTINCT column FROM table[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT DISTINCT department FROM employees

SELECT DISTINCT department, position 
FROM employees[/color][/code]

[b]Важно![/b] DISTINCT применяется ко всем столбцам в SELECT:
[code][color=00ff00]SELECT DISTINCT department, salary FROM employees[/color][/code]
— вернёт уникальные комбинации (отдел, зарплата)
		""",
		"example": "[code][color=00ff00]SELECT DISTINCT department FROM employees[/color][/code]",
		"firebird_specific": false,
		"unlock_condition": "day_1_completed"
	},
	
	"sql_between_in_like": {
		"title": "BETWEEN, IN, LIKE - специальные условия",
		"category": "filtering",
		"content": """
[b]BETWEEN[/b] — диапазон значений:
[code][color=00ff00]SELECT * FROM employees 
WHERE salary BETWEEN 70000 AND 90000[/color][/code]

[b]IN[/b] — список значений:
[code][color=00ff00]SELECT * FROM employees 
WHERE department IN ('IT', 'HR', 'Finance')[/color][/code]

[b]LIKE[/b] — поиск по шаблону:
[indent]%[code]%[/code] — любое количество символов
[code]_[/code] — один символ[/indent]

[code][color=00ff00]SELECT * FROM employees 
WHERE name LIKE 'Иван%'

SELECT * FROM employees 
WHERE name LIKE '%ов'

SELECT * FROM employees 
WHERE name LIKE 'П____в'[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees 
WHERE salary BETWEEN 70000 AND 90000

SELECT * FROM employees 
WHERE department IN ('IT', 'HR')

SELECT * FROM employees 
WHERE name LIKE 'Иван%'[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_1_completed"
	},
	
	# ==================== АГРЕГАТНЫЕ ФУНКЦИИ ====================
	
	"aggregate_count": {
		"title": "COUNT() - подсчёт записей",
		"category": "aggregates",
		"content": """
[b]COUNT()[/b] подсчитывает количество записей.

[b]Синтаксис:[/b]
[code][color=00ff00]COUNT(*)[/color][/code] — все записи
[code][color=00ff00]COUNT(column)[/color][/code] — записи где column NOT NULL

[b]Примеры:[/b]
[code][color=00ff00]SELECT COUNT(*) FROM employees
-- Общее количество сотрудников

SELECT COUNT(DISTINCT department) FROM employees
-- Количество уникальных отделов

SELECT department, COUNT(*)
FROM employees
GROUP BY department
-- Количество в каждом отделе[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT COUNT(*) FROM employees
SELECT COUNT(DISTINCT department) FROM employees[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_2_start"
	},
	
	"aggregate_sum_avg": {
		"title": "SUM() и AVG() - сумма и среднее",
		"category": "aggregates",
		"content": """
[b]SUM()[/b] — сумма значений:
[code][color=00ff00]SELECT SUM(salary) FROM employees
-- Общий фонд зарплат

SELECT department, SUM(salary)
FROM employees
GROUP BY department
-- Фонд по отделам[/color][/code]

[b]AVG()[/b] — среднее значение:
[code][color=00ff00]SELECT AVG(salary) FROM employees
-- Средняя зарплата

SELECT department, AVG(salary)
FROM employees
GROUP BY department
-- Средняя по отделам[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT SUM(salary) FROM employees
SELECT AVG(salary) FROM employees
SELECT department, AVG(salary) FROM employees GROUP BY department[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_2_start"
	},
	
	"aggregate_min_max": {
		"title": "MIN() и MAX() - минимум и максимум",
		"category": "aggregates",
		"content": """
[b]MIN()[/b] — минимальное значение:
[code][color=00ff00]SELECT MIN(salary) FROM employees
-- Минимальная зарплата

SELECT department, MIN(salary)
FROM employees
GROUP BY department[/color][/code]

[b]MAX()[/b] — максимальное значение:
[code][color=00ff00]SELECT MAX(salary) FROM employees
-- Максимальная зарплата

SELECT department, MAX(salary)
FROM employees
GROUP BY department[/color][/code]

Можно комбинировать:
[code][color=00ff00]SELECT MIN(salary), MAX(salary), AVG(salary)
FROM employees[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT MIN(salary), MAX(salary) FROM employees
SELECT department, MIN(salary), MAX(salary) 
FROM employees GROUP BY department[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_2_start"
	},
	
	# ==================== FIREBIRD-СПЕЦИФИКА ====================
	
	"firebird_data_types": {
		"title": "Типы данных Firebird",
		"category": "firebird_specific",
		"content": """
[b]Числовые:[/b]
[indent][b]SMALLINT[/b] — 2 байта (-32768 до 32767)
[b]INTEGER[/b] — 4 байта 
[b]BIGINT[/b] — 8 байт
[b]DECIMAL(p,s)[/b] — точное число (p цифр, s после запятой)
[b]NUMERIC(p,s)[/b] — аналог DECIMAL
[b]FLOAT[/b] — 4 байта (приблизительное)
[b]DOUBLE PRECISION[/b] — 8 байт[/indent]

[b]Строковые:[/b]
[indent][b]CHAR(n)[/b] — фиксированная длина
[b]VARCHAR(n)[/b] — переменная длина[/indent]

[b]Дата/время:[/b]
[indent][b]DATE[/b] — дата
[b]TIME[/b] — время
[b]TIMESTAMP[/b] — дата и время[/indent]

[b]Другие:[/b]
[indent][b]BLOB[/b] — большие объекты (текст, бинарные)
[b]BOOLEAN[/b] — TRUE/FALSE (Firebird 3.0+)[/indent]
		""",
		"example": """[code][color=00ff00]CREATE TABLE employees (
    id INTEGER,
    name VARCHAR(100),
    salary DECIMAL(10,2),
    hire_date TIMESTAMP
)[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "tutorial"
	},
	
	"firebird_list_function": {
		"title": "LIST() - групповая конкатенация",
		"category": "firebird_specific",
		"content": """
[b]LIST()[/b] — уникальная функция Firebird для объединения строк!

[b]Синтаксис:[/b]
[code][color=00ff00]LIST(column [, separator])[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT LIST(name, ', ') 
FROM employees

Результат:
Иванов Иван, Петрова Мария, Сидоров Алексей

SELECT department, LIST(name, ', ')
FROM employees
GROUP BY department

Результат:
IT        | Иванов Иван, Петрова Мария
HR        | Сидоров Алексей
Finance   | Козлова Елена[/color][/code]

[i]Аналоги в других СУБД:[/i]
[indent]• MySQL: GROUP_CONCAT()
• PostgreSQL: STRING_AGG()
• SQL Server: STRING_AGG()[/indent]
		""",
		"example": """[code][color=00ff00]SELECT LIST(name, ', ') FROM employees
SELECT department, LIST(name, ', ') FROM employees GROUP BY department[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_2_completed"
	},
	
	"firebird_extract": {
		"title": "EXTRACT() - работа с датами",
		"category": "firebird_specific",
		"content": """
[b]EXTRACT()[/b] извлекает часть даты/времени.

[b]Синтаксис:[/b]
[code][color=00ff00]EXTRACT(part FROM date_expression)[/color][/code]

[b]Части:[/b]
[indent]YEAR, MONTH, DAY
HOUR, MINUTE, SECOND
WEEKDAY (0=Monday, 6=Sunday)
YEARDAY (1-366)[/indent]

[b]Примеры:[/b]
[code][color=00ff00]SELECT EXTRACT(YEAR FROM hire_date) 
FROM employees

SELECT name, 
       EXTRACT(YEAR FROM hire_date) as hire_year
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) > 2020

SELECT EXTRACT(WEEKDAY FROM CURRENT_DATE)[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT EXTRACT(YEAR FROM hire_date) FROM employees
SELECT EXTRACT(MONTH FROM CURRENT_DATE)[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_2_completed"
	},
	
	"firebird_cast": {
		"title": "CAST() - преобразование типов",
		"category": "firebird_specific",
		"content": """
[b]CAST()[/b] преобразует значение к другому типу.

[b]Синтаксис:[/b]
[code][color=00ff00]CAST(expression AS type)[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT CAST(salary AS VARCHAR(20)) FROM employees

SELECT CAST('2024-01-15' AS DATE)

SELECT CAST('12345' AS INTEGER)

-- Форматирование даты
SELECT CAST(CURRENT_TIMESTAMP AS DATE)

-- Конкатенация с числом
SELECT name || ' earns ' || CAST(salary AS VARCHAR)
FROM employees[/color][/code]

[b]Полезно для:[/b]
[indent]• Преобразования строк в числа
• Форматирования вывода
• Конкатенации разных типов[/indent]
		""",
		"example": """[code][color=00ff00]SELECT CAST(salary AS VARCHAR(20)) FROM employees
SELECT CAST('2024-01-15' AS DATE)[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_3_start"
	},
	
	"firebird_coalesce": {
		"title": "COALESCE() - работа с NULL",
		"category": "firebird_specific",
		"content": """
[b]COALESCE()[/b] возвращает первое NOT NULL значение.

[b]Синтаксис:[/b]
[code][color=00ff00]COALESCE(value1, value2, ...)[/color][/code]

Возвращает первое не-NULL значение

[b]Примеры:[/b]
[code][color=00ff00]SELECT name, COALESCE(commission, 0) 
FROM employees
-- Если commission NULL, вернёт 0

SELECT name, COALESCE(phone, 'не указан')
FROM employees

-- Первое непустое значение
SELECT COALESCE(mobile, home_phone, work_phone, 'нет телефона')
FROM contacts[/color][/code]

[b]Полезно для:[/b]
[indent]• Замены NULL на значения по умолчанию
• Выбора первого доступного значения
• Избежания NULL в результатах[/indent]
		""",
		"example": """[code][color=00ff00]SELECT name, COALESCE(commission, 0) FROM employees
SELECT COALESCE(phone, 'не указан') FROM employees[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_3_start"
	},
	
	"firebird_nullif": {
		"title": "NULLIF() - замена значений на NULL",
		"category": "firebird_specific",
		"content": """
[b]NULLIF()[/b] возвращает NULL если значения равны.

[b]Синтаксис:[/b]
[code][color=00ff00]NULLIF(value1, value2)[/color][/code]

Возвращает NULL если value1 = value2, иначе value1

[b]Примеры:[/b]
[code][color=00ff00]SELECT name, NULLIF(salary, 0) 
FROM employees
-- Заменит 0 на NULL

-- Избежание деления на ноль
SELECT numerator / NULLIF(denominator, 0)
FROM calculations

-- Замена пустых строк на NULL
SELECT name, NULLIF(email, '') 
FROM employees[/color][/code]

[b]Полезно для:[/b]
[indent]• Избежания деления на ноль
• Замены 'пустых' значений на NULL
• Очистки данных[/indent]
		""",
		"example": """[code][color=00ff00]SELECT name, NULLIF(salary, 0) FROM employees
SELECT 100 / NULLIF(0, 0)[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_3_start"
	},
	
	"firebird_substring": {
		"title": "SUBSTRING() - работа со строками",
		"category": "firebird_specific",
		"content": """
[b]SUBSTRING()[/b] извлекает часть строки.

[b]Синтаксис:[/b]
[code][color=00ff00]SUBSTRING(string FROM start [FOR length])[/color][/code]

[b]Примеры:[/b]
[code][color=00ff00]SELECT SUBSTRING(name FROM 1 FOR 3) 
FROM employees
-- Первые 3 символа

SELECT SUBSTRING(email FROM POSITION('@' IN email) + 1)
FROM employees
-- Часть после @

SELECT SUBSTRING(phone FROM 1 FOR 3)
FROM employees
-- Код города[/color][/code]

[b]Другие строковые функции:[/b]
[indent][b]UPPER()[/b], [b]LOWER()[/b] — регистр
[b]TRIM()[/b] — убрать пробелы
[b]POSITION()[/b] — позиция подстроки
[b]CHAR_LENGTH()[/b] — длина строки[/indent]
		""",
		"example": """[code][color=00ff00]SELECT SUBSTRING(name FROM 1 FOR 3) FROM employees
SELECT SUBSTRING(email FROM 6) FROM employees[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_3_start"
	},
	
	"firebird_generators": {
		"title": "Генераторы (SEQUENCES)",
		"category": "firebird_specific",
		"content": """
[b]Генераторы[/b] создают уникальные числа (автоинкремент).

[b]Создание:[/b]
[code][color=00ff00]CREATE GENERATOR gen_employee_id
-- или
CREATE SEQUENCE gen_employee_id[/color][/code]

[b]Использование:[/b]
[code][color=00ff00]GEN_ID(gen_employee_id, 1)
-- или
NEXT VALUE FOR gen_employee_id[/color][/code]

[b]Пример:[/b]
[code][color=00ff00]CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100)
);

CREATE GENERATOR gen_employee_id;

INSERT INTO employees (id, name)
VALUES (GEN_ID(gen_employee_id, 1), 'Иванов');

-- Установка начального значения
SET GENERATOR gen_employee_id TO 100;[/color][/code]

[b]В Firebird 3.0+:[/b]
[code][color=00ff00]CREATE SEQUENCE seq_employee_id START WITH 1;

INSERT INTO employees (id, name)
VALUES (NEXT VALUE FOR seq_employee_id, 'Иванов')[/color][/code]
		""",
		"example": """[code][color=00ff00]CREATE GENERATOR gen_id
SELECT GEN_ID(gen_id, 1) FROM RDB$DATABASE
SET GENERATOR gen_id TO 100[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "advanced"
	},
	
	"firebird_triggers": {
		"title": "Триггеры",
		"category": "firebird_specific",
		"content": """
[b]Триггеры[/b] автоматически выполняются при событиях.

[b]Синтаксис:[/b]
[code][color=00ff00]CREATE TRIGGER trigger_name
FOR table_name
ACTIVE BEFORE/AFTER INSERT/UPDATE/DELETE
AS
BEGIN
  -- код
END[/color][/code]

[b]Пример - автоинкремент:[/b]
[code][color=00ff00]CREATE TRIGGER employees_bi 
FOR employees
ACTIVE BEFORE INSERT
AS
BEGIN
  NEW.id = GEN_ID(gen_employee_id, 1);
END[/color][/code]

[b]Пример - аудит:[/b]
[code][color=00ff00]CREATE TRIGGER employees_au
FOR employees
ACTIVE AFTER UPDATE
AS
BEGIN
  INSERT INTO audit_log (table_name, record_id, changed_at)
  VALUES ('employees', NEW.id, CURRENT_TIMESTAMP);
END[/color][/code]

[b]NEW[/b] — новые данные
[b]OLD[/b] — старые данные (для UPDATE/DELETE)
		""",
		"example": """[code][color=00ff00]CREATE TRIGGER employees_bi
FOR employees
ACTIVE BEFORE INSERT
AS
BEGIN
  NEW.id = GEN_ID(gen_employee_id, 1);
END[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "advanced"
	},
	
	"firebird_procedures": {
		"title": "Хранимые процедуры",
		"category": "firebird_specific",
		"content": """
[b]Хранимые процедуры[/b] — именованные блоки кода.

[b]Создание:[/b]
[code][color=00ff00]CREATE PROCEDURE get_employee_salary(emp_id INTEGER)
RETURNS (salary DECIMAL(10,2))
AS
BEGIN
  SELECT salary FROM employees 
  WHERE id = :emp_id
  INTO :salary;
  SUSPEND;
END[/color][/code]

[b]Вызов:[/b]
[code][color=00ff00]SELECT * FROM get_employee_salary(5)

EXECUTE PROCEDURE get_employee_salary(5)[/color][/code]

[b]Процедура с параметрами:[/b]
[code][color=00ff00]CREATE PROCEDURE update_salary(
    emp_id INTEGER, 
    percent DECIMAL(5,2))
AS
BEGIN
  UPDATE employees 
  SET salary = salary * (1 + :percent / 100)
  WHERE id = :emp_id;
END

EXECUTE PROCEDURE update_salary(5, 10);[/color][/code]
		""",
		"example": """[code][color=00ff00]CREATE PROCEDURE get_employee_count
RETURNS (cnt INTEGER)
AS
BEGIN
  SELECT COUNT(*) FROM employees INTO :cnt;
  SUSPEND;
END[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "advanced"
	},
	
	"firebird_current_timestamp": {
		"title": "CURRENT_TIMESTAMP и NOW()",
		"category": "firebird_specific",
		"content": """
[b]CURRENT_TIMESTAMP[/b] — текущая дата и время.

[b]Примеры:[/b]
[code][color=00ff00]INSERT INTO employees (id, name, hire_date)
VALUES (1, 'Иванов', CURRENT_TIMESTAMP)

UPDATE employees 
SET last_login = CURRENT_TIMESTAMP
WHERE id = 5

SELECT CURRENT_TIMESTAMP
-- 2024-03-26 14:30:15.123[/color][/code]

[b]Другие функции времени:[/b]
[indent][b]CURRENT_DATE[/b] — текущая дата
[b]CURRENT_TIME[/b] — текущее время
[b]NOW()[/b] — аналог CURRENT_TIMESTAMP[/indent]

[b]Пример использования:[/b]
[code][color=00ff00]SELECT name, hire_date,
       CURRENT_DATE - hire_date as days_worked
FROM employees[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT CURRENT_TIMESTAMP
INSERT INTO log (event_time) VALUES (CURRENT_TIMESTAMP)
SELECT CURRENT_DATE FROM RDB$DATABASE[/color][/code]""",
		"firebird_specific": true,
		"unlock_condition": "day_3_start"
	},
	
	# ==================== ПРОДВИНУТЫЙ SQL ====================
	
	"sql_joins": {
		"title": "JOIN - соединение таблиц",
		"category": "advanced",
		"content": """
[b]JOIN[/b] объединяет данные из нескольких таблиц.

[b]INNER JOIN[/b] — только совпадающие:
[code][color=00ff00]SELECT e.name, d.name
FROM employees e
INNER JOIN departments d ON e.department_id = d.id[/color][/code]

[b]LEFT JOIN[/b] — все из левой + совпадения:
[code][color=00ff00]SELECT e.name, d.name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id[/color][/code]

[b]RIGHT JOIN[/b] — все из правой + совпадения:
[code][color=00ff00]SELECT e.name, d.name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.id[/color][/code]

[b]CROSS JOIN[/b] — декартово произведение:
[code][color=00ff00]SELECT * FROM employees CROSS JOIN departments[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT e.name, d.budget
FROM employees e
INNER JOIN departments d ON e.department = d.name[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_3_completed"
	},
	
	"sql_subqueries": {
		"title": "Подзапросы",
		"category": "advanced",
		"content": """
[b]Подзапрос[/b] — запрос внутри запроса.

[b]В WHERE:[/b]
[code][color=00ff00]SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)[/color][/code]

[b]В SELECT:[/b]
[code][color=00ff00]SELECT name, salary,
       (SELECT AVG(salary) FROM employees) as avg_salary
FROM employees[/color][/code]

[b]В FROM:[/b]
[code][color=00ff00]SELECT dept, avg_sal
FROM (SELECT department as dept, AVG(salary) as avg_sal
      FROM employees
      GROUP BY department) as dept_stats[/color][/code]

[b]С IN:[/b]
[code][color=00ff00]SELECT * FROM employees
WHERE department IN (
    SELECT name FROM departments WHERE budget > 1000000
)[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "day_3_completed"
	},
	
	"sql_union": {
		"title": "UNION, INTERSECT, EXCEPT",
		"category": "advanced",
		"content": """
[b]UNION[/b] — объединение результатов:
[code][color=00ff00]SELECT name FROM employees
UNION
SELECT name FROM managers[/color][/code]

[b]UNION ALL[/b] — с дубликатами:
[code][color=00ff00]SELECT name FROM employees
UNION ALL
SELECT name FROM managers[/color][/code]

[b]INTERSECT[/b] — пересечение (общие):
[code][color=00ff00]SELECT department FROM employees
INTERSECT
SELECT name FROM departments[/color][/code]

[b]EXCEPT[/b] — разница (есть в первом, нет во втором):
[code][color=00ff00]SELECT department FROM employees
EXCEPT
SELECT name FROM departments[/color][/code]

Все операторы требуют одинакового количества столбцов!
		""",
		"example": """[code][color=00ff00]SELECT name FROM employees WHERE salary > 80000
UNION
SELECT name FROM managers[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "advanced"
	},
	
	"sql_case_when": {
		"title": "CASE WHEN - условная логика",
		"category": "advanced",
		"content": """
[b]CASE[/b] позволяет использовать условия в SELECT.

[b]Синтаксис:[/b]
[code][color=00ff00]CASE
  WHEN condition1 THEN result1
  WHEN condition2 THEN result2
  ELSE default_result
END[/color][/code]

[b]Пример:[/b]
[code][color=00ff00]SELECT name, salary,
CASE
  WHEN salary > 100000 THEN 'High'
  WHEN salary > 70000 THEN 'Medium'
  ELSE 'Low'
END as salary_level
FROM employees[/color][/code]

[b]Пример с агрегацией:[/b]
[code][color=00ff00]SELECT 
  COUNT(CASE WHEN salary > 80000 THEN 1 END) as high_count,
  COUNT(CASE WHEN salary <= 80000 THEN 1 END) as low_count
FROM employees[/color][/code]
		""",
		"example": """[code][color=00ff00]SELECT name, salary,
CASE
  WHEN salary > 90000 THEN 'Senior'
  WHEN salary > 70000 THEN 'Middle'
  ELSE 'Junior'
END as level
FROM employees[/color][/code]""",
		"firebird_specific": false,
		"unlock_condition": "advanced"
	},
	
	# ==================== ИГРОВЫЕ МЕХАНИКИ ====================
	
	"game_quest_system": {
		"title": "Система заданий",
		"category": "game_mechanics",
		"content": """
[b]Как работать с заданиями:[/b]

[indent]1. [b]Получение:[/b] Откройте почту и прочитайте письмо с заданием
2. [b]Выполнение:[/b] Откройте терминал и введите SQL-запрос
3. [b]Проверка:[/b] Система автоматически проверит результат
4. [b]Отчёт:[/b] Нажмите кнопку "Отправить отчёт" в письме[/indent]

[b]Типы заданий:[/b]
[indent]• 🟢 [b]Лёгкие[/b] — простые SELECT, WHERE
• 🟡 [b]Средние[/b] — GROUP BY, агрегаты
• 🔴 [b]Сложные[/b] — JOIN, подзапросы[/indent]

[b]Советы:[/b]
[indent]• Используйте справку (книга на рабочем столе)
• Проверяйте результаты перед отправкой
• Экспериментируйте с запросами[/indent]
		""",
		"example": "",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	},
	
	"game_violations": {
		"title": "Нарушения и последствия",
		"category": "game_mechanics",
		"content": """
[b]Нарушения[/b] — ошибки при работе с данными.

[b]Что считается нарушением:[/b]
[indent]• Неверный SQL-запрос
• Изменение не тех данных
• Нарушение инструкций в письмах
• Пропуск дедлайнов[/indent]

[b]Последствия:[/b]
[indent]• 1-2 нарушения — предупреждение
• 3-5 нарушений — выговор
• 5+ нарушений — увольнение (Game Over)[/indent]

[b]Как избежать:[/b]
[indent]• Внимательно читайте задания
• Проверяйте запросы перед выполнением
• Используйте WHERE с осторожностью
• Сохраняйте резервные копии[/indent]

[b][color=00ffff]💡 Совет:[/color][/b] Если не уверены — сначала SELECT, потом UPDATE/DELETE!
		""",
		"example": "",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	},
	
	"game_time_system": {
		"title": "Игровое время",
		"category": "game_mechanics",
		"content": """
[b]Время в игре:[/b]

[indent]• Каждый день = 8 рабочих часов
• Задания нужно выполнить до конца дня
• Пропуск дедлайна = нарушение[/indent]

[b]Отслеживание времени:[/b]
[indent]• Часы в правом верхнем углу
• Текущий день отображается в заголовке[/indent]

[b]Прогрессия:[/b]
[indent]• День 1-3: Обучение (простые запросы)
• День 4-10: Работа (средняя сложность)
• День 11-20: Ответственность (сложные задачи)
• День 21-30: Эксперт (критические решения)[/indent]

[b][color=00ffff]💡 Совет:[/color][/b] Не откладывайте на последний час!
		""",
		"example": "",
		"firebird_specific": false,
		"unlock_condition": "tutorial"
	}
}

func _ready():
	print("📖 Guide System загружен!")
	# Разблокируем базовые темы
	unlock_topic("sql_basics_select")
	unlock_topic("sql_basics_from")
	unlock_topic("sql_where_clause")
	unlock_topic("game_quest_system")
	unlock_topic("game_violations")
	unlock_topic("game_time_system")

func unlock_topic(topic_id: String):
	if not unlocked_topics.has(topic_id):
		unlocked_topics.append(topic_id)
		if guide_database.has(topic_id):
			print("📖 Открыта тема: ", guide_database[topic_id].title)

func is_topic_unlocked(topic_id: String) -> bool:
	return unlocked_topics.has(topic_id)

func mark_as_read(article_id: String):
	if not read_articles.has(article_id):
		read_articles.append(article_id)
		print("📚 Прочитано: ", article_id)
