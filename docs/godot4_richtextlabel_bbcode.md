# Godot 4 RichTextLabel BBCode - Краткое руководство

## Включение BBCode

**В редакторе:** Выбери `RichTextLabel` → Inspector → поставь галочку `Bb Code Enabled`

**В коде (ДО установки текста!):**
```gdscript
$RichTextLabel.bbcode_enabled = true
$RichTextLabel.text = "[color=red]Красный текст[/color]"
```

⚠️ Важно: `bbcode_enabled = true` нужно установить **ДО** присваивания текста!

## Синтаксис цветов

### Правильный синтаксис
```gdscript
# Через BBCode
$RichTextLabel.text = "Обычный [color=red]красный[/color] и [color=#ff5500]оранжевый[/color] текст"

# Через код (рекомендуется для динамического текста)
$RichTextLabel.push_color(Color.RED)
$RichTextLabel.add_text("Красный текст")
$RichTextLabel.pop()
```

### Поддерживаемые форматы цветов
- Имена цветов HTML: `red`, `blue`, `green`, `orange`, `gray`, `cyan`, `crimson` и т.д.
- HEX 3 или 6 символов: `#f00`, `#ff0000`
- HEX 8 символов (с прозрачностью): `#ff000080`

### ❌ НЕ работает в Godot 4
- `color="red"` (кавычки)
- `color=rgb(255, 0, 0)` (CSS функции)
- Пробелы в значении: `color=red `

## Основные теги BBCode

| Тег | Описание | Пример |
|-----|----------|--------|
| `[color=VALUE]текст[/color]` | Цвет текста | `[color=red]Ошибка[/color]` |
| `[b]текст[/b]` | Жирный | `[b]Важно[/b]` |
| `[i]текст[/i]` | Курсив | `[i]Примечание[/i]` |
| `[u]текст[/u]` | Подчёркивание | `[u]Ссылка[/u]` |
| `[s]текст[/s]` | Зачёркивание | `[s]Старое[/s]` |
| `[font_size=SIZE]текст[/font_size]` | Размер шрифта | `[font_size=20]Крупный[/font_size]` |
| `[img]path[/img]` | Изображение | `[img]res://icon.svg[/img]` |
| `[url]ссылка[/url]` | Ссылка | `[url]https://godotengine.org[/url]` |
| `[center]текст[/center]` | По центру | `[center]Заголовок[/center]` |
| `[right]текст[/right]` | По правому краю | `[right]Подпись[/right]` |

## Рекомендуемый подход для динамического текста

Godot 4 рекомендует использовать `push_color()`/`pop()` вместо пересборки строки с BBCode:

```gdscript
func show_warning(message: String):
    $RichTextLabel.append_text("\n\n")
    $RichTextLabel.push_color(Color.ORANGE)
    $RichTextLabel.append_text("⚠️ ВНИМАНИЕ: ")
    $RichTextLabel.append_text(message)
    $RichTextLabel.pop()
    $RichTextLabel.push_color(Color.GRAY)
    $RichTextLabel.append_text("\n\nДополнительная инструкция...")
    $RichTextLabel.pop()
```

## Настройка шрифтов для RichTextLabel

Чтобы все стили (обычный, жирный, курсив) использовали один шрифт:

```
[node name="EmailBody" type="RichTextLabel"]
theme_override_fonts/normal_font = ExtResource("font")
theme_override_fonts/bold_font = ExtResource("font")
theme_override_fonts/italics_font = ExtResource("font")
theme_override_fonts/mono_font = ExtResource("font")
bbcode_enabled = true
```

## Источники

- [Официальная документация Godot 4](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html)
- [Godot 4 RichText Tutorial (YouTube)](https://www.youtube.com/watch?v=L_H8Wvw8oG0)
