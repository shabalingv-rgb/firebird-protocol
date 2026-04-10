# Godot .NET 4.x - Руководство для проекта Firebird Protocol

## Обзор

Проект **Firebird Protocol** использует Godot 4.6 с поддержкой C# (.NET 8.0). Это руководство описывает ключевые аспекты работы с .NET в Godot.

---

## 🔧 Настройка среды

### Требования
- **Godot Engine 4.6+** с поддержкой .NET (скачивать с godotengine.org, версия **.NET**)
- **.NET SDK 8.0** (скачать с https://dotnet.microsoft.com/download)
- **Firebird Embedded 5.0** (включён в проект)

### Проверка установки
```bash
# Проверить версию .NET SDK
dotnet --version
# Должно вывести: 8.0.x

# Проверить Godot
godot --version
# Должно вывести: 4.6.x
```

---

## 📁 Критически важные файлы .NET

### `firebird-protocol.csproj` ✅ СОЗДАН
Файл создан с правильной конфигурацией:
```xml
<Project Sdk="Godot.NET.Sdk/4.6.0">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <EnableDynamicLoading>true</EnableDynamicLoading>
    <RootNamespace>firebirdprotocol</RootNamespace>
  </PropertyGroup>
</Project>
```

> ⚠️ `firebird-protocol.csproj.old` — устаревший файл, можно удалить.

### `firebird-protocol.slnx` ✅ ОБНОВЛЁН
Файл решения теперь ссылается на проект:
```xml
<Solution>
  <Project Path="firebird-protocol.csproj" />
</Solution>
```

### `Directory.Build.props`
Файл в `scripts/database/Directory.Build.props` — **проверить его содержимое**. Обычно он содержит общие настройки сборки.

---

## 🏗 Архитектура C# в проекте

### Главный класс: `FirebirdDatabase.cs`
Расположение: `scripts/system/FirebirdDatabase.cs`

**Ключевые особенности:**
- Наследуется от `Godot.Node`
- Использует `FirebirdSql.Data.FirebirdClient` для подключения к БД
- Автозагрузка через `project.godot` → `[autoload]` → `DatabaseManager`
- Кэширует данные из БД в списки `Godot.Collections.Dictionary<string, Variant>`

**Основные методы:**
| Метод | Описание |
|-------|----------|
| `InitializeDatabase()` | Инициализация БД, создание таблиц если нужно |
| `GetEmailsForDay(dayId)` | Получить письма для конкретного дня |
| `GetQuestForEmail(emailId)` | Получить задание для письма |
| `LoadPlayerProgress(saveSlot)` | Загрузка прогресса игрока |
| `SavePlayerProgress(...)` | Сохранение прогресса |
| `ExecuteQuery(sql)` | Выполнение SQL SELECT |
| `GetAvailableSites(dayId)` | Сайты браузера, доступные в день N |
| `GetArticlesForSite(siteId, dayId)` | Статьи для категории |

### Взаимодействие GDScript ↔ C#

**Из GDScript вызвать C# метод:**
```gdscript
# DatabaseManager — это autoload-имя для FirebirdDatabase.cs
var emails = DatabaseManager.GetEmailsForDay(1)
var quest = DatabaseManager.GetQuestForEmail(1)
var progress = DatabaseManager.LoadPlayerProgress(1)
```

**Типы данных:**
- C# `List<Dictionary<string, Variant>>` → GDScript `Array[Dictionary]`
- C# `Dictionary<string, Variant>` → GDScript `Dictionary`
- Firebird возвращает столбцы в **ВЕРХНЕМ РЕГИСТРЕ** (`DAY_ID`, `EMAIL_ID`)

---

## 🐛 Распространённые проблемы

### 1. C# код не компилируется
**Причина:** ~~Отсутствовал `.csproj`~~ ✅ **ИСПРАВЛЕНО**.

Если всё ещё есть проблемы:
1. В Godot: **Project → Tools → C# → Clean**
2. Затем: **Project → Tools → C# → Build**
3. Или через консоль: `dotnet build --force`

### 2. Методы C# не видны из GDScript
**Причина:** 
- Класс не `public partial`
- Метод не `public`
- `.csproj` не собран

**Решение:**
```csharp
public partial class FirebirdDatabase : Node
{
    public Array GetEmailsForDay(int dayId) { ... }  // ✅ Видно из GDScript
}
```

### 3. Регистр столбцов из Firebird
Firebird возвращает столбцы в **ВЕРХНЕМ РЕГИСТРЕ**. Всегда проверяйте оба варианта:
```csharp
int emailDayId = -1;
if (email.ContainsKey("DAY_ID")) emailDayId = email["DAY_ID"].AsInt32();
else if (email.ContainsKey("day_id")) emailDayId = email["day_id"].AsInt32();
```

### 4. Connection string для Firebird Embedded
```csharp
string dbPath = ProjectSettings.GlobalizePath("res://game_content.fdb");
_database = $"Database=localhost:{dbPath};User=SYSDBA;Password=masterkey;ServerType=0;Dialect=3;";
```
- `ServerType=0` — Embedded режим
- `User=SYSDBA;Password=masterkey` — стандартные учётные данные

### 5. Ошибка "fb_temp" папка
Firebird требует временную папку для lock-файлов:
```csharp
string tempPath = Path.Combine(Directory.GetCurrentDirectory(), "fb_temp");
Directory.CreateDirectory(tempPath);
// Environment.SetEnvironmentVariable("FIREBIRD_LOCK", tempPath); // Закомментировано — может понадобиться
```

---

## 📦 NuGet пакеты

### FirebirdSql.Data.FirebirdClient
- **Версия:** 10.0.0
- **Назначение:** Клиент для Firebird SQL
- **Документация:** https://firebirdsql.org/en/net-provider/

**Установка (если нет в .csproj):**
```bash
dotnet add package FirebirdSql.Data.FirebirdClient --version 10.0.0
```

---

## 🔨 Сборка и экспорт

### Из Godot Editor
1. **Project → Tools → C# → Build** (собрать C#)
2. **F5** — запустить с отладкой
3. **Project → Export** — экспорт на платформу

### Из командной строки
```bash
# Собрать C#
dotnet build

# Запустить Godot
godot --path .

# Экспорт (headless)
godot --headless --export-release "Windows Desktop" ../builds/firebird-protocol.exe
```

---

## 📚 Полезные ссылки

- [Godot .NET Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html)
- [FirebirdSql.NET Provider](https://github.com/cincuranet/FirebirdSql.Data.FirebirdClient)
- [Godot C# API](https://docs.godotengine.org/en/stable/classes/c_sharp.html)
- [Variant в Godot C#](https://docs.godotengine.org/en/stable/classes/class_variant.html)

---

> **Примечание для AI-моделей:** При генерации C# кода для этого проекта всегда используйте `Godot.NET.Sdk/4.6.0`, `net8.0`, и `FirebirdSql.Data.FirebirdClient 10.0.0`.
