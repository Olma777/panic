# panic

Kill-switch на один шаг — часть экосистемы [Paranoid Tools](https://github.com/Di-kairos/paranoid-tools).

Сценарий: граница / принуждение / «кто-то идёт». Одной командой `panic now` (или
хоткеем через launchd) **спрятать и запереть** всё: закрыть открытые vault'ы
securetrash, размонтировать тома, очистить буфер обмена, заблокировать экран.

> **Статус: ранний (v0.1.0, work in progress).** Готов каркас + **ядро `now`**:
> размонтирует все смонтированные disk image'ы (`hdiutil detach -force`), чистит буфер
> обмена, блокирует экран. **`--hard`** дополнительно прибивает cloud-демоны и чистит
> Recent items.

## Использование

```bash
panic now           # спрятать и запереть сейчас
panic now --hard    # + прибить cloud-демоны, почистить «Recent items»
panic version
```

Явный verb `now` выбран намеренно: kill-switch не должен срабатывать от случайного
`panic` без аргументов (bare `panic` → usage).

## Архитектура

- Single-file Bash, ноль зависимостей. Нативные примитивы macOS (`hdiutil`,
  `pbcopy`, `osascript`/`pmset` для lock).
- Общее ядро (`lib/common.sh`) **вендорится** из securetrash inline, пиннуто к git-ref;
  `tools/vendor-common.sh --check` ловит дрейф в CI. См. `paranoid-tools/README.md`.
- Переиспользует close/detach-логику из vaultwatch (закрытие сессии vault).

## Scope & limitations

Базовый принцип экосистемы: честно про пределы. panic **прячет и запирает**, но:

- **не уничтожает** данные и **не чистит swap** (для уничтожения — `securetrash`);
  фрагменты plaintext могли уйти в swap и остаться там до перезаписи.
- `detach -force` при открытых файлах может **повредить данные** — осознанный
  trade-off режима паники (спрятать важнее), пользователь должен это знать. Нет confirm:
  скорость важнее; защита от случайного запуска — явный verb `now`.
- размонтирует **disk image'ы под `/Volumes`** (vault'ы/dmg); system-образы вне `/Volumes`
  не трогает. Физические внешние диски — в следующих паках.
- `--hard` чистит **глобальные** Recent items (shared file lists); per-app «недавние»
  внутри приложений этим НЕ стираются — честно про предел.
- блокировка экрана — `CGSession -suspend` (реальный login-window, не зависит от
  настройки «требовать пароль»); переопределяемо через `PANIC_CGSESSION`.
- не имитирует «полное стирание за секунду» — это была бы ложь.

## Windows-эквивалент

Планируется во вторую очередь: lock workstation, dismount BitLocker/VeraCrypt-томов,
очистка clipboard. Порт — как у securetrash/vaultwatch.
