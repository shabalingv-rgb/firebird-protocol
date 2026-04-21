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
using SystemDict = System.Collections.Generic.Dictionary<string, object>;


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

	// Методы для получения размера кэша (GDScript не может напрямую читать C# свойства)
	public int GetCachedEmailsCount() => CachedEmails?.Count ?? 0;
	public int GetCachedDaysCount() => CachedDays?.Count ?? 0;
	public int GetCachedQuestsCount() => CachedQuests?.Count ?? 0;

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
			ApplyMigrations();
			ImportContent();


			IsInitialized = true;
			EmitSignal(SignalName.DatabaseReady);
			GD.Print("✅ БД готова к работе");
			
			// Проверка подключения вынесена в отдельную транзакцию
			using (var trans = _connection.BeginTransaction())
			{
				using (var cmd = new FbCommand("SELECT MON$DATABASE_NAME FROM MON$DATABASE", _connection, trans))
				{
					GD.Print("Реальный путь к БД на сервере: " + cmd.ExecuteScalar());
				}
				trans.Commit();
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
			using (var trans = _connection.BeginTransaction())
			{
				using (var cmd = new FbCommand("SELECT COUNT(*) FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = 'PLAYER_PROGRESS'", _connection, trans))
				{
					var count = cmd.ExecuteScalar();
					GD.Print($"Найдено таблиц с таким именем: {count}");
				}
				trans.Commit();
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

	/// <summary>Применяет миграции к существующей БД (добавляет недостающие колонки).</summary>
	private void ApplyMigrations()
	{
		GD.Print("🔄 Применение миграций БД...");

		try
		{
			// Проверяем наличие колонки is_read в таблице emails
			var checkColumn = ExecuteQuery(@"
				SELECT 1 FROM RDB$RELATION_FIELDS 
				WHERE RDB$RELATION_NAME = 'EMAILS' 
				AND RDB$FIELD_NAME = 'IS_READ'
			");

			if (checkColumn == null || checkColumn.Count == 0)
			{
				GD.Print("📝 Миграция: добавляем колонку is_read в emails...");
				ExecuteNonQuery("ALTER TABLE emails ADD is_read SMALLINT DEFAULT 0");
				GD.Print("✅ Колонка is_read добавлена");
			}
			else
			{
				GD.Print("✅ Колонка is_read уже существует");
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"⚠️ Ошибка миграции: {e.Message}");
		}
	}

	private void ImportContent()
	{
		GD.Print("📥 Начало проверки структуры БД...");

		bool needImport = true;
		try
		{
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

		FbTransaction transaction = null;
		try
		{
			transaction = _connection.BeginTransaction();

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

			transaction.Commit();
			GD.Print("✅ База данных успешно инициализирована.");
		}
		catch (Exception ex)
		{
			if (transaction != null)
			{
				try { transaction.Rollback(); } catch { }
			}
			GD.PrintErr($"❌ Ошибка импорта: {ex.Message}");
			return;
		}
		finally
		{
			if (transaction != null)
			{
				try { transaction.Dispose(); } catch { }
			}
		}

		LoadContentToCache();
	}

	/// <summary>Загружает только INSERT-данные из SQL-файла (если таблицы есть, но пусты).</summary>
	private void ImportInitialData()
	{
		string sqlPath = ProjectSettings.GlobalizePath("res://scripts/database/game_content_firebird.sql");
		if (!File.Exists(sqlPath))
		{
			GD.PrintErr("❌ SQL-файл не найден: " + sqlPath);
			return;
		}

		string sqlContent = File.ReadAllText(sqlPath).Replace("\r", "");
		var commands = SplitSqlStatements(SqlLineComments.Replace(sqlContent, ""));

		FbTransaction transaction = null;
		try
		{
			transaction = _connection.BeginTransaction();

			foreach (var cmdText in commands)
			{
				string cleanCmd = cmdText.Trim();
				if (string.IsNullOrWhiteSpace(cleanCmd)) continue;
				if (!cleanCmd.StartsWith("INSERT", StringComparison.OrdinalIgnoreCase)) continue;

				try
				{
					using var fbCmd = new FbCommand(cleanCmd, _connection, transaction);
					fbCmd.ExecuteNonQuery();
				}
				catch (Exception e)
				{
					if (!e.Message.Contains("already exists") && !e.Message.Contains("duplicate"))
						GD.PrintErr($"⚠️ ImportInitialData: {e.Message}");
				}
			}

			transaction.Commit();
			GD.Print("✅ Начальные данные загружены из SQL.");
		}
		catch (Exception ex)
		{
			if (transaction != null)
			{
				try { transaction.Rollback(); } catch { }
			}
			GD.PrintErr($"❌ Ошибка загрузки данных: {ex.Message}");
		}
		finally
		{
			if (transaction != null)
			{
				try { transaction.Dispose(); } catch { }
			}
		}
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

		// Проверяем, пуста ли guide_topics (новые данные могли не загрузиться)
		var guideTopicsCount = ExecuteQuery("SELECT COUNT(*) as cnt FROM guide_topics");
		int guideTopicsRows = 0;
		if (guideTopicsCount != null && guideTopicsCount.Count > 0)
		{
			var firstRow = (GDictionary)guideTopicsCount[0];
			guideTopicsRows = firstRow.ContainsKey("CNT") ? firstRow["CNT"].AsInt32() : 0;
		}
		GD.Print("   📚 Справочных тем: ", guideTopicsRows);

		// Если таблицы есть, но данные пусты — загружаем начальные записи из SQL
		if ((CachedDays?.Count ?? 0) == 0 || (CachedEmails?.Count ?? 0) == 0 || guideTopicsRows == 0)
		{
			GD.Print("⚠️ Таблицы пусты — загружаю начальные данные...");
			ImportInitialData();
			// Перезагружаем кэш после импорта
			CachedDays = ExecuteQuery("SELECT * FROM game_days ORDER BY day_number");
			CachedEmails = ExecuteQuery("SELECT * FROM emails ORDER BY day_id, sort_order");
			CachedQuests = ExecuteQuery("SELECT * FROM quests ORDER BY id");
			GD.Print("   📅 Дней: ", CachedDays?.Count ?? 0);
			GD.Print("   📧 Писем: ", CachedEmails?.Count ?? 0);
			GD.Print("   🎯 Заданий: ", CachedQuests?.Count ?? 0);
		}

		EmitSignal(SignalName.ContentLoaded);
		GD.Print("✅ Кэш загружен");
	}

	/// <summary>Выполнить SELECT из GDScript (терминал). При ошибке возвращает null — смотри GetLastError().</summary>
	public GArray ExecuteQuery(string sql)
	{
		var result = new GArray();

		try
		{
			using var command = new FbCommand(sql, _connection);
			using var reader = command.ExecuteReader();

			while (reader.Read())
			{
				var row = new Godot.Collections.Dictionary<string, Variant>();
				for (int i = 0; i < reader.FieldCount; i++)
				{
					string fieldName = reader.GetName(i);
					object value = reader.GetValue(i);

					// Явная конвертация типов для Godot Variant
					row[fieldName] = ConvertToVariant(value);
				}
				result.Add(row);
			}
		}
		catch (Exception e)
		{
			GD.PrintErr("❌ Ошибка запроса: ", e.Message);
			GD.PrintErr("   SQL: ", sql);
			return null;
		}

		return result;
	}

	/// <summary>Конвертирует объект из БД в Godot Variant</summary>
	private static Variant ConvertToVariant(object value)
	{
		if (value == null || value == DBNull.Value)
			return Variant.CreateFrom("");

		return value switch
		{
			int v => Variant.CreateFrom(v),
			long v => Variant.CreateFrom(v),
			short v => Variant.CreateFrom(v),
			byte v => Variant.CreateFrom(v),
			float v => Variant.CreateFrom(v),
			double v => Variant.CreateFrom(v),
			decimal v => Variant.CreateFrom((double)v),
			string v => Variant.CreateFrom(v),
			bool v => Variant.CreateFrom(v),
			DateTime v => Variant.CreateFrom(v.ToString("yyyy-MM-dd HH:mm:ss")),
			byte[] v => Variant.CreateFrom(System.Convert.ToBase64String(v)),
			_ => Variant.CreateFrom(value.ToString())
		};
	}

	private void ExecuteNonQuery(string sql)
	{
		try
		{
			using var trans = _connection.BeginTransaction();
			using var command = new FbCommand(sql, _connection, trans);
			command.ExecuteNonQuery();
			trans.Commit();
		}
		catch (Exception e)
		{
			GD.PrintErr("❌ Ошибка выполнения: ", e.Message);
		}
	}

	public GArray GetEmailsForDay(int dayId)
	{
		var result = new GArray();
		foreach (var item in CachedEmails)
		{
			GDictionary email = (GDictionary)(Variant)item;
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
		GD.Print($"🔍 GetQuestForEmail({emailId}) вызван");
		GD.Print($"📦 CachedQuests.Count = {CachedQuests.Count}");

		foreach (var questVariant in CachedQuests)
		{
			GDictionary quest = (GDictionary)(Variant)questVariant;

			// ✅ ПРОВЕРКА КЛЮЧА БЕЗ УЧЁТА РЕГИСТРА (как в GetEmailsForDay)
			Variant emailIdValue = default;
			bool found = false;

			if (quest.ContainsKey("EMAIL_ID")) { emailIdValue = quest["EMAIL_ID"]; found = true; }
			else if (quest.ContainsKey("email_id")) { emailIdValue = quest["email_id"]; found = true; }

			if (found)
			{
				int questEmailId = emailIdValue.AsInt32();
				GD.Print($"  📋 Quest EMAIL_ID = {questEmailId}");

				if (questEmailId == emailId)
				{
					GD.Print("✅ Задание найдено!");

					// Возвращаем копию словаря (безопаснее для GDScript)
					var result = new GDictionary();
					foreach (var kvp in quest)
					{
						result[kvp.Key] = kvp.Value;
					}
					return result;
				}
			}
		}

		GD.Print($"❌ Задание НЕ найдено для email_id={emailId}");
		return new GDictionary();
	}

	// === БРАУЗЕР: Загрузка доступных сайтов ===
	public GArray GetAvailableSites(int dayId)
	{
		GD.Print($"🌐 GetAvailableSites({dayId}) вызван");
		
		var sites = new GArray();
		
		// Новости — всегда доступны с дня 1
		var news = new GDictionary();
		news["id"] = "news";
		news["name"] = "📰 Новости НИИ";
		news["icon"] = "res://assets/icons/news.png";
		news["min_day"] = 1;
		sites.Add(news);
		
		// Википедия — всегда доступна
		var wiki = new GDictionary();
		wiki["id"] = "wiki";
		wiki["name"] = "📚 Википедия";
		wiki["icon"] = "res://assets/icons/wiki.png";
		wiki["min_day"] = 1;
		sites.Add(wiki);
		
		// Доска объявлений — с дня 3
		if (dayId >= 3)
		{
			var board = new GDictionary();
			board["id"] = "board";
			board["name"] = "📌 Доска объявлений";
			board["icon"] = "res://assets/icons/board.png";
			board["min_day"] = 3;
			sites.Add(board);
		}
		
		// Юмор — с дня 5
		if (dayId >= 5)
		{
			var humor = new GDictionary();
			humor["id"] = "humor";
			humor["name"] = "😄 Юмор";
			humor["icon"] = "res://assets/icons/humor.png";
			humor["min_day"] = 5;
			sites.Add(humor);
		}
		
		GD.Print($"📊 Найдено сайтов: {sites.Count}");
		return sites;
	}

	// === БРАУЗЕР: Загрузка статей для сайта ===
	public GArray GetArticlesForSite(string siteId, int dayId)
	{
		GD.Print($"📰 GetArticlesForSite({siteId}, {dayId}) вызван");
		
		var articles = new GArray();
		
		try
		{
			string sql;
			
			if (siteId == "wiki")
			{
				// Wiki-статьи: постоянные + разблокированные
				sql = $@"
					SELECT id, title, content, author, is_permanent
					FROM news_articles 
					WHERE category = 'wiki' 
					AND (is_permanent = 1 OR day_id <= {dayId})
					ORDER BY title";
			}
			else
			{
				// Обычные статьи: только доступные по дню
				sql = $@"
					SELECT id, title, content, author, day_id
					FROM news_articles 
					WHERE category = '{siteId}' 
					AND day_id <= {dayId}
					ORDER BY day_id DESC";
			}
			
			var result = ExecuteQuery(sql);
			
			foreach (var article in result)
			{
				articles.Add(article);
			}
			
			GD.Print($"📊 Найдено статей: {articles.Count}");
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка загрузки статей: {e.Message}");
		}
		
		return articles;
	}

	// === БРАУЗЕР: Получить конкретную статью ===
	public GDictionary GetArticleById(int articleId)
	{
		var result = ExecuteQuery($"SELECT * FROM news_articles WHERE id = {articleId}");
		
		if (result.Count > 0)
		{
			return (GDictionary)result[0];
		}
		
		return new GDictionary();
	}

	public GDictionary LoadPlayerProgress(int saveSlot = 1)
	{
		var result = ExecuteQuery($"SELECT * FROM player_progress WHERE save_slot = {saveSlot}");

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
			fallbackProgress["unlock_conditions"] = "{}";
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
		defaultProgress["unlock_conditions"] = "{}";
		defaultProgress["endings_unlocked"] = "[]";
		defaultProgress["total_playtime_minutes"] = 0;

		return defaultProgress;
	}

	public void SavePlayerProgress(string role, int day, int violations, Variant flagsVariant, Variant questsVariant)
	{
		SavePlayerProgressWithUnlocks(role, day, violations, flagsVariant, questsVariant, null);
	}

	public void SavePlayerProgressWithUnlocks(string role, int day, int violations, Variant flagsVariant, Variant questsVariant, Variant? unlockConditionsVariant)
	{
		try
		{
			string flagsJson = flagsVariant.VariantType == Variant.Type.String
				? flagsVariant.AsString()
				: System.Text.Json.JsonSerializer.Serialize(flagsVariant.AsGodotDictionary());

			string questsJson = questsVariant.VariantType == Variant.Type.String
				? questsVariant.AsString()
				: System.Text.Json.JsonSerializer.Serialize(questsVariant.AsGodotArray());

			string unlocksJson = "{}";
			if (unlockConditionsVariant != null && unlockConditionsVariant.Value.VariantType != Variant.Type.Nil)
			{
				unlocksJson = unlockConditionsVariant.Value.VariantType == Variant.Type.String
					? unlockConditionsVariant.Value.AsString()
					: System.Text.Json.JsonSerializer.Serialize(unlockConditionsVariant.Value.AsGodotDictionary());
			}
			const int saveSlot = 1;

			// Firebird не поддерживает ON CONFLICT — используем параметры (безопасно для кавычек в JSON) и UPDATE/INSERT
			const string updateSql = @"
				UPDATE player_progress SET
					user_role = @role,
					current_day = @day,
					violations = @violations,
					flags_unlocked = @flagsJson,
					quests_completed = @questsJson,
					unlock_conditions = @unlocksJson,
					last_saved = CURRENT_TIMESTAMP
				WHERE save_slot = @saveSlot";

			using (var cmd = new FbCommand(updateSql, _connection))
			{
				cmd.Parameters.Add("@role", FbDbType.VarChar).Value = role ?? "";
				cmd.Parameters.Add("@day", FbDbType.Integer).Value = day;
				cmd.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
				cmd.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
				cmd.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
				cmd.Parameters.Add("@unlocksJson", FbDbType.VarChar).Value = unlocksJson ?? "{}";
				cmd.Parameters.Add("@saveSlot", FbDbType.Integer).Value = saveSlot;
				int updated = cmd.ExecuteNonQuery();
				if (updated == 0)
				{
					const string insertSql = @"
						INSERT INTO player_progress (save_slot, user_role, current_day, violations, flags_unlocked, quests_completed, unlock_conditions, last_saved)
						VALUES (@saveSlot, @role, @day, @violations, @flagsJson, @questsJson, @unlocksJson, CURRENT_TIMESTAMP)";
					using var ins = new FbCommand(insertSql, _connection);
					ins.Parameters.Add("@saveSlot", FbDbType.Integer).Value = saveSlot;
					ins.Parameters.Add("@role", FbDbType.VarChar).Value = role ?? "";
					ins.Parameters.Add("@day", FbDbType.Integer).Value = day;
					ins.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
					ins.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
					ins.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
					ins.Parameters.Add("@unlocksJson", FbDbType.VarChar).Value = unlocksJson ?? "{}";
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

	// === СОХРАНЕНИЯ: Создать новое сохранение ===
	public bool CreateSaveSlot(int saveSlot)
	{
		if (saveSlot < 1)
		{
			GD.PrintErr("❌ CreateSaveSlot: номер слота должен быть >= 1");
			return false;
		}

		try
		{
			// Проверяем существует ли слот
			using (var cmd = new FbCommand("SELECT COUNT(*) as cnt FROM player_progress WHERE save_slot = @slot", _connection))
			{
				cmd.Parameters.Add("@slot", FbDbType.Integer).Value = saveSlot;
				using var reader = cmd.ExecuteReader();
				if (reader.Read())
				{
					int count = Convert.ToInt32(reader.GetValue(0));
					if (count > 0)
					{
						GD.Print($"💾 Слот {saveSlot} уже существует");
						return false;
					}
				}
			}

			// Создаём пустое сохранение
			using (var cmd = new FbCommand(@"
				INSERT INTO player_progress (save_slot, user_role, current_day, violations, trust_level, last_saved)
				VALUES (@slot, 'employee', 1, 0, 50, CURRENT_TIMESTAMP)
			", _connection))
			{
				cmd.Parameters.Add("@slot", FbDbType.Integer).Value = saveSlot;
				cmd.ExecuteNonQuery();
			}

			GD.Print($"✅ Слот сохранения {saveSlot} создан");
			return true;
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка создания слота: {e.Message}");
			return false;
		}
	}

	// === СОХРАНЕНИЯ: Получить список всех слотов ===
	public GArray GetSaveSlotsList()
	{
		var slots = new GArray();

		try
		{
			var result = ExecuteQuery(@"
				SELECT save_slot, user_role, current_day, violations, trust_level,
				       total_playtime_minutes, last_saved
				FROM player_progress
				ORDER BY save_slot
			");

			if (result != null)
			{
				foreach (var slotVariant in result)
				{
					var slot = (GDictionary)(Variant)slotVariant;
					slots.Add(slot);
				}
			}

			GD.Print($"📊 Найдено слотов сохранений: {slots.Count}");
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка получения слотов: {e.Message}");
		}

		return slots;
	}

	// === СОХРАНЕНИЯ: Удалить сохранение ===
	public bool DeleteSaveSlot(int saveSlot)
	{
		if (saveSlot < 1)
		{
			GD.PrintErr("❌ DeleteSaveSlot: номер слота должен быть >= 1");
			return false;
		}

		FbTransaction transaction = null;
		try
		{
			transaction = _connection.BeginTransaction();

			// Удаляем прогресс
			using (var cmd = new FbCommand("DELETE FROM player_progress WHERE save_slot = @slot", _connection, transaction))
			{
				cmd.Parameters.Add("@slot", FbDbType.Integer).Value = saveSlot;
				cmd.ExecuteNonQuery();
			}

			// player_choices не имеет колонки save_slot — оставляем историю выборов
			// (при необходимости можно добавить миграцию позже)

			transaction.Commit();
			GD.Print($"🗑️ Слот {saveSlot} удалён");
			return true;
		}
		catch (Exception e)
		{
			transaction?.Rollback();
			GD.PrintErr($"❌ Ошибка удаления слота: {e.Message}");
			return false;
		}
		finally
		{
			transaction?.Dispose();
		}
	}

	// === СОХРАНЕНИЯ: Сохранить текущее состояние игры ===
	public void AutoSave(int saveSlot, int currentDay, int violations, int trustLevel,
						 GDictionary flags, GArray completedQuests, int playtimeMinutes)
	{
		// Автосохранение использует слот 0, что допустимо
		if (saveSlot < 0)
		{
			GD.PrintErr("❌ AutoSave: номер слота должен быть >= 1");
			return; 
		}

		try
		{
			string flagsJson = System.Text.Json.JsonSerializer.Serialize(flags);
			string questsJson = System.Text.Json.JsonSerializer.Serialize(completedQuests);

			const string updateSql = @"
				UPDATE player_progress SET
					current_day = @day,
					violations = @violations,
					trust_level = @trust,
					flags_unlocked = @flagsJson,
					quests_completed = @questsJson,
					total_playtime_minutes = @playtime,
					last_saved = CURRENT_TIMESTAMP
				WHERE save_slot = @slot";

			using (var cmd = new FbCommand(updateSql, _connection))
			{
				cmd.Parameters.Add("@day", FbDbType.Integer).Value = currentDay;
				cmd.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
				cmd.Parameters.Add("@trust", FbDbType.Integer).Value = trustLevel;
				cmd.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
				cmd.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
				cmd.Parameters.Add("@playtime", FbDbType.Integer).Value = playtimeMinutes;
				cmd.Parameters.Add("@slot", FbDbType.Integer).Value = saveSlot;

				int updated = cmd.ExecuteNonQuery();
				if (updated == 0)
				{
					// Слот не найден — создаём
					const string insertSql = @"
						INSERT INTO player_progress (save_slot, user_role, current_day, violations, trust_level, flags_unlocked, quests_completed, total_playtime_minutes, last_saved)
						VALUES (@slot, 'employee', @day, @violations, @trust, @flagsJson, @questsJson, @playtime, CURRENT_TIMESTAMP)";
					using var ins = new FbCommand(insertSql, _connection);
					ins.Parameters.Add("@slot", FbDbType.Integer).Value = saveSlot;
					ins.Parameters.Add("@day", FbDbType.Integer).Value = currentDay;
					ins.Parameters.Add("@violations", FbDbType.Integer).Value = violations;
					ins.Parameters.Add("@trust", FbDbType.Integer).Value = trustLevel;
					ins.Parameters.Add("@flagsJson", FbDbType.VarChar).Value = flagsJson ?? "{}";
					ins.Parameters.Add("@questsJson", FbDbType.VarChar).Value = questsJson ?? "[]";
					ins.Parameters.Add("@playtime", FbDbType.Integer).Value = playtimeMinutes;
					ins.ExecuteNonQuery();
					GD.Print($"✅ Авто-сохранение: слот {saveSlot} создан, день {currentDay}, время {playtimeMinutes} мин");
				}
				else
				{
					GD.Print($"💾 Авто-сохранение: слот {saveSlot}, день {currentDay}, время {playtimeMinutes} мин");
				}
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка авто-сохранения: {e.Message}");
		}
	}

	// === СОХРАНЕНИЯ: Загрузить историю выборов ===
	public GArray GetPlayerChoices(int saveSlot)
	{
		var choices = new GArray();

		if (saveSlot < 1)
		{
			GD.PrintErr("❌ GetPlayerChoices: номер слота должен быть >= 1");
			return choices;
		}

		try
		{
			// player_choices не имеет колонки save_slot — возвращаем все выборы
			using var cmd = new FbCommand(@"
				SELECT quest_id, choice_type, choice_value, day_id, choice_timestamp
				FROM player_choices
				ORDER BY choice_timestamp
			", _connection);

			using var reader = cmd.ExecuteReader();
			while (reader.Read())
			{
				var choice = new GDictionary();
				choice["quest_id"] = ConvertToVariant(reader.GetValue(0));
				choice["choice_type"] = ConvertToVariant(reader.GetValue(1));
				choice["choice_value"] = ConvertToVariant(reader.GetValue(2));
				choice["day_id"] = ConvertToVariant(reader.GetValue(3));
				choice["choice_timestamp"] = ConvertToVariant(reader.GetValue(4));
				choices.Add(choice);
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка загрузки выборов: {e.Message}");
		}

		return choices;
	}

	// === СОХРАНЕНИЯ: Получить статистику ===
	public GDictionary GetGameStatistics(int saveSlot)
	{
		var stats = new GDictionary();

		if (saveSlot < 1)
		{
			GD.PrintErr("❌ GetGameStatistics: номер слота должен быть >= 1");
			return stats;
		}

		try
		{
			// Общая статистика прогресса
			var progress = ExecuteQuery($"SELECT * FROM player_progress WHERE save_slot = {saveSlot}");
			if (progress != null && progress.Count > 0)
			{
				stats["progress"] = progress[0];
			}

			// Количество выполненных заданий (парсим JSON из quests_completed)
			var progressData = ExecuteQuery($"SELECT quests_completed FROM player_progress WHERE save_slot = {saveSlot}");
			int questsCount = 0;
			if (progressData != null && progressData.Count > 0)
			{
				var row = (GDictionary)progressData[0];
				Variant questsVal = row.ContainsKey("QUESTS_COMPLETED") ? row["QUESTS_COMPLETED"] : row["quests_completed"];
				if (questsVal.VariantType == Variant.Type.String)
				{
					string questsJson = questsVal.AsString();
					if (!string.IsNullOrEmpty(questsJson) && questsJson != "[]")
					{
						var questIds = System.Text.Json.JsonSerializer.Deserialize<GArray>(questsJson);
						if (questIds != null)
							questsCount = questIds.Count;
					}
				}
			}
			stats["quests_completed_count"] = Variant.From(questsCount);

			// Использованные SQL команды
			var sqlStats = ExecuteQuery(@"
				SELECT command_name, times_used
				FROM sql_commands
				WHERE times_used > 0
				ORDER BY times_used DESC
			");
			stats["sql_usage"] = sqlStats ?? new GArray();

			// Всего писем прочитано
			var emailsRead = ExecuteQuery("SELECT COUNT(DISTINCT id) as cnt FROM emails WHERE is_read = 1");
			stats["emails_read"] = (emailsRead != null && emailsRead.Count > 0) ? ((GDictionary)emailsRead[0])["CNT"] : Variant.From(0);

			GD.Print("📊 Статистика загружена");
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка загрузки статистики: {e.Message}");
		}

		return stats;
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

	// === Пометить письмо прочитанным (БД + кэш) ===
	public void MarkEmailAsRead(int emailId)
	{
		GD.Print($"📧 MarkEmailAsRead({emailId})");

		try
		{
			// Обновляем в БД
			ExecuteNonQuery($"UPDATE emails SET is_read = 1 WHERE id = {emailId}");

			// Обновляем в кэше
			foreach (var item in CachedEmails)
			{
				GDictionary email = (GDictionary)(Variant)item;
				int id = -1;
				if (email.ContainsKey("ID")) id = email["ID"].AsInt32();
				else if (email.ContainsKey("id")) id = email["id"].AsInt32();

				if (id == emailId)
				{
					email["IS_READ"] = Variant.From(1);
					email["is_read"] = Variant.From(1);
					GD.Print($"  📬 Письмо #{emailId} помечено прочитанным в кэше");
					break;
				}
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка пометки письма: {e.Message}");
		}
	}

	public void LogPlayerQuery(string sql, int dayId)
	{
		try
		{
			const string insertSql = @"
				INSERT INTO player_query_log (query_text, day_id, executed_at)
				VALUES (@queryText, @dayId, CURRENT_TIMESTAMP)";

			using var cmd = new FbCommand(insertSql, _connection);
			cmd.Parameters.Add("@queryText", FbDbType.VarChar).Value = sql ?? "";
			cmd.Parameters.Add("@dayId", FbDbType.Integer).Value = dayId;
			cmd.ExecuteNonQuery();
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка логирования запроса: {e.Message}");
		}
	}

	public Dictionary GetRandomEventForDay(int day)
	{
		var result = ExecuteQuery($"SELECT * FROM random_events WHERE min_day <= {day} AND max_day >= {day}");

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

	// === СПРАВКА: Загрузка всех доступных тем ===
	public GArray GetAvailableGuideTopics(int dayId)
	{
		GD.Print($"📚 GetAvailableGuideTopics(day={dayId})");

		var topics = new GArray();

		try
		{
			string sql = $"SELECT id, topic_key, title, content, sql_example, category, sort_order, min_day, max_day " +
				$"FROM guide_topics " +
				$"WHERE min_day <= {dayId} AND max_day >= {dayId} " +
				$"ORDER BY sort_order, title";

			var result = ExecuteQuery(sql);
			if (result != null)
			{
				foreach (var item in result)
				{
					GDictionary row = (GDictionary)(Variant)item;
					var topic = new GDictionary();
					topic["id"] = row.ContainsKey("ID") ? row["ID"] : Variant.From(0);
					topic["topic_key"] = row.ContainsKey("TOPIC_KEY") ? row["TOPIC_KEY"] : Variant.From("");
					topic["title"] = row.ContainsKey("TITLE") ? row["TITLE"] : Variant.From("");
					topic["content"] = row.ContainsKey("CONTENT") ? row["CONTENT"] : Variant.From("");
					topic["sql_example"] = row.ContainsKey("SQL_EXAMPLE") ? row["SQL_EXAMPLE"] : Variant.From("");
					topic["category"] = row.ContainsKey("CATEGORY") ? row["CATEGORY"] : Variant.From("");
					topic["sort_order"] = row.ContainsKey("SORT_ORDER") ? row["SORT_ORDER"] : Variant.From(0);
					topic["min_day"] = row.ContainsKey("MIN_DAY") ? row["MIN_DAY"] : Variant.From(1);
					topic["max_day"] = row.ContainsKey("MAX_DAY") ? row["MAX_DAY"] : Variant.From(999);
					topics.Add(topic);
				}
			}

			GD.Print($"📊 Найдено тем: {topics.Count}");
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка загрузки тем: {e.Message}");
		}

		return topics;
	}

	// === СПРАВКА: Получить тему по ключу ===
	public GDictionary GetGuideTopicByKey(string topicKey)
	{
		GD.Print($"📖 GetGuideTopicByKey({topicKey})");
		
		var result = new GArray();
		
		try
		{
			using var cmd = new FbCommand(@"
				SELECT id, topic_key, title, content, sql_example, category
				FROM guide_topics 
				WHERE topic_key = @topicKey
			", _connection);
			
			cmd.Parameters.Add("@topicKey", FbDbType.VarChar).Value = topicKey ?? "";
			
			using var reader = cmd.ExecuteReader();
			
			while (reader.Read())
			{
				var topic = new GDictionary();
				topic["id"] = Variant.From(reader.GetValue(0));
				topic["topic_key"] = Variant.From(reader.GetValue(1));
				topic["title"] = Variant.From(reader.GetValue(2));
				topic["content"] = Variant.From(reader.GetValue(3));
				topic["sql_example"] = Variant.From(reader.GetValue(4));
				topic["category"] = Variant.From(reader.GetValue(5));
				result.Add(topic);
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка загрузки темы: {e.Message}");
		}
		
		if (result.Count > 0)
		{
			return (GDictionary)result[0];
		}
		
		return new GDictionary();
	}

	// === СПРАВКА: Поиск тем по ключевому слову ===
	public GArray SearchGuideTopics(string searchTerm)
	{
		GD.Print($"🔍 SearchGuideTopics({searchTerm})");
		
		var topics = new GArray();
		
		try
		{
			string sql = @"
				SELECT id, topic_key, title, content, category
				FROM guide_topics 
				WHERE title LIKE @search 
				   OR content LIKE @search 
				   OR topic_key LIKE @search
				ORDER BY title
			";
			
			using var cmd = new FbCommand(sql, _connection);
			cmd.Parameters.Add("@search", FbDbType.VarChar).Value = $"%{searchTerm}%";
			
			using var reader = cmd.ExecuteReader();
			
			while (reader.Read())
			{
				var topic = new GDictionary();
				topic["id"] = Variant.From(reader.GetValue(0));
				topic["topic_key"] = Variant.From(reader.GetValue(1));
				topic["title"] = Variant.From(reader.GetValue(2));
				topic["content"] = Variant.From(reader.GetValue(3));
				topic["category"] = Variant.From(reader.GetValue(4));
				topics.Add(topic);
			}
			
			GD.Print($"📊 Найдено тем: {topics.Count}");
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка поиска: {e.Message}");
		}
		
		return topics;
	}

	// === СПРАВКА: Получить структуру таблицы ===
	public GArray GetTableStructure(string tableName)
	{
		GD.Print($"🏗️ GetTableStructure({tableName})");

		var columns = new GArray();

		if (string.IsNullOrWhiteSpace(tableName))
		{
			GD.PrintErr("❌ GetTableStructure: имя таблицы не указано");
			return columns;
		}

		try
		{
			string safeName = tableName.Trim().ToUpper().Replace("'", "''");
			string sql =
				"SELECT " +
				"TRIM(rf.RDB$FIELD_NAME) as FIELD_NAME, " +
				"rf.RDB$FIELD_POSITION as FIELD_POSITION, " +
				"f.RDB$FIELD_TYPE as FIELD_TYPE, " +
				"f.RDB$FIELD_SUB_TYPE as FIELD_SUB_TYPE, " +
				"f.RDB$FIELD_LENGTH as FIELD_LENGTH, " +
				"rf.RDB$NULL_FLAG as NULL_FLAG " +
				"FROM RDB$RELATION_FIELDS rf " +
				"LEFT JOIN RDB$FIELDS f ON TRIM(rf.RDB$FIELD_SOURCE) = TRIM(f.RDB$FIELD_NAME) " +
				"WHERE rf.RDB$RELATION_NAME = '" + safeName + "' " +
				"ORDER BY rf.RDB$FIELD_POSITION";

			GD.Print($"🔍 SQL запрос структуры: {sql}");

			var result = ExecuteQuery(sql);
			if (result != null)
			{
				GD.Print($"📊 Найдено колонок: {result.Count}");
				foreach (var item in result)
				{
					GDictionary row = (GDictionary)item;
					var col = new GDictionary();

					var colName = row.ContainsKey("FIELD_NAME") ? row["FIELD_NAME"] : Variant.From("");
					var colType = row.ContainsKey("FIELD_TYPE") ? row["FIELD_TYPE"] : Variant.From(0);
					var colLength = row.ContainsKey("FIELD_LENGTH") ? row["FIELD_LENGTH"] : Variant.From(0);
					var colNull = row.ContainsKey("NULL_FLAG") ? row["NULL_FLAG"] : Variant.From(0);

					GD.Print($"  Колонка: [{colName}] Тип: [{colType}] Длина: [{colLength}] NULL_FLAG: [{colNull}]");

					col["COLUMN_NAME"] = colName;
					col["FIELD_TYPE"] = colType;
					col["FIELD_LENGTH"] = colLength;

					int nullFlag = colNull.AsInt32();
					col["NULLABLE"] = Variant.From(nullFlag == 1 ? "NO" : "YES");

					columns.Add(col);
				}
			}
			else
			{
				GD.PrintErr("⚠️ ExecuteQuery вернул null");
			}
		}
		catch (Exception e)
		{
			GD.PrintErr($"❌ Ошибка получения структуры: {e.Message}");
		}

		return columns;
	}

	public override void _ExitTree()
	{
		_connection?.Close();
		_connection?.Dispose();
	}


}
