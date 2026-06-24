#!/usr/bin/env bash
# Устанавливает panic в /usr/local/bin с проверкой целостности.
#
# Тянет бинарь и SHA256SUMS из РЕЛИЗНОГО тега (не из ветки main) и проверяет
# хеш ДО установки. Закрывает supply-chain риск «curl|bash из main без проверки»:
# содержимое релизного тега неизменно (в отличие от подвижной main), а хеш ловит
# повреждение, частичную/кэш-подмену и рассинхрон бинаря с публикацией.
# ЧЕСТНО: сумма и бинарь приходят по одному каналу — от подмены САМОГО релиза
# (переписаны оба) это не защищает; для подлинности нужна подпись / Homebrew.
#
# Использование (рекомендуется verify-then-run, см. README):
#   curl -fsSLO https://github.com/Di-kairos/panic/releases/latest/download/install.sh
#   curl -fsSLO https://github.com/Di-kairos/panic/releases/latest/download/SHA256SUMS
#   shasum -a 256 -c SHA256SUMS --ignore-missing   # проверить сам install.sh
#   less install.sh                                  # прочитать глазами
#   bash install.sh
#
# Переменные окружения:
#   PANIC_VERSION   — поставить конкретный тег (напр. 0.1.0). По умолчанию latest.
#   PANIC_BASE_URL  — переопределить источник целиком (для форков/тестов).
#   PANIC_DEST      — путь установки. По умолчанию /usr/local/bin/panic.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "panic работает только на macOS." >&2; exit 1
fi

REPO="Di-kairos/panic"
# Источник: явный PANIC_BASE_URL → конкретный тег PANIC_VERSION → latest-релиз.
if [[ -n "${PANIC_BASE_URL:-}" ]]; then
  BASE_URL="$PANIC_BASE_URL"
elif [[ -n "${PANIC_VERSION:-}" ]]; then
  BASE_URL="https://github.com/${REPO}/releases/download/v${PANIC_VERSION}"
else
  BASE_URL="https://github.com/${REPO}/releases/latest/download"
fi
DEST="${PANIC_DEST:-/usr/local/bin/panic}"

# Временный каталог под загрузку; чистим в любом случае.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Скачиваю panic и SHA256SUMS из релиза..."
curl -fsSL "${BASE_URL}/panic" -o "${TMP}/panic"
curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${TMP}/SHA256SUMS"

# Проверка целостности ДО chmod +x.
echo "Проверяю контрольную сумму..."
if ! ( cd "$TMP" && shasum -a 256 -c SHA256SUMS --ignore-missing ); then
  echo "✗ Контрольная сумма НЕ совпала — установка прервана (возможна подмена)." >&2
  exit 1
fi

# --- Проверка ПОДПИСИ релиза (аутентичность поверх целостности) ---
# Релизы подписаны выделенным ed25519-ключом экосистемы (ssh-keygen -Y). Pubkey вшит ниже.
# Поведение: нет ssh-keygen → громкое предупреждение (аутентичность не проверена, только
# целостность); у релиза нет .sig → жёсткий отказ (legacy-обход через ALLOW_UNSIGNED_LEGACY=1);
# .sig есть и НЕ сошёлся → жёсткий отказ (явный признак подмены).
RELEASE_SIGNING_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICb2nz4EliRJIU0ExeF41klE/zlyo7XFY119mfzscn2U"
SIGN_PRINCIPAL="releases@paranoid-tools"
# pubkey задан, но ssh-keygen недоступен → НЕ молчим: аутентичность не проверена (только целостность).
if [[ -n "$RELEASE_SIGNING_PUBKEY" ]] && ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "! ssh-keygen недоступен — подпись релиза НЕ проверена (только целостность по SHA256)." >&2
  echo "  Установи openssh для проверки аутентичности или сверь подпись вручную (см. SECURITY.md)." >&2
fi
if [[ -n "$RELEASE_SIGNING_PUBKEY" ]] && command -v ssh-keygen >/dev/null 2>&1; then
  if curl -fsSL "${BASE_URL}/SHA256SUMS.sig" -o "${TMP}/SHA256SUMS.sig" 2>/dev/null; then
    printf '%s namespaces="file" %s\n' "$SIGN_PRINCIPAL" "$RELEASE_SIGNING_PUBKEY" > "${TMP}/allowed_signers"
    echo "Проверяю подпись релиза..."
    if ( cd "$TMP" && ssh-keygen -Y verify -f allowed_signers -I "$SIGN_PRINCIPAL" \
                        -n file -s SHA256SUMS.sig < SHA256SUMS >/dev/null 2>&1 ); then
      echo "✓ Подпись релиза верна (аутентичность подтверждена)."
    else
      echo "✗ Подпись релиза НЕ прошла проверку — установка прервана (возможна подмена)." >&2
      exit 1
    fi
  else
    if [[ "${ALLOW_UNSIGNED_LEGACY:-0}" == "1" ]]; then
      echo "! Подпись недоступна — продолжаю (ALLOW_UNSIGNED_LEGACY=1, только для старых релизов)." >&2
    else
      echo "✗ Подпись релиза отсутствует — установка прервана." >&2
      echo "  Релизы подписаны. Неподписанный/старый релиз: ALLOW_UNSIGNED_LEGACY=1 bash install.sh" >&2
      exit 1
    fi
  fi
fi

# Хеш верный → устанавливаем. Под несписываемый каталог — через sudo.
echo "Устанавливаю в ${DEST}..."
if [[ -w "$(dirname "$DEST")" ]]; then
  install -m 0755 "${TMP}/panic" "$DEST"
else
  sudo install -m 0755 "${TMP}/panic" "$DEST"
fi

echo "Установлено: $DEST"
echo "Дальше: повесь 'panic now' на хоткей (напр. через launchd / Shortcuts)."
