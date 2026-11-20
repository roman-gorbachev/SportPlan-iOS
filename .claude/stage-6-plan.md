# Этап 6: таймер отдыха и уведомления — план

## Контекст
Этап 5 (активная тренировка) в `main`. Следующий блок по `docs/code-brief.md` §4 — таймер отдыха: стартует сам после выполненного подхода, ±15 с, «Пропустить», хранит только даты (`workout.rest_started_at` / `rest_ends_at`, модель `RestPeriod` уже есть), локальное уведомление о конце, показ в `tabViewBottomAccessory`. Макет — `.design/system/WorkoutKit` раздел 03 («В блоке упражнения» и «Bottom accessory»). Новых миграций нет.

Решения обсуждения (18.11.2026):
- Вводим `ActiveWorkoutStore` сейчас — один владелец состояния тренировки; его читают вкладка «Тренировка» и accessory, на этапе 7 — Live Activity.
- Таймер в двух местах, как в макете: панель в блоке упражнения (−15 / +15 / «Пропустить», «из 2:00») и компактно в accessory (время, «отдых · дальше 65 × 8», +15). Тап по accessory → вкладка «Тренировка».
- Отдых кончился при открытом приложении: звук и haptic, без баннера.
- «Как в прошлый раз» в редакторе переделываем по макету в этом этапе; точная раскладка блинов — этап 8.

Позиции без вариантов (приняты): старт после любого первого выполнения подхода (рабочий, разминка, «Записать», стоп секундомера), длительность — `rest_sec` упражнения в тренировке; новый отдых заменяет старый; правка уже выполненного подхода отдых не трогает; −15 не уводит конец в прошлое (≤ 15 с осталось → отдых заканчивается); «Пропустить», «Завершить», «Отменить» обнуляют отдых и снимают уведомление; истёкший отдых в БД не стирается, UI сравнивает с текущим временем; разрешение на уведомления — при первом старте таймера; без разрешения таймер работает в приложении.

## 6.1 Domain и data
**Domain (`Packages/SportplanKit/Sources/Domain/`)**
- `RestPeriod`: `duration`, `isActive(at:)`, `adjusted(bySeconds:now:) -> RestPeriod?` (nil — отдых закончен); шаг 15 с и минимум — `private static let`.
- `ActiveWorkout`: `restTrigger` — последний выполненный подход (max `completedAt`) и его упражнение, для «Отдых после подхода 3»; `nextPlannedSet(after:)` — следующий невыполненный подход того же упражнения, иначе первый невыполненный следующего, иначе nil.
- `RestNotificationScheduler` (протокол, `Sendable`): `schedule(_ request: RestNotificationRequest)`, `cancel()`. `RestNotificationRequest` — `endsAt`, название упражнения, номер следующего подхода (без локализации: текст собирает data).
- `WorkoutRepository.updateRest(workoutId:rest:)`; `finish` и `cancel` обнуляют отдых.
- Use cases (`UseCase/Workout/`): общий `RestStarter` (пишет отдых и планирует уведомление); его вызывают `CompleteSetUseCase` (только если `completedAt` был nil) и `StopTimedSetUseCase`; новые `AdjustRestUseCase(seconds:)`, `SkipRestUseCase`; `FinishWorkoutUseCase` и `CancelWorkoutUseCase` получают scheduler и вызывают `cancel()`.
- Тесты: `RestPeriod` (сдвиг, обрезка, конец), старт отдыха после выполнения / стопа секундомера / не после правки, замена, пропуск, завершение и отмена снимают уведомление, `restTrigger`, `nextPlannedSet`. Фейк `FakeRestNotificationScheduler` на `Mutex` рядом с `FakeWorkoutRepository`, время — `TestClock`.

**Data (`sportplan/data/`)**
- `WorkoutRepositoryImpl.updateRest` и обнуление полей в `finish`; тесты в `WorkoutRepositoryImplTests`.
- `notifications/RestNotificationCenter` (`nonisolated`, `NSObject`, `UNUserNotificationCenterDelegate`): запрос разрешения при первом `schedule`, один постоянный идентификатор, текст из String Catalog («Отдых окончен» / «Пора: жим лёжа, подход 4»), `willPresent` → `[.sound]`. Делегат ставится в `AppDIContainer`.
- Time Sensitive: пробую entitlement `usernotifications.time-sensitive`; если personal team не подписывает — убираю, уровень `.active`. Проверяется только на устройстве.

## 6.2 Экраны
- `presentation/workout/common/ActiveWorkoutStore` (`@Observable`, в `AppDIContainer`, один на приложение): наблюдает `ObserveActiveWorkoutUseCase`, отдаёт `state` (loading / noWorkout / active / error) и `rest: RestPeriod?` — обнуляется задачей, которая спит до `endsAt`; счётчик `restFinishedCount` для haptic. Наблюдение стартует из `.task` в `RootView`.
- `ActiveWorkoutViewModel` и `ExercisePickerViewModel` читают store через `Observations { }` вместо своего наблюдения; к use cases записи ходят как раньше.
- Панель отдыха в блоке упражнения-триггера (`RestTimerPanel` в `active/ui/`): «Отдых после подхода N», `Text(timerInterval:)`, «из 2:00», −15 / +15 / «Пропустить», по макету.
- Accessory: `RestTimerViewModel` + `RestTimerAccessory` (`presentation/workout/rest/`), `.tabViewBottomAccessory` в `RootView` только при активном отдыхе; время, «отдых · дальше 65 × 8», +15; тап → `selectedTab = .workout`; `.sensoryFeedback` по `restFinishedCount`.
- «Как в прошлый раз»: действие редактора берёт `previousResult(for:)` строки (`ActiveWorkoutExercise`), кнопка неактивна без истории; переименовать ключ строки и действие (`copyPreviousSet` → `copyLastWorkoutSet`).
- Доступность: лейбл «Отдых, осталось …», кнопки ≥ 44pt, Reduce Motion для прогресса.
- Строки — в `Localizable.xcstrings`.
- Тесты ViewModel: панель после выполнения подхода, +15 / −15 / «Пропустить», отдых исчезает после конца (короткий отдых), «Как в прошлый раз» подставляет прошлую тренировку.

## Файлы
- Domain: `Model/RestPeriod.swift`, `Model/ActiveWorkout.swift`, `Repository/WorkoutRepository.swift`, `UseCase/Workout/{CompleteSet,StopTimedSet,FinishWorkout,CancelWorkout}UseCase.swift` + новые.
- Data: `repositories/WorkoutRepositoryImpl.swift`, новый `notifications/RestNotificationCenter.swift`.
- Presentation: `root/RootView.swift`, `workout/active/...`, новые `workout/common/ActiveWorkoutStore.swift`, `workout/rest/...`; `di/AppDIContainer.swift`.
- Документы: этот план → `.claude/stage-6-plan.md`; решения → `.claude/decisions.md` («Этап 6»); `roadmap.md` — вопрос «Как в прошлый раз» снят, в этап 8 — точная раскладка блинов.

## Проверка
- `swift test` в `Packages/SportplanKit` и `xcodebuild test` — зелёные, сборка без предупреждений.
- Симулятор: выполнить подход → панель и accessory с отсчётом, accessory виден на вкладке «Программы»; +15 / −15 / «Пропустить»; дождаться конца — accessory уходит, звук; свернуть приложение до конца — приходит уведомление; перезапуск во время отдыха — отсчёт на месте; «Завершить» во время отдыха — уведомления нет; «Как в прошлый раз»; тёмная тема, крупный текст.
- На устройстве (нужен пользователь): подпись с Time Sensitive.
- Коммиты: 6.1 Domain и data → 6.2 экраны; от `Roman Gorbachev <romangorbachev2006@gmail.com>`, без упоминаний AI; затем merge в `main` и push.
