# Changelog

Все заметные изменения panic. Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [0.1.4] — 2026-06-26

### Added
- **`panic hotkey`** — глобальный хоткей паники через [`skhd`](https://github.com/koekeishiya/skhd):
  `install [combo]` / `uninstall` / `status`. По умолчанию `cmd + alt - p` → `panic now`.
  Биндинг живёт в managed-блоке `skhdrc` (чужие skhd-биндинги не трогает). Честно: чистый
  Bash глобальный хоткей на macOS невозможен — нужен резидентный слушатель с правом
  Accessibility, поэтому используем skhd (`brew install skhd`). Windows-хоткей пока не подключён.
- Тесты: +8 bats (`test/hotkey.bats`) + skhd-стаб.

## [0.1.3] — 2026-06-25

Первый выпуск с поддержкой Windows.

### Added
- **Windows PowerShell port (beta):** `windows/panic.ps1` + `windows/install.ps1`.
  `panic now` запирает разблокированные BitLocker-тома (`Lock-BitLocker -ForceDismount`),
  размонтирует тома VeraCrypt (`VeraCrypt /d /f`), чистит буфер обмена и блокирует экран
  (`rundll32 user32.dll,LockWorkStation`); `--hard` дополнительно прибивает cloud-демоны
  и чистит Recent items. `status` — read-only preflight (BitLocker on/off, разблокированные
  тома, cloud-демоны). panic — сплошные side-effect'ы, поэтому Pester покрывает оркестровку
  с замоканными системными примитивами (windows-CI). Поведение зеркалит macOS-версию.

## [0.1.2] — 2026-06-24

Релиз догоняет ассеты до исходников: команда `status` и hardening установщика/подписи,
осевшие в `main` после тега `v0.1.1`, теперь попадают в публичный релиз.

### Added
- **`status`** — read-only preflight: FileVault on/off, смонтированные disk image'ы под
  `/Volumes`, активные cloud-демоны. Показывает, что именно сделает `panic now`, ничего
  не трогая. Безопасно звать до паники.

### Security
- **install.sh fail-closed:** отсутствие `SHA256SUMS.sig` на релизе теперь прерывает
  установку (обход для старых релизов — `ALLOW_UNSIGNED_LEGACY=1`); отсутствие `ssh-keygen`
  больше не молчит, а громко предупреждает, что подпись не проверена (только целостность).
- **Подпись релиза fail-closed:** `release.yml` прерывает выпуск (`exit 1`), если
  `RELEASE_SIGNING_KEY` не задан, — неподписанный релиз невозможен.

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

[Unreleased]: https://github.com/Di-kairos/panic/compare/v0.1.4...HEAD
[0.1.4]: https://github.com/Di-kairos/panic/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/Di-kairos/panic/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/Di-kairos/panic/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Di-kairos/panic/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Di-kairos/panic/releases/tag/v0.1.0
