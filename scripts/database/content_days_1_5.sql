-- ДЕНЬ 1: Ознакомление
-- Письма
INSERT INTO emails (day_id, sender, sender_email, subject, body, email_type, is_required, sort_order) VALUES
(1, 'Отдел кадров', 'hr@nii-firebird.gov', 'Добро пожаловать', 'Уважаемый сотрудник!\n\nПоздравляем с первым рабочим днём в НИИ "Файербёрд".\n\nВаш доступ к системе активирован. Начните с ознакомления с базой данных сотрудников.\n\nС уважением,\nОтдел кадров', 'quest', 1, 1),

(1, 'Иванов П.С.', 'ivanov@nii-firebird.gov', 'Ваше рабочее место', 'Коллега, добро пожаловать!\n\nВаш терминал настроен. Пароль для входа: firebird1989\n\nЕсли возникнут вопросы — обращайтесь.\n\nП.С. Иванов', 'info', 0, 2);

-- Задания
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required) VALUES
(1, 'Первый запрос', 'Получите список всех сотрудников', 'SELECT * FROM employees', 5, 'id,name,department,salary', 'easy', 'SELECT,FROM'),
(1, 'Фильтрация', 'Найдите сотрудников из отдела IT', 'SELECT * FROM employees WHERE department = ''IT''', 2, 'id,name,department', 'easy', 'SELECT,FROM,WHERE');

-- Новости
INSERT INTO news_articles (day_id, category, title, content, author, is_permanent) VALUES
(1, 'news', 'Планёрка', 'Сегодня в 9:00 состоится общая планёрка. Явка обязательна.', 'Администрация', false),
(1, 'wiki', 'Основы SQL', 'SELECT — выборка данных\nFROM — источник данных\nWHERE — условие фильтрации', 'Справочная', true);

-- ДЕНЬ 2-5: (аналогично, добавляй больше контента)
-- ...