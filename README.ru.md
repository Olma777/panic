[English](README.md) · **Русский**

# panic

Kill-switch в один шаг — спрятать и запереть всё одной командой.

[![CI](https://github.com/Di-kairos/panic/actions/workflows/ci.yml/badge.svg)](https://github.com/Di-kairos/panic/actions/workflows/ci.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS-blue)
![shellcheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)

Часть экосистемы [Paranoid Tools](https://github.com/Di-kairos/paranoid-tools).

Сценарий: граница / принуждение / «кто-то идёт». Одной командой `panic now` (или
хоткеем через launchd) **спрятать и запереть** всё: закрыть открытые vault'ы
securetrash, размонтировать тома, очистить буфер обмена, заблокировать экран.

## Установка

Checksum-verified установка с релизного тега — verify-then-run (не доверяй — проверяй):

```bash
base=https://github.com/Di-kairos/panic/releases/latest/download
curl -fsSLO "$base/install.sh"
curl -fsSLO "$base/SHA256SUMS"
shasum -a 256 -c SHA256SUMS --ignore-missing   # проверить сам install.sh
less install.sh                                  # прочитать глазами
bash install.sh                                  # тянет panic + сумму, проверяет, ставит
```

Быстрая форма (одна строка):

```bash
curl -fsSL https://github.com/Di-kairos/panic/releases/latest/download/install.sh | bash
```

`install.sh` тянет бинарь и `SHA256SUMS` из неизменного релизного тега и проверяет хеш
**до** установки. Переменные окружения: `PANIC_VERSION` (зафиксировать тег вместо `latest`),
`PANIC_DEST` (путь установки), `PANIC_BASE_URL` (переопределить источник для форков/тестов).

> **Целостность ≠ подлинность (честные границы).** Контрольная сумма доказывает, что
> бинарь совпадает с `SHA256SUMS` из того же релиза — это ловит повреждение,
> частичную/кэш-подмену и не даёт запустить код с подвижной ветки `main`. Сама по себе она
> НЕ защищает от атакующего, способного переписать *и* бинарь, *и* его сумму в источнике,
> и НЕ доказывает, *кто* их опубликовал. Для этого нужна подпись.

## Использование

```bash
panic status            # только чтение: предпросмотр — что затронет `panic now`
panic now               # спрятать и запереть сейчас
panic now --hard        # + прибить cloud-демоны, почистить «Recent items»
panic hotkey install    # повесить глобальный хоткей (cmd + alt - p) на `panic now`
panic hotkey status     # показать / снять хоткей
panic version           # показать версию (также -v / --version)
panic --help            # показать справку (также -h / help)
```

Явный verb `now` выбран намеренно: kill-switch не должен срабатывать от случайного
`panic` без аргументов (bare `panic` → usage).

Что делает `panic now`:

1. размонтирует все смонтированные disk image'ы под `/Volumes` (`hdiutil detach -force`);
2. очищает буфер обмена (`pbcopy </dev/null`);
3. блокирует экран (`CGSession -suspend` — реальный login-window).

С флагом `--hard` дополнительно: прибивает cloud-демоны (Dropbox, OneDrive, iCloud `bird`,
Google Drive) и чистит глобальные Recent items (shared file lists).

### Глобальный хоткей

Чтобы срабатывало в один шаг, повесь `panic now` на системную горячую клавишу:

```bash
panic hotkey install                 # по умолчанию: cmd + alt - p
panic hotkey install "cmd + shift - escape"   # или своя комбинация
panic hotkey status                  # показать текущий биндинг
panic hotkey uninstall               # снять
```

Настоящий глобальный хоткей на macOS требует резидентного слушателя с правом Accessibility —
на чистом Bash это невозможно. `panic hotkey` использует [`skhd`](https://github.com/koekeishiya/skhd),
крошечный hotkey-демон (`brew install skhd`). Биндинг лежит в явно помеченном managed-блоке
твоего `skhdrc`, так что твои собственные skhd-биндинги не затрагиваются. При первом срабатывании
выдай skhd доступ в **System Settings → Privacy & Security → Accessibility**, иначе хоткей не сработает.

> На Windows глобальный хоткей пока не подключён — запускай `panic now` напрямую (нативный
> хоткей запланирован).

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

## Windows (beta)

PowerShell-порт уже существует — в [`windows/README.md`](windows/README.md). Он повторяет
логику macOS — lock workstation, dismount BitLocker/VeraCrypt-томов и очистка clipboard.

> **Beta:** Windows-порт протестирован по логике (Pester на CI), но ещё не проверен на
> реальном Windows-железе. См. [`windows/README.md`](windows/README.md).

## Лицензия

Распространяется под лицензией [MIT](LICENSE). Без каких-либо гарантий — см. файл лицензии.
Сообщить об уязвимости — [SECURITY.md](SECURITY.md). Как внести вклад — [CONTRIBUTING.md](CONTRIBUTING.md).
