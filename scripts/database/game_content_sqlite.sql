-- ============================================
-- FIREBIRD PROTOCOL - GAME CONTENT DATABASE
-- Версия: SQLite 3.x (для Godot 4.x)
-- Дата: 2026-03-26
-- ============================================

-- ============================================
-- SQL-КОМАНДЫ ДЛЯ ОТСЛЕЖИВАНИЯ
-- ============================================

INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('SELECT', 'basics', 0, 1, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('FROM', 'basics', 0, 1, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('WHERE', 'filtering', 0, 1, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('ORDER BY', 'filtering', 0, 2, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('GROUP BY', 'aggregates', 0, 3, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('HAVING', 'filtering', 0, 4, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('COUNT', 'aggregates', 0, 3, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('SUM', 'aggregates', 0, 4, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('AVG', 'aggregates', 0, 4, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('MIN', 'aggregates', 0, 4, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('MAX', 'aggregates', 0, 4, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('JOIN', 'advanced', 0, 5, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('INNER JOIN', 'advanced', 0, 5, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('LEFT JOIN', 'advanced', 0, 6, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('SUBQUERY', 'advanced', 0, 6, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('UNION', 'advanced', 0, 7, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('INTERSECT', 'advanced', 0, 7, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('EXCEPT', 'advanced', 0, 7, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('CASE WHEN', 'advanced', 0, 7, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('DISTINCT', 'filtering', 0, 2, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('LIKE', 'filtering', 0, 2, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('BETWEEN', 'filtering', 0, 2, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('IN', 'filtering', 0, 2, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('LIST()', 'aggregates', 1, 8, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('EXTRACT()', 'functions', 1, 8, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('CAST()', 'functions', 1, 9, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('COALESCE()', 'functions', 1, 9, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('NULLIF()', 'functions', 1, 9, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('SUBSTRING()', 'functions', 1, 9, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('UPDATE', 'modification', 0, 11, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('INSERT', 'modification', 0, 11, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('DELETE', 'modification', 0, 12, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('MERGE', 'modification', 0, 11, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('TRANSACTION', 'advanced', 1, 13, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('COMMIT', 'advanced', 1, 13, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('ROLLBACK', 'advanced', 1, 13, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('TRIGGER', 'advanced', 1, 14, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('PROCEDURE', 'advanced', 1, 14, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('GENERATOR', 'advanced', 1, 15, 0);
INSERT INTO sql_commands (command_name, category, firebird_specific, introduced_day, times_used) VALUES ('SEQUENCE', 'advanced', 1, 15, 0);

-- ============================================
-- ДНИ 1-10 (СОТРУДНИК)
-- ============================================

INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 1, 'Первый день', 'Добро пожаловать в НИИ "Файербёрд". Сегодня ваш первый рабочий день.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 2, 'Странности', 'Коллеги ведут себя подозрительно. Вам поручают необычные задания.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 3, 'Статистика', 'Руководство запрашивает отчёт по отделам. Обратите внимание на аномалии.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 4, 'Аномалия', 'В данных обнаружены несоответствия. Кто-то редактировал записи.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 5, 'Исчезновение', 'Сотрудник отдела безопасности исчез. Его запись удалена из базы.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 6, 'Проверка', 'Служба безопасности проводит проверку всех доступов.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 7, 'Выбор', 'Вам приказывают скрыть определённые данные. Что вы решите?', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 8, 'Особый', 'Специальное задание от руководства. Используйте возможности Firebird.', 1, NULL);
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 9, 'Выходной', 'У вас выходной день. Отдохните от работы.', 0, 'bar');
INSERT INTO game_days (role, day_number, title, description, is_playable, alternative_activity) VALUES ('employee', 10, 'Осознание', 'Вы находите информацию, которая меняет всё.', 1, NULL);

-- ============================================
-- ПИСЬМА (ДНИ 1-10)
-- ============================================

INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (1, 'Отдел кадров', 'hr@nii-firebird.gov', 'Добро пожаловать в НИИ "Файербёрд"', 'Уважаемый сотрудник!

Поздравляем с первым рабочим днём в Научно-Исследовательском Институте "Файербёрд".

Ваш доступ к системе Firebird SQL v5.0 активирован.

Первое задание: ознакомьтесь с базой данных сотрудников института.

С уважением,
Отдел кадров НИИ "Файербёрд"', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (1, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 1', 'Коллега, добрый день!

Меня зовут Петров Сергей, я ваш непосредственный руководитель.

На сегодня у вас одно задание:

ЗАДАНИЕ: Ознакомление с базой сотрудников
ОПИСАНИЕ: Выполните запрос для получения списка всех сотрудников
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 5 строк

После выполнения отправьте отчёт ответом на это письмо.

Удачи!

---
Петров Сергей
Начальник отдела анализа данных', 'quest', 1, 2);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (2, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 2', 'Коллега,

Сегодня нужно найти сотрудников с высокой зарплатой.

ЗАДАНИЕ: Поиск высокооплачиваемых сотрудников
ОПИСАНИЕ: Найдите всех сотрудников с зарплатой выше 80000
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка

Это стандартная процедура аудита.

---
Петров Сергей', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (2, 'Петров М.', 'petrov.m@nii-firebird.gov', 'Вопрос...', 'Привет,

Ты ведь новый в отделе? Слушай, будь осторожен с запросами к таблице secure_memory. Иногда лучше не знать что там хранится.

Не отвечай на это письмо.

М.П.', 'story', 0, 2);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (3, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 3', 'Коллега,

Руководство запросило статистику по отделам.

ЗАДАНИЕ: Статистика по отделам
ОПИСАНИЕ: Выведите количество сотрудников в каждом отделе
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 3 строки

Срок: до конца рабочего дня.

---
Петров Сергей', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (4, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 4', 'Коллега,

Обнаружены расхождения в фонде зарплат.

ЗАДАНИЕ: Анализ зарплат
ОПИСАНИЕ: Вычислите среднюю и общую сумму зарплат по институту
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка с 2 колонками

Это срочное задание.

---
Петров Сергей', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (4, 'system@nii-firebird.gov', 'system@nii-firebird.gov', 'ПРЕДУПРЕЖДЕНИЕ: Аномалия данных', 'ВНИМАНИЕ

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
Система мониторинга Firebird SQL', 'story', 0, 2);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (5, 'Козлов А.В.', 'kozlov.av@nii-firebird.gov', 'СРОЧНО: Проверка данных', 'Сотрудник,

Сотрудник отдела безопасности Сидоров А.И. не вышел на работу.

ЗАДАНИЕ: Проверка статуса сотрудника
ОПИСАНИЕ: Найдите информацию о Сидорове А.И. в базе
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 1 строка

Если запись отсутствует — немедленно сообщите.

---
Козлов А.В.
Зам. директора по безопасности', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (5, 'unknown@nii-firebird.gov', 'unknown@nii-firebird.gov', 'Он не уволился', 'Сидоров не увольнялся. Его запись удалили.

Проверь таблицу audit_log если есть доступ.

Не игнорируй это.', 'story', 0, 2);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (6, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 6', 'Коллега,

В связи с проверкой безопасности:

ЗАДАНИЕ: Анализ доступов
ОПИСАНИЕ: Найдите сотрудников у которых зарплата выше средней
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 2 строки

---
Петров Сергей', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (7, 'Козлов А.В.', 'kozlov.av@nii-firebird.gov', 'Конфиденциально: Корректировка данных', 'Сотрудник,

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
Козлов А.В.', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (8, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Задание на день 8', 'Коллега,

Специальное задание от руководства.

ЗАДАНИЕ: Анализ дат доступа
ОПИСАНИЕ: Используйте EXTRACT() для получения дат из timestamp
ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: Список дат

Используйте возможности Firebird SQL.

---
Петров Сергей', 'quest', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (9, 'Мама', 'mama@mail.ru', 'С днём рождения!', 'Сынок,

С днём рождения! Жаль что не можешь приехать.

Как работа? Всё хорошо? Звони когда сможешь.

Люблю,
Мама', 'flavor', 0, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (10, 'system@nii-firebird.gov', 'system@nii-firebird.gov', 'ОБНАРУЖЕНО: Несанкционированный доступ', 'ВНИМАНИЕ! ОБНАРУЖЕНА АКТИВНОСТЬ

Пользователь: [ИМЯ_ИГРОКА]
Запрос: SELECT * FROM project_anamnesis
Статус: РАЗРЕШЁНО (уровень доступа повышен)

Результат запроса доступен в личном кабинете.

Рекомендуется ознакомиться немедленно.

---
Система безопасности', 'story', 1, 1);
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES (10, 'unknown@nii-firebird.gov', 'unknown@nii-firebird.gov', 'Ты тоже?', 'Если ты это читаешь — ты нашёл правду.

Ты не первый. Субъект А-1, А-2, А-3... А-7.

Мы знаем что ты чувствуешь. Воспоминания которые не твои. Дежавю.

Есть выход. Но нужно решить.

Встречаемся в баре "Электрон". 22:00.

Если не придёшь — поймём.

---
А-5 (бывший)', 'story', 0, 2);

-- ============================================
-- ЗАДАНИЯ (ДНИ 1-10)
-- ============================================

INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (1, 'Ознакомление с базой', 'Выполните запрос для получения списка всех сотрудников', 'SELECT * FROM employees', 5, 'id,name,department,salary', 'easy', 'SELECT,FROM', 'day_1_completed');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (3, 'Поиск высокооплачиваемых', 'Найдите сотрудников с зарплатой выше 80000', 'SELECT * FROM employees WHERE salary > 80000', 1, 'id,name,department,salary', 'easy', 'SELECT,FROM,WHERE', 'day_2_completed');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (5, 'Статистика по отделам', 'Выведите количество сотрудников в каждом отделе', 'SELECT department, COUNT(*) FROM employees GROUP BY department', 3, 'department,COUNT', 'medium', 'SELECT,FROM,GROUP_BY,COUNT', 'day_3_completed');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (7, 'Анализ зарплат', 'Вычислите среднюю и общую сумму зарплат', 'SELECT AVG(salary), SUM(salary) FROM employees', 1, 'AVG,SUM', 'medium', 'SELECT,FROM,AVG,SUM', 'day_4_completed,found_anomaly');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (9, 'Проверка сотрудника', 'Найдите информацию о Сидорове А.И.', 'SELECT * FROM employees WHERE name LIKE ''%Сидоров%''', 0, 'id,name,department,salary', 'medium', 'SELECT,FROM,WHERE,LIKE', 'day_5_completed,employee_missing');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (11, 'Анализ доступов', 'Найдите сотрудников с зарплатой выше средней', 'SELECT * FROM employees WHERE salary > (SELECT AVG(salary) FROM employees)', 2, 'id,name,department,salary', 'hard', 'SELECT,FROM,WHERE,SUBQUERY,AVG', 'day_6_completed');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, moral_choice, story_flags_set) VALUES (13, 'Корректировка данных', 'Обновите статус записей', 'UPDATE employees SET status = ''archived'' WHERE department = ''security''', 0, '', 'hard', 'UPDATE,WHERE', 1, 'day_7_completed,moral_choice_made');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (15, 'Анализ дат', 'Используйте EXTRACT() для получения дат', 'SELECT EXTRACT(YEAR FROM hire_date), COUNT(*) FROM employees GROUP BY EXTRACT(YEAR FROM hire_date)', 3, 'YEAR,COUNT', 'hard', 'SELECT,FROM,EXTRACT,GROUP_BY', 'day_8_completed');
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required, story_flags_set) VALUES (17, 'Протокол Анамнез', 'Получите информацию о проекте', 'SELECT * FROM project_anamnesis WHERE subject_name = ''[PLAYER_NAME]''', 1, 'id,subject_name,status,memory_backup_date', 'hard', 'SELECT,FROM,WHERE', 'day_10_completed,truth_discovered,role_1_complete');

-- ============================================
-- НОВОСТИ
-- ============================================

INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (1, 'НИИ "Файербёрд" набирает сотрудников', 'Объявлен набор специалистов по работе с БД Firebird SQL...', 'main', 1, '1989-03-01');
INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (3, 'Новая версия Firebird SQL 5.0', 'Выпущено крупное обновление СУБД...', 'science', 1, '1989-03-03');
INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (5, 'Пропал сотрудник', 'Сотрудник НИИ не вышел на работу...', 'main', 1, '1989-03-05');
INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (7, 'Проверка безопасности', 'В институте проходит плановая проверка...', 'internal', 1, '1989-03-07');
INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (9, 'День воздушных змеев в парке', 'В воскресенье состоялся фестиваль...', 'main', 1, '1989-03-09');
INSERT INTO news_articles (day_id, title, content, category, is_visible, publish_date) VALUES (10, 'Научный прорыв?', 'Источники сообщают о секретном проекте...', 'science', 0, '1989-03-10');

-- ============================================
-- ДОСЬЕ СОТРУДНИКОВ
-- ============================================

INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES ('Иванов Иван', 'Аналитик', 'IT', '1985-06-15', 'active', 'Старший аналитик. Доступ к таблицам: employees, departments.', 0);
INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES ('Петрова Мария', 'Бухгалтер', 'HR', '1986-02-20', 'active', 'Ответственная за зарплаты. Полный доступ к financial.', 0);
INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES ('Сидоров Алексей', 'Охранник', 'Security', '1987-11-01', 'missing', 'Доступ к secure_memory. Исчез 05.03.1989.', 1);
INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES ('Козлова Елена', 'Директор', 'Finance', '1980-01-10', 'active', 'Директор института. Полный доступ ко всем таблицам.', 0);
INSERT INTO employee_dossiers (employee_name, position, department, hire_date, status, dossier_text, is_mysterious) VALUES ('Новиков Дмитрий', 'Программист', 'IT', '1988-08-25', 'active', 'Разработчик Firebird SQL. Доступ к system.', 0);

-- ============================================
-- СЛУЧАЙНЫЕ СОБЫТИЯ
-- ============================================

INSERT INTO random_events (event_name, event_type, min_day, max_day, trigger_chance, effect_description, can_occur_multiple) VALUES ('Отключение энергии', 'power_outage', 5, 25, 0.15, 'Таймер реального времени 3 минуты на завершение текущего задания', 0);
INSERT INTO random_events (event_name, event_type, min_day, max_day, trigger_chance, effect_description, can_occur_multiple) VALUES ('Срочное письмо', 'urgent_quest', 3, 18, 0.20, 'Внеочередное задание с ограничением по времени', 1);
INSERT INTO random_events (event_name, event_type, min_day, max_day, trigger_chance, effect_description, can_occur_multiple) VALUES ('Проверка безопасности', 'inspection', 6, 20, 0.10, 'Блокировка терминала на 1 игровой день', 0);
INSERT INTO random_events (event_name, event_type, min_day, max_day, trigger_chance, effect_description, can_occur_multiple) VALUES ('Призрачные данные', 'ghost_data', 4, 15, 0.25, 'Временные записи в БД которые исчезают при повторном запросе', 1);

-- ============================================
-- КОНЦОВКИ
-- ============================================

INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES ('Истина', 'truth', 'employee', '{"violations": 1, "choices": "reveal"}', 'Вы раскрываете заговор. Вас увольняют, но данные утекают в прессу.', 0);
INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES ('Компромисс', 'compromise', 'employee', '{"violations": 3, "choices": "mixed"}', 'Вы уходите с работы сохранив копию данных. Жизнь продолжается.', 0);
INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES ('Статус-кво', 'status_quo', 'employee', '{"violations": 4, "choices": "obey"}', 'Вы выполняете приказы. Ничего не изменилось.', 0);
INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES ('Жертва', 'victim', 'employee', '{"violations": 5}', 'Вас увольняют с формулировкой "за нарушение". Доступ заблокирован.', 0);
INSERT INTO endings (ending_name, ending_type, role_required, conditions_required, description, is_secret) VALUES ('Пробуждение', 'awakening', 'employee', '{"secret_condition": true}', 'Вы осознаёте что вы — клон. Это только начало...', 1);

-- ============================================
-- КОНЕЦ ФАЙЛА
-- ============================================