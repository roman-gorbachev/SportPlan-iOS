# Этап 1 — каркас проекта (план)

## Цель
Пустое, но правильно устроенное приложение: настройки проекта по решениям, локальный пакет с `Domain` и `DesignSystem`, настоящие токены и шрифты из дизайна, три вкладки со своими стеками навигации, тесты, установка на iPhone. Функциональности и БД нет (БД — этап 2).

## Структура после этапа
```
sportplan.xcodeproj
sportplan/                         таргет приложения (папка синхронизируется)
  SportplanApp.swift               вместо MyApp.swift, регистрирует шрифты
  di/AppDIContainer.swift
  presentation/
    root/RootView.swift            TabView, три вкладки
    navigation/Router.swift        протокол
    navigation/TabRouter.swift     @Observable, NavigationPath
    navigation/AppTab.swift
    workout/ui/...                 вкладка, заглушка экрана, шестерёнка → настройки
    programs/ui/...                вкладка, заглушка экрана
    history/ui/...                 вкладка, заглушка экрана
    settings/ui/...                заглушка экрана
  Localizable.xcstrings            базовый язык ru
sportplanTests/                    Swift Testing
Packages/SportplanKit/
  Package.swift                    swift-tools 6.2, iOS 26
  Sources/Domain/Weight.swift      первый доменный тип: граммы, Comparable, арифметика
  Sources/DesignSystem/            Palette, Typography, Spacing, CornerRadius, FontRegistry, Fonts/*.ttf
  Tests/DomainTests/, Tests/DesignSystemTests/
```

## Шаги
1. **Настройки шаблона** (правка `project.xcproj`):
   - bundle id `com.rgorbachev.sportplan`;
   - Swift 6;
   - только iPhone (`TARGETED_DEVICE_FAMILY = 1`, платформы iphoneos/iphonesimulator), только портрет;
   - убрать `REGISTER_APP_GROUPS`, `ENABLE_APP_SANDBOX`, `ENABLE_USER_SELECTED_FILES`;
   - `IPHONEOS_DEPLOYMENT_TARGET = 26.0`;
   - язык разработки `ru`;
   - удалить `#Playground` и `ContentView.swift`.
   Проверка: проект собирается.
2. **Пакет `SportplanKit`**:
   - `Domain` без изоляции по умолчанию; `Weight` с тестами;
   - `DesignSystem` с MainActor по умолчанию, ресурсами-шрифтами и тестами;
   - строк для интерфейса в пакете нет.
   Проверка: `swift test`.
3. **Шрифты и токены**:
   - скачать Unbounded и Onest с Google Fonts (OFL, вместе с лицензиями). Если там только вариативные файлы, проверить, что iOS правильно берёт нужные начертания; если нет — сделать статические;
   - `FontRegistry` регистрирует шрифты из бандла пакета;
   - перенести токены из `.design/system`:
     - `Palette` — динамические цвета для светлой и тёмной темы, 15 токенов + 5 уровней heatmap;
     - `Typography` — numeralHero/L/M/S, largeTitle, title, headline, body, callout, footnote, caption; через `Font.custom(_:size:relativeTo:)` и `.appStyle(_:)`, цифры табличные;
     - `Spacing` — 4…56;
     - `CornerRadius` — 6/14/20/28 и круг;
   - каталог токенов для `#Preview`, чтобы сверить с канвасом.
4. **Ручной шаг в Xcode** (новый формат проекта не документирован, поэтому руками надёжнее): добавить локальный пакет `Packages/SportplanKit`, подключить `Domain` и `DesignSystem` к приложению, создать таргет тестов `sportplanTests` (Swift Testing). Пошаговую инструкцию даст Claude.
5. **Каркас приложения**:
   - `SportplanApp`, `AppDIContainer` (пока пустой корень композиции);
   - `RootView` с `TabView`: «Тренировка», «Программы», «История»; у каждой вкладки свой `TabRouter` и `NavigationStack(path:)`;
   - экраны-заглушки, оформленные токенами. ViewModel и пару `XRoute`/`XScreen` вводим вместе с первой фичей, у заглушек нет данных;
   - шестерёнка на «Тренировке» открывает заглушку настроек через роутер вкладки;
   - строки в `Localizable.xcstrings`;
   - тест приложения: роутер (push/pop) и сборка контейнера.
6. **Документы**: в `CLAUDE.md` — команды сборки и тестов, фактическая структура; в брифе — что изменилось по ходу.
7. **Проверка**:
   - сборка и запуск на симуляторе iOS 27: три вкладки, переход в настройки, светлая и тёмная тема, крупный Dynamic Type;
   - с разрешения пользователя докачать среду iOS 26 и запустить там (это несколько ГБ);
   - зелёные `swift test` и тесты приложения;
   - установка на iPhone с бесплатного аккаунта (подпись, профиль).
8. **Коммит** после твоего ревью, по формату из CLAUDE.md.

## Открыто на будущее (не этот этап)
- ~~Цвета блинов в светлой и тёмной теме~~ — снято дизайном на этапе 2: один цвет на блин, обводка `separatorStrong`.
