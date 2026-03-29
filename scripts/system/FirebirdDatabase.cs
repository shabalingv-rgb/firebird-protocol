using Godot;
using FirebirdSql.Data.FirebirdClient;  // ✅ Правильное пространство
using System;
using System.Collections.Generic;  // Для Dictionary
using System.Threading.Tasks;

public partial class FirebirdDatabase : Node
{
    [Signal]
    public delegate void DatabaseReadyEventHandler();
    
    [Signal]
    public delegate void ContentLoadedEventHandler();
    
    private FbConnection _connection;
    private bool _isConnected = false;
    private bool _isInitialized = false;
    
    // Кэшированные данные
    public List<Dictionary<string, object>> CachedDays { get; private set; } = new();
    public List<Dictionary<string, object>> CachedEmails { get; private set; } = new();
    public List<Dictionary<string, object>> CachedQuests { get; private set; } = new();
    public List<Dictionary<string, object>> CachedNews { get; private set; } = new();
    public List<Dictionary<string, object>> CachedDossiers { get; private set; } = new();
    public List<Dictionary<string, object>> CachedEvents { get; private set; } = new();
    public List<Dictionary<string, object>> CachedEndings { get; private set; } = new();
    
    private string _connectionString;
    
    public override void _Ready()
    {
        GD.Print("🗄️ Firebird Database (C#) загружен");
        InitializeDatabase();
    }
    
    private void InitializeDatabase()
    {
        GD.Print("📋 Инициализация Firebird Embedded...");
        
        // Строка подключения для Embedded
        _connectionString = @"
            User=SYSDBA;
            Password=masterkey;
            Database=/путь/к/game_content.fdb;
            DataSource=localhost;
            ServerType=0;
            Charset=UTF8";
        
        // Для Embedded ServerType=0
        // Database должен указывать на .fdb файл
        
        ConnectDatabase();
    }
    
    private void ConnectDatabase()
    {
        try
        {
            _connection = new FbConnection(_connectionString);
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
        }
    }
    
    private void CreateTables()
    {
        GD.Print("📋 Создание таблиц...");
        
        var tables = new[]
        {
            @"CREATE TABLE IF NOT EXISTS game_days (
                id INTEGER PRIMARY KEY,
                role VARCHAR(20) NOT NULL,
                day_number INTEGER NOT NULL,
                title VARCHAR(100),
                description VARCHAR(500),
                is_playable INTEGER DEFAULT 1,
                alternative_activity VARCHAR(50),
                UNIQUE(role, day_number)
            )",
            
            @"CREATE TABLE IF NOT EXISTS emails (
                id INTEGER PRIMARY KEY,
                day_id INTEGER,
                sender VARCHAR(100) NOT NULL,
                sender_email VARCHAR(100),
                subject VARCHAR(200) NOT NULL,
                body VARCHAR(5000) NOT NULL,
                email_type VARCHAR(20),
                is_required INTEGER DEFAULT 1,
                sort_order INTEGER DEFAULT 0,
                unlock_condition VARCHAR(100)
            )",
            
            // ... остальные таблицы
        };
        
        foreach (var tableSql in tables)
        {
            ExecuteNonQuery(tableSql);
        }
        
        GD.Print("✅ Таблицы созданы");
    }
    
    private void ImportContent()
    {
        GD.Print("📥 Импорт контента...");
        // Здесь парсинг SQL файла и импорт
        // Аналогично тому что было в SQLite версии
        
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
    
    private List<Dictionary<string, object>> ExecuteQuery(string sql)
    {
        var result = new List<Dictionary<string, object>>();
    
        try
        {
            using var command = new FbCommand(sql, _connection);
            using var reader = command.ExecuteReader();
        
            while (reader.Read())
            {
                var row = new Dictionary<string, object>();
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    row[reader.GetName(i)] = reader.GetValue(i);
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
    
    // Методы для GDScript
    public List<Dictionary<string, object>> GetEmailsForDay(int dayId)
    {
        var result = new List<Dictionary<string, object>>();
        foreach (var email in CachedEmails)
        {
            if (email.ContainsKey("day_id") && Convert.ToInt32(email["day_id"]) == dayId)
            {
                result.Add(email);
            }
        }
        return result;
    }
    
    public Dictionary<string, object> GetQuestForEmail(int emailId)
    {
        foreach (var quest in CachedQuests)
        {
            if (quest.ContainsKey("email_id") && Convert.ToInt32(quest["email_id"]) == emailId)
            {
                return quest;
            }
        }
        return new Dictionary<string, object>();
    }
    
    public override void _ExitTree()
    {
        _connection?.Close();
        _connection?.Dispose();
    }
}