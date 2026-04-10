# 🐦 Firebird Protocol

> Ретрофутуристическая игра-головоломка в стиле зелёного монохромного терминала. Расследуйте тайны НИИ «Файербёрд», используя SQL-запросы и принимая моральные решения.

![Godot](https://img.shields.io/badge/Godot-4.6-blue?logo=godotengine)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Language](https://img.shields.io/badge/language-C%23%20%2B%20GDScript-orange)
![Database](https://img.shields.io/badge/database-Firebird%205.0-purple)

---

## 📋 Оглавление

- [Описание](#-описание)
- [Особенности](#-особенности)
- [Технологии](#-технологии)
- [Установка](#-установка)
- [Управление](#-управление)
- [Архитектура](#-архитектура)
- [Структура проекта](#-структура-проекта)
- [Разработка](#-разработка)
- [Лицензия](#-лицензия)

---

## 📖 Описание

**Firebird Protocol** — это атмосферная игра, действие которой происходит в альтернативном СССР. Вы — новый сотрудник НИИ «Файербёрд», секретного института информационных систем. Ваш рабочий инструмент — терминал с SQL. Каждое утро вы получаете задания по электронной почте, анализируете данные и раскрываете тайны института.

### Игровой процесс
1. **Утро** — проверяйте почту и получайте задания
2. **Работа** — выполняйте SQL-запросы в терминале
3. **Браузер** — читайте новости, изучайте wiki, общайтесь на доске объявлений
4. **Решения** — ваши выборы влияют на сюжет и концовку

---

## ✨ Особенности

- 📧 **Система электронной почты** — ежедневные задания и корреспонденция
- 💻 **Интерактивный терминал** — выполнение SQL-запросов в реальном времени
- 🌐 **Внутриигровой браузер** — новости, wiki, доска объявлений, юмор
- 🎯 **Система заданий** — прогрессия от простых к сложным запросам
- 📊 **Динамическая база данных** — Firebird 5.0 Embedded с игровым контентом
- 🕰️ **Система дней** — каждый день приносит новые задания и события
- 🎭 **Моральные выборы** — решения влияют на сюжет и концовку
- 🎨 **Ретро-эстетика** — зелёный монохромный терминал, пиксельные иконки
- 🔍 **Система справки** — встроенный справочник по SQL

---

## 🛠 Технологии

| Компонент | Технология |
|-----------|-----------|
| **Движок** | [Godot Engine 4.6](https://godotengine.org/) |
| **Языки** | C# (бэкенд), GDScript (фронтенд) |
| **СУБД** | [Firebird 5.0 Embedded](https://firebirdsql.org/) |
| **ORM** | FirebirdSql.Data.FirebirdClient |
| **Физика** | Jolt Physics |
| **Рендер** | Forward Plus (D3D12 / Vulkan) |

---

## 📦 Установка

### Требования
- **Godot Engine 4.6+** с поддержкой .NET / Mono
- **.NET SDK 8.0+**
- **Firebird Embedded** (включён в проект)

### Запуск

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/yourusername/firebird-protocol.git
cd firebird-protocol

# 2. Откройте проект в Godot Engine
#    File → Open → выберите project.godot

# 3. Godot автоматически импортирует ассеты и установит зависимости
#    При первом запуске будет создана база данных

# 4. Нажмите F5 для запуска
```

### Сборка

```bash
# Через Godot Editor: Project → Export → выберите платформу
# Или через командную строку:
godot --headless --export-release "Linux" ../builds/firebird-protocol.x86_64
```

---

## 🎮 Управление

| Клавиша | Действие |
|---------|----------|
| `F1` | Открыть/закрыть панель отладки (в любой сцене) |
| `ESC` | Закрыть панель отладки |
| `Мышь` | Навигация по UI |

---

## 🏗 Архитектура

Проект использует гибридную архитектуру **C# + GDScript**:

```
┌─────────────────────────────────────────────────┐
│                   Godot Engine                  │
├─────────────────────┬───────────────────────────┤
│      GDScript       │          C#               │
│   (UI & Scenes)     │    (Database & Logic)     │
│                     │                           │
│  • Email Client     │  • FirebirdDatabase       │
│  • Browser          │  • QuestManager (автозапуск)│
│  • Terminal         │  • GameState (автозапуск) │
│  • Desktop          │  • EmailSystem (автозапуск)│
│  • Debug Panel      │  • GuideSystem (автозапуск)│
│                     │                           │
│  ←─────── Сигналы и вызовы ───────→│
└─────────────────────┴───────────────────────────┘
```

### Автозагрузки (Autoload)

| Singleton | Тип | Описание |
|-----------|-----|----------|
| `GameState` | GDScript | Глобальное состояние игры, сигнал `day_changed` |
| `QuestManager` | GDScript | Управление заданиями и прогрессом |
| `EmailSystem` | GDScript | Система электронной почты |
| `GuideSystem` | GDScript | Справочная система по SQL |
| `DatabaseManager` | C# | Обёртка над Firebird, кэш данных |
| `GlobalInput` | GDScript | Глобальный обработчик клавиши F1 |

---

## 📁 Структура проекта

```
firebird-protocol/
├── addons/                  # Плагины Godot
├── assets/
│   ├── fonts/               # PressStart2P-Regular.ttf (пиксельный шрифт)
│   └── icons/               # Монохромные иконки (SVG + PNG)
│       ├── mail.svg/png     # Почта
│       ├── browser.svg/png  # Браузер
│       ├── help.svg/png     # Справка
│       ├── sudoku.svg/png   # Судоку
│       ├── news.svg/png     # Новости
│       ├── wiki.svg/png     # Википедия
│       ├── board.svg/png    # Доска объявлений
│       └── humor.svg/png    # Юмор
├── database/                # Файлы Firebird (.fdb)
├── docs/                    # Документация
│   └── godot4_richtextlabel_bbcode.md
├── fb_temp/                 # Временные файлы Firebird
├── scenes/                  # Сцены Godot (.tscn + .gd)
│   ├── browser/             # Внутриигровой браузер
│   ├── debug/               # Панель отладки
│   ├── desktop/             # Рабочий стол
│   ├── email/               # Почтовый клиент
│   ├── guide/               # Справочная система
│   ├── main_menu/           # Главное меню
│   ├── sudoku/              # Мини-игра Судоку
│   └── terminal/            # SQL-терминал
├── scripts/
│   ├── database/            # SQL-скрипты инициализации
│   │   └── game_content_firebird.sql
│   ├── global/              # Глобальные GDScript-системы
│   └── system/              # C# ядро и утилиты
│       ├── FirebirdDatabase.cs
│       └── global_input.gd
├── game_content.fdb         # Файл базы данных Firebird
├── firebird-protocol.slnx   # Решение .NET
├── project.godot            # Конфигурация проекта
└── README.md
```

---

## 🧑‍💻 Разработка

### Добавление нового дня

1. Откройте `scripts/database/game_content_firebird.sql`
2. Добавьте запись в `game_days`:
```sql
INSERT INTO game_days (id, role, day_number, title, description, is_playable)
VALUES (4, 'employee', 4, 'Новый день', 'Описание дня', 1);
```
3. Добавьте письма, задания и новости для нового дня
4. Перезапустите игру (база данных будет пересоздана)

### Добавление нового письма

```sql
INSERT INTO emails (id, day_id, sender, sender_email, subject, body, email_type, is_required, sort_order)
VALUES (6, 2, 'Иванов П.С.', 'ivanov.ps@nii-firebird.gov', 'Тема письма', 'Текст письма...', 'quest', 1, 1);
```

Типы писем: `quest` (задание), `info` (информация), `warning` (предупреждение)

### Добавление новой статьи в браузер

```sql
-- Постоянная wiki-статья
INSERT INTO news_articles (id, day_id, category, title, content, author, is_permanent)
VALUES (15, 1, 'wiki', 'Заголовок', 'Содержимое', 'Автор', 1);

-- Временная новость
INSERT INTO news_articles (id, day_id, category, title, content, author, is_permanent)
VALUES (16, 3, 'news', 'Заголовок', 'Содержимое', 'Автор', 0);
```

Категории: `news`, `wiki`, `board` (день 3+), `humor` (день 5+)

### Панель отладки

Нажмите **F1** в любой сцене для открытия панели отладки:
- Перемотка дней (слайдер и кнопки)
- Смена роли (employee / journalist / manager)
- Добавление тестовых писем
- Сброс прогресса

---

## 📝 Лицензия

Этот проект распространяется под лицензией **MIT**. Подробнее см. файл [LICENSE](LICENSE).

---

## 🙏 Благодарности

- **[Godot Engine](https://godotengine.org/)** — свободный игровой движок
- **[Firebird SQL](https://firebirdsql.org/)** — надёжная реляционная СУБД
- **[Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P)** — пиксельный шрифт от CodeMan38

---

> *«ВНИМАНИЕ: Обнаружена активность в базе данных. Продолжайте работу, сотрудник.»*
