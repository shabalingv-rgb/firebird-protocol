-- Добавляем задание для письма ID=1
INSERT INTO quests (email_id, title, description, sql_template, expected_rows, expected_columns, difficulty, sql_skills_required) 
VALUES (1, 'Первый запрос', 'Получите список всех сотрудников', 'SELECT * FROM employees', 5, 'id,name,department,salary', 'easy', 'SELECT,FROM');

COMMIT;