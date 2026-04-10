# Godot 4.x: Вызов C# методов из GDScript

## Краткая справка

### Именование методов (Naming Convention)

Godot автоматически конвертирует имена между C# и GDScript:

| C# (PascalCase) | GDScript (snake_case) |
|---|---|
| `ExecuteQuery` | `execute_query` |
| `GetEmailsForDay` | `get_emails_for_day` |
| `GetQuestForEmail` | `get_quest_for_email` |
| `GetLastError` | `get_last_error` |
| `TrackSqlUsage` | `track_sql_usage` |
| `GetAvailableSites` | `get_available_sites` |
| `GetArticlesForSite` | `get_articles_for_site` |
| `GetArticleById` | `get_article_by_id` |
| `LoadPlayerProgress` | `load_player_progress` |
| `SavePlayerProgress` | `save_player_progress` |
| `SavePlayerChoice` | `save_player_choice` |
| `GetRandomEventForDay` | `get_random_event_for_day` |

### Основные правила

1. **Все `public` методы C# автоматически доступны из GDScript** — не нужны специальные атрибуты
2. **Класс C# должен наследоваться от Godot-типа** (`Node`, `Resource` и т.д.)
3. **C# проект должен быть успешно собран** — без сборки GDScript не увидит изменения
4. **Используйте `Godot.Collections.Array` и `Godot.Collections.Dictionary`** вместо `System.Collections`

### Требования к C# классу

```csharp
public partial class FirebirdDatabase : Node
{
    // public метод → доступен из GDScript как execute_query()
    public List<Godot.Collections.Dictionary<string, Variant>> ExecuteQuery(string sql)
    {
        // ...
    }

    // private метод → НЕ доступен из GDScript
    private void ExecuteNonQuery(string sql)
    {
        // ...
    }
}
```

### Вызов из GDScript

```gdscript
# Правильно: snake_case (Godot конвертирует автоматически)
var result = DatabaseManager.execute_query("SELECT * FROM employees")
var error = DatabaseManager.get_last_error()

# НЕПРАВИЛЬНО: PascalCase (вызовет ошибку "Nonexistent function")
var result = DatabaseManager.ExecuteQuery("SELECT * FROM employees")
```

### Пересборка проекта

После изменения C# кода **обязательно** пересобрать:

```bash
dotnet build firebird-protocol.csproj
```

Или через редактор Godot: **Build → Build Solution** (Ctrl+Shift+B)

### Частые ошибки

| Ошибка | Причина | Решение |
|---|---|---|
| `Nonexistent function 'ExecuteQuery'` | 1) Метод `private` 2) Не пересобран проект 3) Вызов в PascalCase | Сделать `public`, пересобрать, использовать `execute_query` |
| `Nonexistent function 'execute_query'` | Метод `private` или проект не пересобран | Проверить `public`, `dotnet build`, перезапустить сцену |
| Метод не виден после `dotnet build` | Godot не перезагрузил сборку | Закрыть и reopen Godot редактор |

### Сигналы

```csharp
[Signal]
public delegate void DatabaseReadyEventHandler();

[Signal]
public delegate void ContentLoadedEventHandler();
```

```gdscript
# Подключение в GDScript
DatabaseManager.database_ready.connect(_on_database_ready)
DatabaseManager.content_loaded.connect(_on_content_loaded)
```

> Сигналы в GDScript подключаются в `snake_case`: `database_ready`, `content_loaded`

---

*Источник: [Godot 4.x C# API differences](https://docs.godotengine.org/en/4.4/tutorials/scripting/c_sharp/c_sharp_differences.html)*
