using FirebirdSql.Data.FirebirdClient;
using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using System.IO;
using System.Threading.Tasks.Dataflow;
using GDictionary = Godot.Collections.Dictionary;
using GArray = Godot.Collections.Array;
using Microsoft.VisualBasic;


public partial class FirebirdDatabase : Node
{
    [Signal]
    public delegate void DatabaseReadyEventHandler();
    
    [Signal]
    public delegate void ContentLoadedEventHandler();
    
    private FbConnection _connection;
    private string _database;
    private bool _isConnected = false;
    private bool _isInitialized = false;
    
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
        GD.Print("📋 Инициализация Firebird Embedded...");
        
        // Получаем абсолютный путь к БД
        string dbPath = ProjectSettings.GlobalizePath("res://game_content.fdb");
        //string libPath = "/Library/Frameworks/Firebird.framework/Versions/A/Libraries/libfbclient.dylib";
        
        // Пробуем разнве варианты строки подключения
        GD.Print("📂 Путь к БД: ", dbPath);

        //Вариант 1: Простая строка (попробуем сначала)
        _database = $"Database=localhost:{dbPath};User=SYSDBA;Password=masterkey;ServerType=0;Dialect=3;";


        GD.Print("🔑 Строка подключения: ", _database);

        // Проверяем что файл существует
        if (!File.Exists(dbPath))
        {
            GD.PrintErr("❌ Файл БД не найден: ", dbPath);
            return;
        }
        
        GD.Print("✅ Файл БД найден, подключаемся...");
        ConnectDatabase();
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
            
            _isInitialized = true;
            EmitSignal(SignalName.DatabaseReady);
            GD.Print("✅ БД готова к работе");
        }
        catch (Exception e)
        {
            GD.PrintErr("❌ Ошибка подключения: ", e.Message);
            GD.PrintErr("Stack: ", e.StackTrace);
            GD.PrintErr("Inner Exception: ", e.InnerException?.Message);
        }
    }
    
    private void CreateTables()
    {
        // Запрос к системному каталогу Firebird, что бы проверить наличие таблицы GAME_DAYS
        var check = ExecuteQuery("SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = 'GAME_DAYS'");

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
        GD.Print("📥 Проверка контента...");
        
        var checkResult = ExecuteQuery("SELECT COUNT(*) AS \"cnt\" FROM game_days");
        if (checkResult.Count > 0 && checkResult[0]["cnt"].AsInt32() > 0)
        {
            GD.Print("✅ Данные уже существуют: ", checkResult[0]["cnt"], " записей");
            LoadContentToCache();
            return;
        }
        
        string sqlPath = ProjectSettings.GlobalizePath("res://scripts/database/game_content_firebird.sql");
        if (File.Exists(sqlPath))
        {
            string sqlContent = File.ReadAllText(sqlPath);
            string[] commands = sqlContent.Split(new[] { ";\n", ";\r\n" }, StringSplitOptions.RemoveEmptyEntries);
            
            int successCount = 0;
            int errorCount = 0;
            
            foreach (var command in commands)
            {
                if (command.Trim().Length > 0 && !command.Trim().StartsWith("--"))
                {
                    try
                    {
                        ExecuteNonQuery(command);
                        successCount++;
                    }
                    catch (Exception e)
                    {
                        errorCount++;
                        GD.PrintErr("⚠️ Ошибка: ", e.Message);
                    }
                }
            }
            
            GD.Print("✅ Импорт завершён: ", successCount, " успешно, ", errorCount, " ошибок");
        }
        else
        {
            GD.PrintErr("❌ SQL файл не найден: ", sqlPath);
        }
        
        LoadContentToCache();
    }
    
    private void LoadContentToCache()
    {
        GD.Print("📦 Загрузка в кэш...");
        
        CachedDays = ExecuteQuery("SELECT * FROM game_days ORDER BY day_number");
        GD.Print("   📅 Дней: ", CachedDays.Count);
        
        CachedEmails = ExecuteQuery("SELECT * FROM emails ORDER BY day_id, sort_order");
        GD.Print("   📧 Писем: ", CachedEmails.Count);
        
        CachedQuests = ExecuteQuery("SELECT * FROM quests ORDER BY id");
        GD.Print("   🎯 Заданий: ", CachedQuests.Count);
        
        EmitSignal(SignalName.ContentLoaded);
        GD.Print("✅ Кэш загружен");
    }
    
    private List<Dictionary> ExecuteQuery(string sql)
    {
        var result = new List<Dictionary>();
        
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
            GD.PrintErr("❌ Ошибка запроса: ", e.Message);
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
        var result = new GArray();

        foreach (var email in CachedEmails)
        {
            if (email.ContainsKey("day_id") && email["day_id"].AsInt32() == dayId)
            {
                result.Add(email);
            }
        }
        return result;
    }
    
    public Dictionary GetQuestForEmail(int emailId)
    {
        foreach (var quest in CachedQuests)
        {
            if (quest.ContainsKey("email_id") && Convert.ToInt32(quest["email_id"]) == emailId)
            {
                return quest;
            }
        }
        return new Dictionary();
    }
    
    public GDictionary LoadPlayerProgress(int saveSlot = 1)
    {
        var result = ExecuteQuery($"SELECT * FROM player_progress WHERE save_slot = {saveSlot}");
        
        if (result.Count > 0)
        {
            var progress = result[0];
            GD.Print("💾 Прогресс загружен: день=", progress.ContainsKey("current_day") ? progress["current_day"] : "1");
            return progress;
        }
        
        GD.Print("💾 Прогресс по умолчанию");
        return new GDictionary
        {
            { "save_slot", saveSlot },
            { "player_role", "employee" },
            { "current_day", 1 },
            { "violations", 0 },
            { "trust_level", 50 },
            { "flags_unlocked", "{}" },
            { "quests_completed", "[]" },
            { "endings_unlocked", "[]" },
            { "total_playtime_minutes", 0 }
        };
    }
    
    public void SavePlayerProgress(string role, int day, int violations, Dictionary flags, Dictionary quests)
    {
        try
        {
            string flagsJson = System.Text.Json.JsonSerializer.Serialize(flags);
            string questsJson = System.Text.Json.JsonSerializer.Serialize(quests);
            
            string sql = $@"
                INSERT INTO player_progress (save_slot, user_role, current_day, violations, flags_unlocked, quests_completed, last_saved)
                VALUES (1, '{role}', {day}, {violations}, '{flagsJson}', '{questsJson}', CURRENT_TIMESTAMP)
                ON CONFLICT (save_slot) DO UPDATE SET
                    user_role = '{role}',
                    current_day = {day},
                    violations = {violations},
                    flags_unlocked = '{flagsJson}',
                    quests_completed = '{questsJson}',
                    last_saved = CURRENT_TIMESTAMP";
            
            ExecuteNonQuery(sql);
            GD.Print("💾 Прогресс сохранён: день=", day);
        }
        catch (Exception e)
        {
            GD.PrintErr("❌ Ошибка сохранения: ", e.Message);
        }
    }
    
    public void TrackSqlUsage(string commandName, int day)
    {
        try
        {
            string sql = $@"
                UPDATE sql_commands 
                SET times_used = times_used + 1, last_used_day = {day}
                WHERE command_name = '{commandName}'";
            
            ExecuteNonQuery(sql);
        }
        catch (Exception)
        {
        }
    }
    
    public Dictionary GetRandomEventForDay(int day)
    {
        var result = ExecuteQuery($"SELECT * FROM random_events WHERE min_day <= {day} AND max_day >= {day}");
        
        if (result.Count > 0)
        {
            var rand = new Random();
            int index = rand.Next(result.Count);
            return result[index];
        }
        
        return new Dictionary();
    }
    
    public override void _ExitTree()
    {
        _connection?.Close();
        _connection?.Dispose();
    }
}