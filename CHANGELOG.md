# Changelog

Все заметные изменения panic. Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [0.1.1] — 2026-06-22

### Added
- **Подпись релизов (Ed25519, опциональная):** CI подписывает `SHA256SUMS`, `install.sh`
  авто-проверяет подпись поверх контрольной суммы (мягкая деградация). Pubkey в `SECURITY.md`.
- Homebrew `Formula/panic.rb`, `LICENSE`/`SECURITY.md`/`CONTRIBUTING.md`,
  English-primary README + `README.ru.md`, флаги `-v`/`--version`, `-h`/`--help`.

### Fixed
- **Офлайн `vendor --check`:** хеш вшитого common-блока против запиннутого SHA, без сети.

## [0.1.0] — 2026-06-19

Первый функциональный срез: kill-switch на один шаг для macOS.

### Added
- **`panic now`** — спрятать и запереть: размонтировать все смонтированные disk image'ы
  под `/Volumes` (`hdiutil detach -force`; mountpoints парсятся из `hdiutil info`,
  устойчиво к пробелам; system-образы вне `/Volumes` не трогаются), очистить буфер
  обмена (`pbcopy </dev/null`), заблокировать экран (`CGSession -suspend`, переопределяемо
  через `PANIC_CGSESSION`). Без confirm — режим паники; защита от случайного запуска —
  явный verb `now` (bare `panic` → usage).
- **`--hard`** — дополнительно прибить cloud-демоны (`pkill -x` Dropbox/OneDrive/bird/
  Google Drive, best-effort) и почистить глобальные Recent items (shared file lists).
- Вендоринг общего ядра `lib/common.sh` из securetrash inline-маркерами + CI-чек дрейфа.
- Дистрибуция: checksum-verified `install.sh` (бинарь + `SHA256SUMS` с релизного тега),
  `release.yml` собирает ассеты на push тега `v*`.

### Honest limitations
- panic ПРЯЧЕТ и ЗАПИРАЕТ, но **не уничтожает** и **не чистит swap** (для уничтожения —
  securetrash). `detach -force` при открытых файлах может повредить данные (осознанный
  trade-off паники). `--hard` чистит только глобальные Recent items — per-app «недавние»
  внутри приложений не стираются. Подробности — `README.md` «Scope & limitations».

### Tests
- bats 20/20 (8 scaffold + 7 now + 5 --hard), shellcheck clean.
- Тесты идут на Linux-CI через PATH-стабы (`uname/hdiutil/pbcopy/pkill`) + `PANIC_CGSESSION`/
  `PANIC_SFL_DIR` overrides.
- Real-device smoke на macOS: `now` распарсил живой `hdiutil info` и размонтировал тест-образ.

[Unreleased]: https://github.com/Di-kairos/panic/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Di-kairos/panic/releases/tag/v0.1.0
