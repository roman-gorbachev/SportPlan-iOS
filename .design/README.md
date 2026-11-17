# .design — снимок дизайн-канваса

Снимок исходников канваса «Трекер тренировок» на 17.11.2026. Бриф — `design-brief.md` в этой же папке.
Живая версия (смотреть и править): https://claude.ai/artifact/HfYdf17DiKLv8MoVk1qzQJ

## Что это за файлы

- `canvas.json` — раскладка канваса: какие доски есть, их размеры и порядок.
- `*.dc.html` — доски в формате Design Component. Это HTML с инлайн-стилями плюс шаблоны (`{{t.surf}}`, `<sc-for>`, `<sc-if>`, `<dc-import>`), поэтому в обычном браузере они отображаются не полностью. Смотреть — по ссылке выше.
- Значения для шаблонов лежат в конце каждого файла, в `renderVals()`. Для каждой темы там объект `light` / `dark` с цветами.

## Где что

| Папка / файл | Содержание |
|---|---|
| `Main`, `Journal`, `Print` | Шаг 1: три концепции (история) |
| `Hybrid` | Выбранное направление «Блины, крупно» |
| `system/Color` | Цветовые токены светлой и тёмной темы, контраст, блины IWF, уровни heatmap |
| `system/Type` | Шкала шрифтов (Unbounded + Onest, Dynamic Type), отступы 4pt, скругления, линии |
| `system/Foundations` | SF Symbols, движение и Reduce Motion, haptics |
| `system/WorkoutKit` | Строка подхода, степпер, таймер отдыха, секундомер подхода, Live Activity и Dynamic Island на всю тренировку, подсказка прогрессии, заметка |
| `system/LoadTypes` | Строка подхода по оборудованию и метрике |
| `system/HistoryKit` | Heatmap (5 уровней по рабочим подходам), графики и рекорды для трёх типов упражнений, бейдж рекорда, пустые состояния |
| `system/PlatesKit` | Настройки «Мой зал»: оборудование и блины |
| `screens/WorkoutScreen` | Экран «Тренировка»: один компонент, параметры `dark` и `state` (active / start / empty / ax) |
| `screens/*Light`, `*Dark` | Состояния экрана «Тренировка», собранные из `WorkoutScreen` |
| `screens/ProgramsScreen` | Вкладка «Программы»: `state` list / empty / day / ax |
| `screens/ExerciseFlow` | Справочник упражнений и добавление: `state` library / libraryEmpty / archive / type / details |
| `screens/Prog*`, `Lib*`, `Add*`, `Archive*` | Состояния этих экранов в светлой и тёмной теме |

Для кода главное — `system/Color` и `system/Type`: в них все токены (имена вроде `textPrimary`, `surfaceSunken`, `numeralL` совпадают с тем, что стоит завести в модуле дизайн-токенов).
