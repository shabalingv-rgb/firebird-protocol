using FirebirdSql.Data.FirebirdClient;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Godot;
using Godot.Collections;
using GDictionary = Godot.Collections.Dictionary;
using GArray = Godot.Collections.Array;


public partial class FirebirdDatabase : Node
{
	// Один раз компилируем шаблон — при повторных вызовах инициализации не тратим время на разбор regex
	private static readonly Regex SqlLineComments = new(@"--[^\r\n]*", RegexOptions.Compiled);

	[Signal]
	public delegate void DatabaseReadyEventHandler();

	[Signal]
	public delegate void ContentLoadedEventHandler();

	private FbConnection _connection;
	private string _database;
	private bool _isConnected = false;
	public bool IsInitialized { get; private set; } = false;

	private string _lastError = "";

	public string GetLastError() => _lastError; // Метод для GDScript

	public GArray CachedDays { get; private set; } = new();
	public GArray CachedEmails { get; private set; } = new();
	public GArray CachedQuests { get; private set; } = new();
	public GArray CachedNews { get; private set; } = new();
	public GArray CachedDossiers { get; private set; } = new();
	public GArray CachedEvents { get; private set; } = new();
	public GArray CachedEndings { get; private set; } = new();

	public override void _Ready()
	{
		GD.Print("🗄️ Firebird Database (C#) загружен");
		InitializeDatabase();
	}

	private void InitializeDatabase()
	{
		GD.Print("📋 Инициализация Firebird...");

		string dbPath = ProjectSettings.GlobalizePath("res://game_content.fdb");
		_database = $"Database=localhost:{dbPath};User=SYSDBA;Password=masterkey;ServerType=0;Dialect=3;";

		if (!File.Exists(dbPath))
		{
			GD.Print("🛠 База не найдена, создаю новую...");
			try
			{
				// 1. Создаем пустой файл базы
				FbConnection.CreateDatabase(_database);
				GD.Print("✅ Файл базы создан.");
				// 2. Читаем SQL-скрипт
				string sqlPath = "res://scripts/database/game_content_firebird.sql";
				if (!Godot.FileAccess.FileExists(sqlPath))
				{
					GD.PrintErr("❌ SQL-скрипт не найден по пути: " + sqlPath);
					return;
				}

				using var sqlFile = Godot.FileAccess.Open(sqlPath, Godot.FileAccess.ModeFlags.Read);
				string fullSql = sqlFile.GetAsText();

				// 3. Очищаем SQL от комментариев и разбиваем на команды
				string cleanSql = SqlLineComments.Replace(fullSql, "");
				var allCommands = SplitSqlStatements(cleanSql);
				using (var connection = new FbConnection(_database))
				{
					connection.Open();

					// ЭТАП А: Создание таблиц (DDL)
					using (var trans = connection.BeginTransaction())
					{
						foreach (var cmdText in allCommands)
						{
							if (cmdText.StartsWith("CREATE", StringComparison.OrdinalIgnoreCase))
							{
								using var cmd = new FbCommand(cmdText, connection, trans);
								cmd.ExecuteNonQuery();
							}
						}
						trans.Commit();
						GD.Print("✅ Структура таблиц создана.");
					}
					// ЭТАП Б: Загрузка данных (DML)
					using (var trans = connection.BeginTransaction())
					{
						foreach (var cmdText in allCommands)
						{
							if (cmdText.StartsWith("INSERT", StringComparison.OrdinalIgnoreCase))
							{
								using var cmd = new FbCommand(cmdText, connection, trans);
								cmd.ExecuteNonQuery();
							}
						}
						trans.Commit();
						GD.Print("✅ Начальные данные загружены.");
					}
				}
			}
			catch (Exception ex)
			{
				GD.PrintErr($"❌ Критическая ошибка при инициализации: {ex.Message}");
			}
		}

		GD.Print("🔌 Подключение к базе...");
		ConnectDatabase();
	}

	/// <summary>Разбивает скрипт на отдельные команды (как при первичной инициализации, так при импорте).</summary>
	private static List<string> SplitSqlStatements(string sql)
	{
		return sql.Split(';', StringSplitOptions.RemoveEmptyEntries)
			.Select(c => c.Trim())
			.Where(c => !string.IsNullOrWhiteSpace(c))
			.ToList();
	}

	private void ConnectDatabase()
	{
		try
		{
			GD.Print("🔌 Попытка подключения...");
			GD.Print("🔑 Connection string: ", _database);
			GD.Print($"Попытка подключения: {_database}");

			// Создаем путь к временной папке внутри проекта
			string tempPath = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "fb_temp");

			// Создаем папку, если её нет
			if (!System.IO.Directory.Exists(tempPath))
			{
				System.IO.Directory.CreateDirectory(tempPath);
			}

			// Указываем Firebird использовать эту папку для локов
			//System.Environment.SetEnvironmentVariable("FIREBIRD_LOCK", tempPath);
			//System.Environment.SetEnvironmentVariable("FIREBIRD_TMP", tempPath);

			GD.Print($"Установлена временная папка Firebird: {tempPath}");

			_connection = new FbConnection(_database);
			_connection.Open();
			_isConnected = true;

			GD.Print("✅ Подключение к Firebird успешно");

			CreateTables();
			ImportContent();

			IsInitialized = true;
			EmitSignal(SignalName.DatabaseReady);
			GD.Print("✅ БД готова к работе");
			using (var cmd = new FbCommand("SELECT MON$DATABASE_NAME FROM MON$DATABASE", _connection))

			{
				GD.Print("Реальный путь к БД на сервере: " + cmd.ExecuteScalar());

			}



		}
		catch (Exception e)
		{
			GD.PrintErr("❌ Ошибка подключения: ", e.Message);
			GD.PrintErr("Stack: ", e.StackTrace);
			GD.PrintErr("Inner Exception: ", e.InnerException?.Message);
		}

		if (_isConnected && _connection != null)
		{
			using (var cmd = new FbCommand("SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = 'PLAYER_PROGRESS'", _connection))
			{
				var count = cmd.ExecuteScalar();
				GD.Print($"Найдено таблиц с таким именем: {count}");
			}
		}
	}

	private void CreateTables()
	{
		// Запрос к системному каталогу Firebird, что бы проверить наличие таблицы GAME_DAYS
		var check = ExecuteQuery("SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = 'GAME_DAYS'");

		if (check == null)
		{
			GD.PrintErr("❌ CreateTables: ошибка выполнения запроса, результат null");
			GD.Print("🛠 Нужно создать структуру таблиц...");
			return;
		}

		if (check.Count == 0)
		{
			GD.Print("🛠 Нужно создать структуру таблиц...");

		}
		else
		{
			GD.Print("📋 Таблицы уже созданы в БД");
		}

	}

	private void ImportContent()
	{
		GD.Print("📥 Начало проверки структуры БД...");

		bool needImport = true;
		try
		{
			// Ищем именно ТВОЮ таблицу. В Firebird системные имена всегда ВЕРХНИМ РЕГИСТРОМ
			using var cmdCheck = new FbCommand(
				"SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = 'PLAYER_PROGRESS'",
				_connection);

			var result = cmdCheck.ExecuteScalar();
			if (result != null && result != DBNull.Value)
			{
				needImport = false;
			}
		}
		catch { needImport = true; }

		if (!needImport)
		{
			GD.Print("✅ Игровые таблицы найдены.");
			LoadContentToCache();
			return;
		}

		GD.Print("🛠 Игровые таблицы не найдены. Начинаю импорт...");

		string sqlPath = ProjectSettings.GlobalizePath("res://scripts/database/game_content_firebird.sql");
		if (!File.Exists(sqlPath))
		{
			GD.PrintErr("❌ SQL не найден: " + sqlPath);
			return;
		}

		string sqlContent = File.ReadAllText(sqlPath).Replace("\r", "");
		var commands = SplitSqlStatements(SqlLineComments.Replace(sqlContent, ""));

		using (var transaction = _connection.BeginTransaction())
		{
			foreach (var cmdText in commands)
			{
				string cleanCmd = cmdText.Trim();
				if (string.IsNullOrWhiteSpace(cleanCmd)) continue;

				try
				{
					using var fbCmd = new FbCommand(cleanCmd, _connection, transaction);
					fbCmd.ExecuteNonQuery();

				}
				catch (Exception e)
				{
					if (!e.Message.Contains("already exists"))
						GD.PrintErr($"⚠️ SQL Detail: {e.Message}");
				}
			}
			// 2. Коммитим ВНУТРИ блока using, пока переменная transaction жива
			transaction.Commit();
		}
		GD.Print("✅ База данных успешно инициализирована.");
		LoadContentToCache();
	}




	private void LoadContentToCache()
	{
		GD.Print("📦 Загрузка в кэш...");

		CachedDays = ExecuteQuery("SELECT * FROM game_days ORDER BY day_number");
		GD.Print("   📅 Дней: ", CachedDays?.Count ?? 0);

		CachedEmails = ExecuteQuery("SELECT * FROM emails ORDER BY day_id, sort_order");
		GD.Print("   📧 Писем: ", CachedEmails?.Count ?? 0);

		CachedQuests = ExecuteQuery("SELECT * FROM quests ORDER BY id");
		GD.Print("   🎯 Заданий: ", CachedQuests?.Count ?? 0);

		EmitSignal(SignalName.ContentLoaded);
		GD.Print("✅ Кэш загружен");
	}

	/// <summary>Выполнить SELECT из GDScript (терминал). При ошибке возвращает null — смотри GetLastError().</summary>
	public GArray ExecuteQuery(string sql)
	{
		_lastError = ""; // Сбрасываем ошибку перед новым запросом
		var result = new GArray();

		try
		{
			using var command = new FbCommand(sql, _connection);
			using var reader = command.ExecuteReader();

			while (reader.Read())
			{
				var row = new GDictionary();
				for (int i = 0; i < reader.FieldCount; i++)
				{
					object val = reader.GetValue(i);
					string name = reader.GetName(i);

					if (val == null || val == DBNull.Value)
					{
						row[name] = new Variant();
					}
					else if (val is DateTime dt)
					{
						// Godot любит строки или метри времени для дат 
						row[name] = dt.ToString("yyyy-MM-dd HH:mm:ss");
					}
					else if (val is int || val is long || val is short)
					{
						row[name] = Convert.ToInt64(val);
					}
					else if (val is float || val is double || val is decimal)
					{
						row[name] = Convert.ToDouble(val);
					}
					else
					{
						// Для всего остального используем ToStrinf()
						row[name] = val.ToString();
					}

				}
				result.Add(row);
			}
		}
		catch (Exception e)
		{
			_lastError = e.Message; // Запоминаем текст ошибки от irebird
			GD.PrintErr($"❌ Ошибка SQL: {e.Message}");
			return null; // озвращаем null как признак ошибки
		}

		return result;
	}

	private void ExecuteNonQuery(string sql)
	{
		try
		{
			using var command = new FbCommand(sql, _connection);
			command.ExecuteNonQuery();
		}
		catch (Exception e)
		{
			GD.PrintErr("❌ Ошибка выполнения: ", e.Message);
		}
	}

	public GArray GetEmailsForDay(int dayId)
	{
		GD.Print($"GetEmailsForDay({dayId}) вызван");
		GD.Print($"CachedEmails.Count = {CachedEmails?.Count ?? 0}");
		var result = new GArray();
		foreach (var item in CachedEmails)
		{
			GDictionary email = (GDictionary)item;
			int emailDayId = -1;
			if (email.ContainsKey("DAY_ID")) emailDayId = email["DAY_ID"].AsInt32();
			else if (email.ContainsKey("day_id")) emailDayId = email["day_id"].AsInt32();

			if (emailDayId == dayId)
			{
				result.Add(email);
			}

		}
		return result;
	}

	public GDictionary GetQuestForEmail(int emailId)
	{
		foreach (var item in CachedQuests)
		{
			GDictionary quest = (GDictionary)item;
			if (quest.ContainsKey("email_id") && quest["email_id"].AsInt32() == emailId)
				return quest;

		}
		return new GDictionary();
	}

	public GDictionary LoadPlayerProgress(int saveSlot = 1)
	{
		GArray result = ExecuteQuery($"SELECT * FROM player_progress WHERE save_slot = {saveSlot}");

		if (result == null)
		{
			GD.PrintErr("❌ LoadPlayerProgress: ошибка выполнения запроса, результат null");
			GD.Print("💾 Прогресс по умолчанию (из-за ошибки БД)");
			GDictionary fallbackProgress = new GDictionary();
			fallbackProgress["save_slot"] = saveSlot;
			fallbackProgress["player_role"] = "employee";
			fallbackProgress["current_day"] = 1;
			fallbackProgress["violations"] = 0;
			fallbackProgress["trust_level"] = 50;
			fallbackProgress["flags_unlocked"] = "{}";
			fallbackProgress["quests_completed"] = "[]";
			fallbackProgress["endings_unlocked"] = "[]";
			fallbackProgress["total_playtime_minutes"] = 0;
			return fallbackProgress;
		}

		if (result.Count > 0)
		{
			GDictionary progressData = (GDictionary)result[0];
			string day = progressData.ContainsKey("current_day")
				? progressData["current_day"].ToString()
				: "1";

			GD.Print($"💾 Прогресс загружен: день={day}");

			return progressData;
		}

		GD.Print("💾 Прогресс по умолчанию");
		GDictionary defaultProgress = new GDictionary();
		defaultProgress["save_slot"] = saveSlot;
		defaultProgress["player_role"] = "employee";
		defaultProgress["current_day"] = 1;
		defaultProgress["violations"] = 0;
		defaultProgress["trust_level"] = 50;
		defaultProgress["flags_unlocked"] = "{}";
		defaultProgress["quests_completed"] = "[]";
		defaultProgress["endings_unlocked"] = "[]";
		defaultProgress["total_playtime_minutes"] = 0;

		return defaultProgress;
	}

	public void SavePlayerProgress(string role, int day, int violations, Dictionary flags, Dictionary quests)
	{
		try
		{
			string flagsJson = System.Text.Json.JsonSerializer.Serialize(flags);
			string questsJson = System.Text.Json.JsonSerializer.Serialize(quests);
			const int saveSlot = 1;

			// Firebird не поддерживает ON CONFLICT — используем параметры (безопасно для кавычек в JSON) и UPDATE/INSERT
			const string updateSql = @"
				UPDATE player_progress SET
					user_role = @role,
					current_day = @day,
					violations = @violations,
					flags_unlocked = @flagsJson,
					quests_completed = @questsJson,
					last_saved = CURRENT_TIMESTAMP
				WHERE save_slot = @saveSlot";

			using (var cmd = new FbCommand(updateSql, _connection))
			{
				cmd.Parameters.Add("@role", FbDbType.VarChar).Value = role ?? "";
				cmd.Parameters.Add("@day", FbDbType.Integer).Value = day;
				cmd.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
				cmd.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
				cmd.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
				cmd.Parameters.Add("@saveSlot", FbDbType.Integer).Value = saveSlot;
				int updated = cmd.ExecuteNonQuery();
				if (updated == 0)
				{
					const string insertSql = @"
						INSERT INTO player_progress (save_slot, user_role, current_day, violations, flags_unlocked, quests_completed, last_saved)
						VALUES (@saveSlot, @role, @day, @violations, @flagsJson, @questsJson, CURRENT_TIMESTAMP)";
					using var ins = new FbCommand(insertSql, _connection);
					ins.Parameters.Add("@saveSlot", FbDbType.Integer).Value = saveSlot;
					ins.Parameters.Add("@role", FbDbType.VarChar).Value = role ?? "";
					ins.Parameters.Add("@day", FbDbType.Integer).Value = day;
					ins.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
					ins.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
					ins.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
					ins.ExecuteNonQuery();
				}
			}

			GD.Print("💾 Прогресс сохранён: день=", day);
		}
		catch (Exception e)
		{
			GD.PrintErr("❌ Ошибка сохранения: ", e.Message);
		}
	}

	/// <summary>Сохранить выбор игрока (отчёт из почты и т.д.).</summary>
	public void SavePlayerChoice(int questId, string choiceType, string choiceValue, int dayId)
	{
		if (_connection == null || !_isConnected)
		{
			GD.PrintErr("SavePlayerChoice: нет подключения к БД");
			return;
		}
		try
		{
			const string sql = @"
				INSERT INTO player_choices (quest_id, choice_type, choice_value, day_id)
				VALUES (@q, @ct, @cv, @d)";
			using var cmd = new FbCommand(sql, _connection);
			cmd.Parameters.Add("@q", FbDbType.Integer).Value = questId;
			cmd.Parameters.Add("@ct", FbDbType.VarChar).Value = choiceType ?? "";
			cmd.Parameters.Add("@cv", FbDbType.VarChar).Value = choiceValue ?? "";
			cmd.Parameters.Add("@d", FbDbType.Integer).Value = dayId;
			cmd.ExecuteNonQuery();
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ SavePlayerChoice: {e.Message}");
		}
	}

	public void TrackSqlUsage(string commandName, int day)
	{
		if (string.IsNullOrWhiteSpace(commandName)) return;

		try
		{
			// 1. Приводим к верхнему регистру, как в SQL-стандарте
			string cmd = commandName.Trim().ToUpper();

			string sqlAdvanced = $@"
                EXECUTE BLOCK AS BEGIN
                    IF (EXISTS (SELECT 1 FROM sql_commands WHERE command_name = '{cmd}')) THEN 
                        UPDATE sql_commands
                        SET times_used = times_used + 1, last_used_day = {day}
                        WHERE command_name = '{cmd}';
                    ELSE 
                        INSERT INTO sql_commands (command_name, times_used, last_used_day)
                        VALUES ('{cmd}', 1, {day});
				END";

			ExecuteNonQuery(sqlAdvanced);

		}
		catch (Exception e)
		{
			// Хоть мы и не прерываем игру, в логах ошибку лучше видеть
			GD.PrintErr($"📊 Ошибка трекинга SQL: {e.Message}");
		}
	}

	public Dictionary GetRandomEventForDay(int day)
	{
		GArray result = ExecuteQuery($"SELECT * FROM random_events WHERE min_day <= {day} AND max_day >= {day}");

		if (result == null)
		{
			GD.PrintErr("❌ GetRandomEventForDay: ошибка выполнения запроса, результат null");
			return new GDictionary();
		}

		if (result.Count > 0)
		{
			var rand = new Random();
			int index = rand.Next(result.Count);
			return (GDictionary)result[index];
		}

		return new GDictionary();
	}

	public override void _ExitTree()
	{
		_connection?.Close();
		_connection?.Dispose();
	}
}
