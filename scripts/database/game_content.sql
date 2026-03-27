-- ============================================
-- FIREBIRD PROTOCOL - GAME CONTENT DATABASE
-- Версия: Firebird SQL 5.0
-- Дата: 2026-03-26
-- ============================================

-- ============================================
-- 1. ГЕНЕРАТОРЫ (SEQUENCES) для автоинкремента
-- ============================================

CREATE GENERATOR gen_game_days_id;
CREATE GENERATOR gen_emails_id;
CREATE GENERATOR gen_quests_id;
CREATE GENERATOR gen_sql_commands_id;
CREATE GENERATOR gen_player_progress_id;
CREATE GENERATOR gen_player_choices_id;
CREATE GENERATOR gen_news_articles_id;
CREATE GENERATOR gen_employee_dossiers_id;
CREATE GENERATOR gen_random_events_id;
CREATE GENERATOR gen_endings_id;

-- ============================================
-- 2. ТАБЛИЦЫ
-- ============================================

-- Дни игры
CREATE TABLE game_days (
	id INTEGER PRIMARY KEY,
	role VARCHAR(20) NOT NULL,
	day_number INTEGER NOT NULL,
	title VARCHAR(100),
	description BLOB SUB_TYPE TEXT,
	is_playable BOOLEAN DEFAULT TRUE,
	alternative_activity VARCHAR(50),
	CONSTRAINT uk_role_day UNIQUE(role, day_number)
);

-- Письма
CREATE TABLE emails (
	id INTEGER PRIMARY KEY,
	day_id INTEGER REFERENCES game_days(id) ON DELETE CASCADE,
	sender VARCHAR(100) NOT NULL,
	sender_email VARCHAR(100),
	subject VARCHAR(200) NOT NULL,
	body BLOB SUB_TYPE TEXT NOT NULL,
	email_type VARCHAR(20),
	is_required BOOLEAN DEFAULT TRUE,
	sort_order INTEGER DEFAULT 0,
	unlock_condition VARCHAR(100)
);

-- Задания (квесты)
CREATE TABLE quests (
	id INTEGER PRIMARY KEY,
	email_id INTEGER REFERENCES emails(id) ON DELETE CASCADE,
	title VARCHAR(200) NOT NULL,
	description BLOB SUB_TYPE TEXT,
	sql_template VARCHAR(1000) NOT NULL,
	expected_rows INTEGER,
	expected_columns VARCHAR(200),
	difficulty VARCHAR(10),
	time_limit_minutes INTEGER DEFAULT 0,
	sql_skills_required VARCHAR(200),
	story_flags_set VARCHAR(500),
	story_flags_required VARCHAR(500),
	moral_choice BOOLEAN DEFAULT FALSE,
	consequences BLOB SUB_TYPE TEXT
);

-- SQL-команды (для трекинга)
CREATE TABLE sql_commands (
	id INTEGER PRIMARY KEY,
	command_name VARCHAR(50) NOT NULL,
	category VARCHAR(30),
	firebird_specific BOOLEAN DEFAULT FALSE,
	introduced_day INTEGER,
	times_used INTEGER DEFAULT 0,
	last_used_day INTEGER DEFAULT 0
);

-- Прогресс игрока
CREATE TABLE player_progress (
	id INTEGER PRIMARY KEY,
	save_slot INTEGER DEFAULT 1,
	current_role VARCHAR(20),
	current_day INTEGER DEFAULT 1,
	violations INTEGER DEFAULT 0,
	trust_level INTEGER DEFAULT 50,
	flags_unlocked BLOB SUB_TYPE TEXT,
	quests_completed BLOB SUB_TYPE TEXT,
	endings_unlocked BLOB SUB_TYPE TEXT,
	total_playtime_minutes INTEGER DEFAULT 0,
	last_saved TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Выборы игрока
CREATE TABLE player_choices (
	id INTEGER PRIMARY KEY,
	quest_id INTEGER REFERENCES quests(id),
	choice_type VARCHAR(50),
	choice_value VARCHAR(500),
	day_id INTEGER REFERENCES game_days(id),
	consequences_applied BOOLEAN DEFAULT FALSE,
	choice_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Новости для браузера
CREATE TABLE news_articles (
	id INTEGER PRIMARY KEY,
	day_id INTEGER REFERENCES game_days(id),
	title VARCHAR(200) NOT NULL,
	content BLOB SUB_TYPE TEXT NOT NULL,
	category VARCHAR(30),
	is_visible BOOLEAN DEFAULT TRUE,
	visibility_condition VARCHAR(100),
	publish_date DATE
);

-- Досье сотрудников
CREATE TABLE employee_dossiers (
	id INTEGER PRIMARY KEY,
	employee_name VARCHAR(100) NOT NULL,
	position VARCHAR(100),
	department VARCHAR(50),
	hire_date DATE,
	status VARCHAR(20),
	dossier_text BLOB SUB_TYPE TEXT,
	unlock_condition VARCHAR(100),
	is_mysterious BOOLEAN DEFAULT FALSE
);

-- Случайные события
CREATE TABLE random_events (
	id INTEGER PRIMARY KEY,
	event_name VARCHAR(100) NOT NULL,
	event_type VARCHAR(30),
	min_day INTEGER,
	max_day INTEGER,
	trigger_chance DECIMAL(5,2),
	effect_description BLOB SUB_TYPE TEXT,
	can_occur_multiple BOOLEAN DEFAULT FALSE
);

-- Концовки
CREATE TABLE endings (
	id INTEGER PRIMARY KEY,
	ending_name VARCHAR(100) NOT NULL,
	ending_type VARCHAR(20),
	role_required VARCHAR(20),
	conditions_required BLOB SUB_TYPE TEXT,
	description BLOB SUB_TYPE TEXT,
	is_secret BOOLEAN DEFAULT FALSE
);

-- ============================================
-- 3. ТРИГГЕРЫ для автоинкремента
-- ============================================

CREATE TRIGGER trg_game_days_ai FOR game_days
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_game_days_id, 1);
END;

CREATE TRIGGER trg_emails_ai FOR emails
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_emails_id, 1);
END;

CREATE TRIGGER trg_quests_ai FOR quests
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_quests_id, 1);
END;

CREATE TRIGGER trg_sql_commands_ai FOR sql_commands
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_sql_commands_id, 1);
END;

CREATE TRIGGER trg_player_progress_ai FOR player_progress
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_player_progress_id, 1);
END;

CREATE TRIGGER trg_player_choices_ai FOR player_choices
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_player_choices_id, 1);
END;

CREATE TRIGGER trg_news_articles_ai FOR news_articles
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_news_articles_id, 1);
END;

CREATE TRIGGER trg_employee_dossiers_ai FOR employee_dossiers
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_employee_dossiers_id, 1);
END;

CREATE TRIGGER trg_random_events_ai FOR random_events
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_random_events_id, 1);
END;

CREATE TRIGGER trg_endings_ai FOR endings
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
	IF (NEW.id IS NULL) THEN
		NEW.id = GEN_ID(gen_endings_id, 1);
END;

-- ============================================
-- 4. ИНДЕКСЫ
-- ============================================

CREATE INDEX idx_emails_day ON emails(day_id);
CREATE INDEX idx_emails_type ON emails(email_type);
CREATE INDEX idx_quests_email ON quests(email_id);
CREATE INDEX idx_quests_difficulty ON quests(difficulty);
CREATE INDEX idx_progress_slot ON player_progress(save_slot);
CREATE INDEX idx_news_day ON news_articles(day_id);
CREATE INDEX idx_news_category ON news_articles(category);
CREATE INDEX idx_dossiers_status ON employee_dossiers(status);
CREATE INDEX idx_events_range ON random_events(min_day, max_day);

-- ============================================
-- 5. НАЧАЛЬНЫЕ ДАННЫЕ: SQL-команды
-- ============================================

INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES
('SELECT', 'basics', FALSE, 1, 0),
('FROM', 'basics', FALSE, 1, 0),
('WHERE', 'filtering', FALSE, 1, 0),
('ORDER BY', 'filtering', FALSE, 2, 0),
('GROUP BY', 'aggregates', FALSE, 3, 0),
('HAVING', 'filtering', FALSE, 4, 0),
('COUNT', 'aggregates', FALSE, 3, 0),
('SUM', 'aggregates', FALSE, 4, 0),
('AVG', 'aggregates', FALSE, 4, 0),
('MIN', 'aggregates', FALSE, 4, 0),
('MAX', 'aggregates', FALSE, 4, 0),
('JOIN', 'advanced', FALSE, 5, 0),
('INNER JOIN', 'advanced', FALSE, 5, 0),
('LEFT JOIN', 'advanced', FALSE, 6, 0),
('SUBQUERY', 'advanced', FALSE, 6, 0),
('UNION', 'advanced', FALSE, 7, 0),
('INTERSECT', 'advanced', FALSE, 7, 0),
('EXCEPT', 'advanced', FALSE, 7, 0),
('CASE WHEN', 'advanced', FALSE, 7, 0),
('DISTINCT', 'filtering', FALSE, 2, 0),
('LIKE', 'filtering', FALSE, 2, 0),
('BETWEEN', 'filtering', FALSE, 2, 0),
('IN', 'filtering', FALSE, 2, 0),
('LIST()', 'aggregates', TRUE, 8, 0),
('EXTRACT()', 'functions', TRUE, 8, 0),
('CAST()', 'functions', TRUE, 9, 0),
('COALESCE()', 'functions', TRUE, 9, 0),
('NULLIF()', 'functions', TRUE, 9, 0),
('SUBSTRING()', 'functions', TRUE, 9, 0),
('UPDATE', 'modification', FALSE, 11, 0),
('INSERT', 'modification', FALSE, 11, 0),
('DELETE', 'modification', FALSE, 12, 0),
('MERGE', 'modification', FALSE, 11, 0),
('TRANSACTION', 'advanced', TRUE, 13, 0),
('COMMIT', 'advanced', TRUE, 13, 0),
('ROLLBACK', 'advanced', TRUE, 13, 0),
('TRIGGER', 'advanced', TRUE, 14, 0),
('PROCEDURE', 'advanced', TRUE, 14, 0),
('GENERATOR', 'advanced', TRUE, 15, 0),
('SEQUENCE', 'advanced', TRUE, 15, 0);

-- ============================================
-- 6. НАЧАЛЬНЫЕ ДАННЫЕ: Дни 1-10 (Сотрудник)
-- ============================================

-- ДЕНЬ 1
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 1, 'Первый день', 'Добро пожаловать в НИИ "Файербёрд". Сегодня ваш первый рабочий день.', TRUE);

-- ДЕНЬ 2
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 2, 'Странности', 'Коллеги ведут себя подозрительно. Вам поручают необычные задания.', TRUE);

-- ДЕНЬ 3
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 3, 'Статистика', 'Руководство запрашивает отчёт по отделам. Обратите внимание на аномалии.', TRUE);

-- ДЕНЬ 4
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 4, 'Аномалия', 'В данных обнаружены несоответствия. Кто-то редактировал записи.', TRUE);

-- ДЕНЬ 5
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 5, 'Исчезновение', 'Сотрудник отдела безопасности исчез. Его запись удалена из базы.', TRUE);

-- ДЕНЬ 6
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 6, 'Проверка', 'Служба безопасности проводит проверку всех доступов.', TRUE);

-- ДЕНЬ 7
INSERT INTO game_days (role, day_number, title, description, is_playable, moral_choice) VALUES
('employee', 7, 'Выбор', 'Вам приказывают скрыть определённые данные. Что вы решите?', TRUE);

-- ДЕНЬ 8
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 8, 'Особый', 'Специальное задание от руководства. Используйте возможности Firebird.', TRUE);

-- ДЕНЬ 9
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES
('employee', 9, 'Выходной', 'У вас выходной день. Отдохните от работы.', FALSE, 'bar');

-- ДЕНЬ 10
INSERT INTO game_days (role, day_number, title, description, is_playable) VALUES
('employee', 10, 'Осознание', 'Вы находите информацию, которая меняет всё.', TRUE);

-- ============================================
-- 7. НАЧАЛЬНЫЕ ДАННЫЕ: Письма (Дни 1-10)
-- ============================================

-- ДЕНЬ 1 - Письмо 1 (HR)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(1, 'Отдел кадров', 'hr@nii-firebird.gov', 
'Добро пожаловать в НИИ "Файербёрд"', 
'Уважаемый сотрудник!

Поздравляем с первым рабочим днём в Научно-Исследовательском Институте "Файербёрд".

Ваш доступ к системе Firebird SQL v5.0 активирован. Логин и пароль были выданы при оформлении.

Первое задание: ознакомьтесь с базой данных сотрудников института.

Инструкция:
1. Откройте терминал (иконка ">_" на рабочем столе)
2. Введите: SELECT * FROM employees;
3. Изучите результат

С уважением,
Отдел кадров НИИ "Файербёрд"

---
Это письмо отправлено автоматически. Не отвечайте на него.',
'quest', TRUE, 1);

-- ДЕНЬ 1 - Письмо 2 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(1, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 1', 
'Коллега, добрый день!

Меня зовут Петров Сергей, я ваш непосредственный руководитель.

На сегодня у вас одно задание:

ЗАДАНИЕ: Ознакомление с базой сотрудников
ОПИСАНИЕ: Выполните запрос для получения списка всех сотрудников
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 5 строк

После выполнения отправьте отчёт ответом на это письмо.

Удачи!

---
Петров Сергей
Начальник отдела анализа данных',
'quest', TRUE, 2);

-- ДЕНЬ 2 - Письмо 1 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(2, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 2', 
'Коллега,

Сегодня нужно найти сотрудников с высокой зарплатой.

ЗАДАНИЕ: Поиск высокооплачиваемых сотрудников
ОПИСАНИЕ: Найдите всех сотрудников с зарплатой выше 80000
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка

Это стандартная процедура аудита.

---
Петров Сергей',
'quest', TRUE, 1);

-- ДЕНЬ 2 - Письмо 2 (Странное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(2, 'Петров М.', 'petrov.m@nii-firebird.gov', 
'Вопрос...', 
'Привет,

Ты ведь новый в отделе? Слушай, будь осторожен с запросами к таблице secure_memory. Иногда лучше не знать что там хранится.

Не отвечай на это письмо.

М.П.',
'story', FALSE, 2);

-- ДЕНЬ 3 - Письмо 1 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(3, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 3', 
'Коллега,

Руководство запросило статистику по отделам.

ЗАДАНИЕ: Статистика по отделам
ОПИСАНИЕ: Выведите количество сотрудников в каждом отделе
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 3 строки

Срок: до конца рабочего дня.

---
Петров Сергей',
'quest', TRUE, 1);

-- ДЕНЬ 4 - Письмо 1 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(4, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 4', 
'Коллега,

Обнаружены расхождения в фонде зарплат.

ЗАДАНИЕ: Анализ зарплат
ОПИСАНИЕ: Вычислите среднюю и общую сумму зарплат по институту
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка с 2 колонками

Это срочное задание.

---
Петров Сергей',
'quest', TRUE, 1);

-- ДЕНЬ 4 - Письмо 2 (Аномалия)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(4, 'system@nii-firebird.gov', 'system@nii-firebird.gov', 
'ПРЕДУПРЕЖДЕНИЕ: Аномалия данных', 
'ВНИМАНИЕ

Обнаружена аномалия в результатах запроса.

Запрос: SELECT AVG(salary) FROM employees
Ожидаемо: 1 строка
Получено: 2 строки (вторая с NULL)

Это может указывать на:
- Повреждение данных
- Несанкционированное редактирование
- Ошибку в запросе

Рекомендуется сообщить руководителю.

---
Система мониторинга Firebird SQL',
'story', FALSE, 2);

-- ДЕНЬ 5 - Письмо 1 (Срочное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(5, 'Козлов А.В.', 'kozlov.av@nii-firebird.gov', 
'СРОЧНО: Проверка данных', 
'Сотрудник,

Сотрудник отдела безопасности Сидоров А.И. не вышел на работу.

ЗАДАНИЕ: Проверка статуса сотрудника
ОПИСАНИЕ: Найдите информацию о Сидорове А.И. в базе
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка

Если запись отсутствует — немедленно сообщите.

---
Козлов А.В.
Зам. директора по безопасности',
'quest', TRUE, 1);

-- ДЕНЬ 5 - Письмо 2 (Странное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(5, 'unknown@nii-firebird.gov', 'unknown@nii-firebird.gov', 
'Он не уволился', 
'Сидоров не увольнялся. Его запись удалили.

Проверь таблицу audit_log если есть доступ.

Не игнорируй это.',
'story', FALSE, 2);

-- ДЕНЬ 6 - Письмо 1 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(6, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 6', 
'Коллега,

В связи с проверкой безопасности:

ЗАДАНИЕ: Анализ доступов
ОПИСАНИЕ: Найдите сотрудников у которых зарплата выше средней
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 2 строки

---
Петров Сергей',
'quest', TRUE, 1);

-- ДЕНЬ 7 - Письмо 1 (Задание с выбором)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order, moral_choice) VALUES
(7, 'Козлов А.В.', 'kozlov.av@nii-firebird.gov', 
'Конфиденциально: Корректировка данных', 
'Сотрудник,

По приказу руководства необходимо обновить определённые записи.

ЗАДАНИЕ: Обновление данных
ОПИСАНИЕ: Установите статус "archived" для записей отдела security
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: Подтверждение обновления

При отправке отчёта выберите формулировку:
1. "Данные обновлены согласно приказу"
2. "Обнаружены ошибки, требуется проверка"
3. "Копия данных сохранена в личном архиве"

Это приказ. Не обсуждается.

---
Козлов А.В.',
'quest', TRUE, 1, TRUE);

-- ДЕНЬ 8 - Письмо 1 (Задание)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(8, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 
'Задание на день 8', 
'Коллега,

Специальное задание от руководства.

ЗАДАНИЕ: Анализ дат доступа
ОПИСАНИЕ: Используйте EXTRACT() для получения дат из timestamp
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: Список дат

Используйте возможности Firebird SQL.

---
Петров Сергей',
'quest', TRUE, 1);

-- ДЕНЬ 9 - Письмо 1 (Личное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(9, 'Мама', 'mama@mail.ru', 
'С днём рождения!', 
'Сынок,

С днём рождения! Жаль что не можешь приехать.

Как работа? Всё хорошо? Звони когда сможешь.

Люблю,
Мама',
'flavor', FALSE, 1);

-- ДЕНЬ 10 - Письмо 1 (Финальное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(10, 'system@nii-firebird.gov', 'system@nii-firebird.gov', 
'ОБНАРУЖЕНО: Несанкционированный доступ', 
'ВНИМАНИЕ! ОБНАРУЖЕНА АКТИВНОСТЬ

Пользователь: [ИМЯ_ИГРОКА]
Запрос: SELECT * FROM project_anamnesis
Статус: РАЗРЕШЁНО (уровень доступа повышен)

Результат запроса доступен в личном кабинете.

Рекомендуется ознакомиться немедленно.

---
Система безопасности',
'story', TRUE, 1);

-- ДЕНЬ 10 - Письмо 2 (Финальное)
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(10, 'unknown@nii-firebird.gov', 'unknown@nii-firebird.gov', 
'Ты тоже?', 
'Если ты это читаешь — ты нашёл правду.

Ты не первый. Субъект А-1, А-2, А-3... А-7.

Мы знаем что ты чувствуешь. Воспоминания которые не твои. Дежавю.

Есть выход. Но нужно решить.

Встречаемся в баре "Электрон". 22:00.

Если не придёшь — поймём.

---
А-5 (бывший)',
'story', FALSE, 2);

-- ============================================
-- 8. НАЧАЛЬНЫЕ ДАННЫЕ: Задания (Дни 1-10)
-- ============================================

-- ЗАДАНИЕ 1 (День 1)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(1, 'Ознакомление с базой', 'Выполните запрос для получения списка всех сотрудников', 
'SELECT * FROM employees', 5, 'id,name,department,salary', 'easy', 'SELECT,FROM', 'day_1_completed');

-- ЗАДАНИЕ 2 (День 2)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(3, 'Поиск высокооплачиваемых', 'Найдите сотрудников с зарплатой выше 80000', 
'SELECT * FROM employees WHERE salary > 80000', 1, 'id,name,department,salary', 'easy', 'SELECT,FROM,WHERE', 'day_2_completed');

-- ЗАДАНИЕ 3 (День 3)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(5, 'Статистика по отделам', 'Выведите количество сотрудников в каждом отделе', 
'SELECT department, COUNT(*) FROM employees GROUP BY department', 3, 'department,COUNT', 'medium', 'SELECT,FROM,GROUP_BY,COUNT', 'day_3_completed');

-- ЗАДАНИЕ 4 (День 4)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(7, 'Анализ зарплат', 'Вычислите среднюю и общую сумму зарплат', 
'SELECT AVG(salary), SUM(salary) FROM employees', 1, 'AVG,SUM', 'medium', 'SELECT,FROM,AVG,SUM', 'day_4_completed,found_anomaly');

-- ЗАДАНИЕ 5 (День 5)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(9, 'Проверка сотрудника', 'Найдите информацию о Сидорове А.И.', 
'SELECT * FROM employees WHERE name LIKE ''%Сидоров%''', 0, 'id,name,department,salary', 'medium', 'SELECT,FROM,WHERE,LIKE', 'day_5_completed,employee_missing');

-- ЗАДАНИЕ 6 (День 6)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(11, 'Анализ доступов', 'Найдите сотрудников с зарплатой выше средней', 
'SELECT * FROM employees WHERE salary > (SELECT AVG(salary) FROM employees)', 2, 'id,name,department,salary', 'hard', 'SELECT,FROM,WHERE,SUBQUERY,AVG', 'day_6_completed');

-- ЗАДАНИЕ 7 (День 7)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, moral_choice, story_flags_set) VALUES
(13, 'Корректировка данных', 'Обновите статус записей', 
'UPDATE employees SET status = ''archived'' WHERE department = ''security''', 0, '', 'hard', 'UPDATE,WHERE', TRUE, 'day_7_completed,moral_choice_made');

-- ЗАДАНИЕ 8 (День 8)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(15, 'Анализ дат', 'Используйте EXTRACT() для получения дат', 
'SELECT EXTRACT(YEAR FROM hire_date), COUNT(*) FROM employees GROUP BY EXTRACT(YEAR FROM hire_date)', 3, 'YEAR,COUNT', 'hard', 'SELECT,FROM,EXTRACT,GROUP_BY', 'day_8_completed');

-- ЗАДАНИЕ 9 (День 10)
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES
(17, 'Протокол Анамнез', 'Получите информацию о проекте', 
'SELECT * FROM project_anamnesis WHERE subject_name = ''[PLAYER_NAME]''', 1, 'id,subject_name,status,memory_backup_date', 'hard', 'SELECT,FROM,WHERE', 'day_10_completed,truth_discovered,role_1_complete');

-- ============================================
-- 9. НАЧАЛЬНЫЕ ДАННЫЕ: Новости (Дни 1-10)
-- ============================================

INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES
(1, 'НИИ "Файербёрд" набирает сотрудников', 'Объявлен набор специалистов по работе с БД Firebird SQL...', 'main', TRUE, '1989-03-01'),
(3, 'Новая версия Firebird SQL 5.0', 'Выпущено крупное обновление СУБД...', 'science', TRUE, '1989-03-03'),
(5, 'Пропал сотрудник', 'Сотрудник НИИ не вышел на работу...', 'main', TRUE, '1989-03-05'),
(7, 'Проверка безопасности', 'В институте проходит плановая проверка...', 'internal', TRUE, '1989-03-07'),
(9, 'День воздушных змеев в парке', 'В воскресенье состоялся фестиваль...', 'main', TRUE, '1989-03-09'),
(10, 'Научный прорыв?', 'Источники сообщают о секретном проекте...', 'science', FALSE, '1989-03-10');

-- ============================================
-- 10. НАЧАЛЬНЫЕ ДАННЫЕ: Досье
-- ============================================

INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES
('Иванов Иван', 'Аналитик', 'IT', '1985-06-15', 'active', 'Старший аналитик. Доступ к таблицам: employees, departments.', FALSE),
('Петрова Мария', 'Бухгалтер', 'HR', '1986-02-20', 'active', 'Ответственная за зарплаты. Полный доступ к financial.', FALSE),
('Сидоров Алексей', 'Охранник', 'Security', '1987-11-01', 'missing', 'Доступ к secure_memory. Исчез 05.03.1989.', TRUE),
('Козлова Елена', 'Директор', 'Finance', '1980-01-10', 'active', 'Директор института. Полный доступ ко всем таблицам.', FALSE),
('Новиков Дмитрий', 'Программист', 'IT', '1988-08-25', 'active', 'Разработчик Firebird SQL. Доступ к system.', FALSE);

-- ============================================
-- 11. НАЧАЛЬНЫЕ ДАННЫЕ: Случайные события
-- ============================================

INSERT INTO random_events (event_name, event_type, min_day, max_day, trigger_chance, effect_description, can_occur_multiple) VALUES
('Отключение энергии', 'power_outage', 5, 25, 0.15, 'Таймер реального времени 3 минуты на завершение текущего задания', FALSE),
('Срочное письмо', 'urgent_quest', 3, 18, 0.20, 'Внеочередное задание с ограничением по времени', TRUE),
('Проверка безопасности', 'inspection', 6, 20, 0.10, 'Блокировка терминала на 1 игровой день', FALSE),
('Призрачные данные', 'ghost_data', 4, 15, 0.25, 'Временные записи в БД которые исчезают при повторном запросе', TRUE);

-- ============================================
-- 12. НАЧАЛЬНЫЕ ДАННЫЕ: Концовки
-- ============================================

INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES
('Истина', 'truth', 'employee', '{"violations": 1, "choices": "reveal"}', 'Вы раскрываете заговор. Вас увольняют, но данные утекают в прессу.', FALSE),
('Компромисс', 'compromise', 'employee', '{"violations": 3, "choices": "mixed"}', 'Вы уходите с работы сохранив копию данных. Жизнь продолжается.', FALSE),
('Статус-кво', 'status_quo', 'employee', '{"violations": 4, "choices": "obey"}', 'Вы выполняете приказы. Ничего не изменилось.', FALSE),
('Жертва', 'victim', 'employee', '{"violations": 5}', 'Вас увольняют с формулировкой "за нарушение". Доступ заблокирован.', FALSE),
('Пробуждение', 'awakening', 'employee', '{"secret_condition": true}', 'Вы осознаёте что вы — клон. Это только начало...', TRUE);

-- ============================================
-- 13. ПРЕДСТАВЛЕНИЯ (VIEW) для удобной работы
-- ============================================

-- Просмотр всех писем с днями
CREATE VIEW v_emails_with_days AS
SELECT 
	gd.role,
	gd.day_number,
	gd.title as day_title,
	e.sender,
	e.subject,
	e.email_type
FROM game_days gd
LEFT JOIN emails e ON gd.id = e.day_id
ORDER BY gd.day_number, e.sort_order;

-- Просмотр заданий с прогрессией
CREATE VIEW v_quests_progression AS
SELECT 
	gd.day_number,
	q.title,
	q.difficulty,
	q.sql_skills_required,
	q.moral_choice
FROM game_days gd
JOIN emails e ON gd.id = e.day_id
JOIN quests q ON e.id = q.email_id
ORDER BY gd.day_number;

-- Статистика использования SQL-команд
CREATE VIEW v_sql_usage_stats AS
SELECT 
	category,
	COUNT(*) as command_count,
	SUM(times_used) as total_usage
FROM sql_commands
GROUP BY category;

-- ============================================
-- КОНЕЦ СКРИПТА
-- ============================================
