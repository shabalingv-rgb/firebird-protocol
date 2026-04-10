# Архитектура проекта Firebird Protocol

## Обзор

Firebird Protocol — это ретрофутуристическая игра-головоломка на Godot 4.6 с гибридной архитектурой **C# + GDScript**. Игрок — сотрудник НИИ «Файербёрд» в альтернативном СССР, работающий с SQL-терминалом.

---

## 🏗 Гибридная архитектура

```
┌─────────────────────────────────────────────┐
│              Godot Engine 4.6               │
├──────────────────┬──────────────────────────┤
│    GDScript      │         C# (.NET 8)      │
│   (UI & Сцены)   │   (БД + Бизнес-логика)   │
│                  │                          │
│  • Email Client  │  • FirebirdDatabase      │
│  • Browser       │    (DatabaseManager)     │
│  • Terminal      │                          │
│  • Desktop       │  • GameState (частично)  │
│  • Debug Panel   │  • QuestManager (частично)│
│  • Guide         │  • EmailSystem           │
│  • Sudoku        │  • GuideSystem           │
│                  │                          │
│  ←── Сигналы + CallMethod ──→│
└──────────────────┴──────────────────────────┘
```

### Почему гибрид?
- **GDScript** — быстрая разработка UI, сцен, анимаций
- **C#** — надёжная работа с Firebird SQL, типизация, NuGet пакеты

---

## 📁 Структура файлов

```
firebird-protocol/
│
├── project.godot                 # Конфигурация проекта Godot
├── firebird-protocol.slnx        # Решение .NET ✅ Обновлено
├── firebird-protocol.csproj      # Проект .NET ✅ Создано (SDK 4.6.0)
├── firebird-protocol.csproj.old  # Старый .csproj (⚠️ УСТАРЕЛ, можно удалить)
│
├── game_content.fdb              # База данных Firebird
├── libfbclient.dylib             # macOS библиотека Firebird
├── icon.svg                      # Иконка проекта
│
├── scenes/                       # Сцены Godot (.tscn + .gd)
│   ├── browser/                  # Внутриигровой браузер
│   │   ├── browser.gd
│   │   └── browser.tscn
│   ├── debug/                    # Панель отладки (F1)
│   │   ├── debug_panel.gd
│   │   └── debug_panel.tscn
│   ├── desktop/                  # Рабочий стол
│   │   ├── desktop.gd
│   │   └── desktop.tscn
│   ├── email/                    # Почтовый клиент
│   │   ├── email_client.gd
│   │   └── email_client.tscn
│   ├── guide/                    # Справочная система SQL
│   │   ├── guide_client.gd
│   │   └── guide_client.tscn
│   ├── main_menu/                # Главное меню
│   │   ├── main_menu.gd
│   │   ├── main_menu.tscn        # ✅ Исправлено
│   │   └── test_violation_btn.gd
│   ├── sudoku/                   # Мини-игра Судоку
│   │   ├── sudoku.gd
│   │   ├── sudoku.tscn
│   │   └── thick_lines.gd
│   ├── terminal/                 # SQL-терминал
│   │   ├── terminal.gd
│   │   └── terminal.tscn
│   └── tutorial/                 # Обучающие сцены
│       ├── day_zero.gd
│       └── day_zero.tscn         # ✅ Дубликат удалён
│
├── scripts/
│   ├── database/
│   │   ├── database_manager.gd   # ✅ Обновлён комментарий (устаревший)
│   │   ├── game_content_firebird.sql  # SQL инициализации БД
│   │   ├── content_days_1_5.sql  # Доп. данные дней
│   │   ├── add_quest_day1.sql    # Доп. задание
│   │   └── Directory.Build.props # Настройки сборки .NET
│   ├── global/
│   │   └── GameState.gd          # Глобальное состояние игры
│   └── system/
│       ├── FirebirdDatabase.cs   # ✅ ОСНОВНОЙ класс БД (C#)
│       ├── quest_manager.gd      # Менеджер заданий
│       ├── email_system.gd       # Система почты
│       ├── guide_system.gd       # Справочная система
│       └── global_input.gd       # Глобальный ввод (F1)
│
├── docs/                         # Документация
│   ├── godot4_richtextlabel_bbcode.md
│   ├── godot-dotnet/
│   ├── firebird-sql/
│   ├── project-structure/
│   └── ai-assistant/
│
├── assets/                       # Ресурсы (шрифты, иконки, темы)
│   ├── fonts/
│   ├── icons/
│   └── themes/
│
└── addons/                       # Плагины Godot
```

---

## 🔌 Autoload (Автозагрузка)

Определены в `project.godot` → `[autoload]`:

| Имя | Файл | Тип | Описание |
|-----|------|-----|----------|
| `GameState` | `*uid://83ilcgee0xpc` | GDScript | Состояние игры, дни, нарушения, флаги |
| `QuestManager` | `*uid://qvhnca2clj38` | GDScript | Управление заданиями |
| `EmailSystem` | `*uid://cje5bc56xghjs` | GDScript | Система почты |
| `GuideSystem` | `*uid://bjwcspsofnsfi` | GDScript | Справочник по SQL |
| `DatabaseManager` | `*uid://h85iqknxq553` | **C#** | FirebirdDatabase.cs — обёртка БД |
| `GlobalInput` | `res://scripts/system/global_input.gd` | GDScript | Обработка клавиши F1 |

> ⚠️ **ВАЖНО:** `DatabaseManager` — это C# класс `FirebirdDatabase`. Все обращения к БД идут через него.

---

## 🔄 Поток данных

### 1. Инициализация (запуск игры)
```
Godot запускает project.godot
    ↓
Загружаются Autoload-скрипты (GameState, QuestManager, etc.)
    ↓
FirebirdDatabase._Ready() → InitializeDatabase()
    ↓
Проверка game_content.fdb
    ├─ Если нет → создание БД + импорт из game_content_firebird.sql
    └─ Если есть → подключение
    ↓
LoadContentToCache() — кэширование всех таблиц
    ↓
Сигнал DatabaseReady
    ↓
QuestManager ждёт → LoadPlayerProgress()
    ↓
Главное меню (main_menu.tscn)
```

### 2. Игровой цикл (день)
```
Игрок начинает день
    ↓
QuestManager.start_day(day_number)
    ↓
DatabaseManager.GetEmailsForDay(day_number) → из кэша C#
    ↓
Для каждого письма → DatabaseManager.GetQuestForEmail(email_id)
    ↓
Активное задание → UI Email Client
    ↓
Игрок работает в Терминале → SQL запросы
    ↓
Terminal.gd → DatabaseManager.ExecuteQuery(sql)
    ↓
Проверка результата → QuestManager.check_quest_completion()
    ↓
При успехе → complete_quest() → save_progress()
    ↓
Все задания выполнены → next_day()
```

### 3. Сохранение прогресса
```
QuestManager.save_progress()
    ↓
DatabaseManager.SavePlayerProgress(role, day, violations, flags, quests)
    ↓
C#: UPDATE player_progress WHERE save_slot = 1
    ↓
Если не обновлено → INSERT INTO player_progress
    ↓
Фиксация в Firebird
```

---

## 📋 Known Issues (Известные проблемы)

### 🔴 Критические (блокеры) — ВСЕ ИСПРАВЛЕНЫ ✅

| # | Проблема | Статус |
|---|----------|--------|
| 1 | ~~Отсутствует `.csproj`~~ | ✅ Создан `firebird-protocol.csproj` с SDK `4.6.0` |
| 2 | ~~Пустой `.slnx`~~ | ✅ Добавлена ссылка на `.csproj` |
| 3 | ~~Несоответствие SDK~~ | ✅ Новый `.csproj` использует `4.6.0` |

### 🟡 Оставшиеся предупреждения

| # | Проблема | Описание |
|---|----------|----------|
| 4 | `libfbclient.dylib` на Windows | В `.gitignore`, файл остаётся (macOS) |
| 5 | Отсутствует `fbclient.dll` | Нужен для Windows (скачать отдельно) |
| 6 | Непоследовательный стиль имён | `GameState.gd` vs `email_system.gd` (косметическое) |

### 🔵 Информационные

| # | Проблема | Описание |
|---|----------|----------|
| 12 | `game_concept_analysis.md` упоминает Qdrant | Qdrant не используется в проекте |
| 13 | README упоминает несуществующие папки | `addons/`, `assets/`, `database/`, `fb_temp/` |
| 14 | `.uid` файл для `.cs` | `FirebirdDatabase.cs.uid` — нестандартно |
| 15 | `game_content.fdb — копия` | Бэкап БД в репозитории — добавить в `.gitignore` |

---

## 🎮 Ключевые сцены

### Главное меню (`main_menu.tscn`)
- Кнопки: Новая игра, Продолжить, Настройки, Выход
- ⚠️ Есть дублирующие signal connections на `_on_test_violation_btn_pressed`

### SQL Терминал (`terminal.tscn`)
- Основной игровой элемент
- Принимает SQL-запросы, выполняет через `DatabaseManager.ExecuteQuery()`
- Результат отображается в таблице

### Email Client (`email_client.tscn`)
- Показывает письма для текущего дня
- Связан с системой заданий

### Debug Panel (`debug_panel.tscn`)
- Вызывается по F1
- Перемотка дней, смена роли, сброс прогресса

---

## 📊 Состояние игры (GameState.gd)

**Ключевые переменные:**
```gdscript
var current_campaign: int = 1       # Кампания (1, 2, 3)
var current_day: int = 0            # Текущий день
var security_violations: int = 0    # Нарушения (макс = 3)
var story_flags: Dictionary = {}    # Флаги сюжета
var persistent_flags: Dictionary = {} # Сохраняются между кампаниями
var is_game_over: bool = false
```

**Сигналы:**
- `security_violation_changed(count)` — изменение нарушений
- `day_changed(day)` — новый день
- `story_flag_changed(flag_name, value)` — изменение флага

---

## 🗂 База данных

### Файл БД
- **Путь:** `res://game_content.fdb`
- **Тип:** Firebird 5.0 Embedded
- **Инициализация:** Автоматическая из `game_content_firebird.sql`

### Кэширование
C# класс `FirebirdDatabase` кэширует ВСЕ таблицы при старте:
```csharp
CachedDays     // game_days
CachedEmails   // emails
CachedQuests   // quests
CachedNews     // news_articles
CachedDossiers // employee_dossiers
CachedEvents   // random_events
CachedEndings  // endings
```

> ⚠️ При изменении данных в БД во время игры нужно вызывать `LoadContentToCache()` заново.

---

## 📚 Полезные ссылки

- [README.md](../../README.md) — основная документация
- [docs/godot-dotnet/](../godot-dotnet/README.md) — Godot .NET
- [docs/firebird-sql/](../firebird-sql/README.md) — Firebird SQL
- [docs/ai-assistant/](../ai-assistant/README.md) — инструкция для AI

---

> **Последнее обновление:** Апрель 2026
> **Версия проекта:** Godot 4.6, .NET 8.0, Firebird 5.0
