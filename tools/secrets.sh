#!/usr/bin/env bash
# repo secrets — encrypted .env transport for multi-device repos. No AI required.
#
#   .env       plaintext secrets at repo root (gitignored — per-device working copy)
#   .env.enc   AES-256-CBC (PBKDF2) encrypted copy — committed; travels with the repo
#
# Usage:  bash tools/secrets.sh setup            one-time per device: cache passphrase
#         bash tools/secrets.sh encrypt          .env      -> .env.enc  (after editing .env)
#         bash tools/secrets.sh decrypt [--force] .env.enc -> .env      (new device / after pull)
#         bash tools/secrets.sh status           sync check (never prompts; healthcheck calls this)
#
# Passphrase resolution order:
#   1) $SECRETS_PASSPHRASE            (throwaway/cloud sessions, CI)
#   2) per-device cache from `setup`  (Windows: DPAPI file; macOS: Keychain;
#                                      Linux: secret-tool, else chmod-600 file)
#   3) interactive prompt             (TTY only; `status` never prompts)
#
# The passphrase itself never goes into the repo, the command line, or chat —
# `setup` reads it from the terminal and stores it in the OS keystore.
# Requires: openssl (ships with Git Bash / standard on Linux & macOS).

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
ENC_FILE="$ROOT/.env.enc"
REPO_ID="$(basename "$ROOT")"
CACHE_DIR="${HOME}/.config/repo-secrets"
CACHE_FILE="$CACHE_DIR/$REPO_ID"
OSSL="openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt"

die() { echo "secrets: $*" >&2; exit 1; }

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
  Darwin)               PLATFORM=mac ;;
  *)                    PLATFORM=linux ;;
esac

# WSL trap: `bash` typed in PowerShell/cmd is often WSL, not Git Bash. The agent
# and healthcheck run Git Bash (DPAPI cache) — a WSL-side cache is invisible to them.
if [ "$PLATFORM" = "linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
  echo "secrets: WARNING — running under WSL on a Windows machine." >&2
  echo "         Use Git Bash instead so the passphrase cache (DPAPI) is shared with agent sessions:" >&2
  echo "         & 'C:\\Program Files\\Git\\bin\\bash.exe' tools/secrets.sh ${1:-<cmd>}" >&2
fi

ps_exe() {
  if command -v powershell.exe >/dev/null 2>&1; then echo powershell.exe
  elif command -v pwsh >/dev/null 2>&1; then echo pwsh
  else return 1; fi
}

# --- per-device passphrase cache ---------------------------------------------
cache_store() { # $1 = passphrase
  case "$PLATFORM" in
    windows)
      mkdir -p "$CACHE_DIR"
      # env -u PSModulePath: a PS7 parent shell pollutes PSModulePath and breaks
      # Windows PowerShell 5.1 module autoload (ConvertTo-SecureString not found)
      RS_PASS="$1" RS_FILE="$(cygpath -w "$CACHE_FILE.dpapi")" env -u PSModulePath "$(ps_exe)" -NoProfile -NonInteractive -Command \
        'ConvertTo-SecureString -String $env:RS_PASS -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -LiteralPath $env:RS_FILE -Encoding ascii' \
        || die "DPAPI store failed" ;;
    mac)
      security add-generic-password -U -s "repo-secrets-$REPO_ID" -a "$USER" -w "$1" \
        || die "Keychain store failed" ;;
    linux)
      if command -v secret-tool >/dev/null 2>&1; then
        printf '%s' "$1" | secret-tool store --label "repo-secrets-$REPO_ID" service repo-secrets repo "$REPO_ID" \
          || die "secret-tool store failed"
      else
        mkdir -p "$CACHE_DIR"; umask 177
        printf '%s' "$1" > "$CACHE_FILE.pass" || die "cache write failed"
        echo "secrets: NOTE — no secret-service available; passphrase cached as plain chmod-600 file $CACHE_FILE.pass" >&2
      fi ;;
  esac
}

cache_load() { # prints passphrase or returns 1
  case "$PLATFORM" in
    windows)
      [ -f "$CACHE_FILE.dpapi" ] || return 1
      RS_FILE="$(cygpath -w "$CACHE_FILE.dpapi")" env -u PSModulePath "$(ps_exe)" -NoProfile -NonInteractive -Command \
        '$s = Get-Content -LiteralPath $env:RS_FILE | ConvertTo-SecureString; $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); [Console]::Out.Write([Runtime.InteropServices.Marshal]::PtrToStringBSTR($b))' \
        2>/dev/null || return 1 ;;
    mac)
      security find-generic-password -s "repo-secrets-$REPO_ID" -w 2>/dev/null || return 1 ;;
    linux)
      if command -v secret-tool >/dev/null 2>&1; then
        secret-tool lookup service repo-secrets repo "$REPO_ID" 2>/dev/null || return 1
      else
        [ -f "$CACHE_FILE.pass" ] && cat "$CACHE_FILE.pass" || return 1
      fi ;;
  esac
}

get_pass() { # $1 = "noprompt" to forbid TTY prompt. Prints passphrase.
  if [ -n "${SECRETS_PASSPHRASE:-}" ]; then printf '%s' "$SECRETS_PASSPHRASE"; return 0; fi
  P="$(cache_load)" && [ -n "$P" ] && { printf '%s' "$P"; return 0; }
  [ "${1:-}" = "noprompt" ] && return 1
  [ -t 0 ] || return 1
  printf 'Passphrase for %s: ' "$REPO_ID" >&2
  read -rs P; echo >&2
  [ -n "$P" ] || return 1
  printf '%s' "$P"
}

pass_ok() { # $1 = passphrase — true if it decrypts .env.enc
  RS_PASS="$1" $OSSL -d -in "$ENC_FILE" -pass env:RS_PASS >/dev/null 2>&1
}

# --- commands -----------------------------------------------------------------
cmd_setup() {
  P="${SECRETS_PASSPHRASE:-}"
  if [ -z "$P" ]; then
    [ -t 0 ] || die "setup needs a terminal (or SECRETS_PASSPHRASE)"
    printf 'Choose/enter passphrase for %s: ' "$REPO_ID" >&2; read -rs P; echo >&2
    printf 'Repeat: ' >&2; read -rs P2; echo >&2
    [ "$P" = "$P2" ] || die "passphrases do not match"
    [ -n "$P" ] || die "empty passphrase"
  fi
  if [ -f "$ENC_FILE" ] && ! pass_ok "$P"; then
    die "that passphrase does NOT decrypt the existing .env.enc — wrong passphrase? (delete .env.enc first if rotating)"
  fi
  cache_store "$P"
  P2="$(cache_load)" || die "stored but cannot read back from keystore"
  [ "$P" = "$P2" ] || die "keystore verification mismatch"
  echo "secrets: passphrase cached for this device ($PLATFORM keystore). encrypt/decrypt now run without prompting."
}

cmd_encrypt() {
  [ -f "$ENV_FILE" ] || die ".env not found at repo root — nothing to encrypt"
  P="$(get_pass)" || die "no passphrase (run: bash tools/secrets.sh setup)"
  [ -f "$ENC_FILE" ] && ! pass_ok "$P" && die "passphrase does not match existing .env.enc — refusing to mix keys (delete .env.enc to rotate)"
  RS_PASS="$P" $OSSL -in "$ENV_FILE" -out "$ENC_FILE.tmp" -pass env:RS_PASS || { rm -f "$ENC_FILE.tmp"; die "encrypt failed"; }
  # verify roundtrip before replacing
  if ! RS_PASS="$P" $OSSL -d -in "$ENC_FILE.tmp" -pass env:RS_PASS 2>/dev/null | cmp -s - "$ENV_FILE"; then
    rm -f "$ENC_FILE.tmp"; die "roundtrip verification failed"
  fi
  mv "$ENC_FILE.tmp" "$ENC_FILE"
  echo "secrets: .env -> .env.enc OK (verified). Commit .env.enc to publish."
}

cmd_decrypt() {
  [ -f "$ENC_FILE" ] || die ".env.enc not found — nothing to decrypt"
  P="$(get_pass)" || die "no passphrase (run: bash tools/secrets.sh setup)"
  pass_ok "$P" || die "wrong passphrase for .env.enc"
  if [ -f "$ENV_FILE" ]; then
    if RS_PASS="$P" $OSSL -d -in "$ENC_FILE" -pass env:RS_PASS 2>/dev/null | cmp -s - "$ENV_FILE"; then
      echo "secrets: .env already in sync with .env.enc"; return 0
    fi
    [ "${1:-}" = "--force" ] || die ".env exists and DIFFERS from .env.enc — local edits? run 'encrypt' to keep them, or 'decrypt --force' to overwrite"
  fi
  umask 177
  RS_PASS="$P" $OSSL -d -in "$ENC_FILE" -out "$ENV_FILE" -pass env:RS_PASS || die "decrypt failed"
  echo "secrets: .env.enc -> .env OK"
}

cmd_status() { # never prompts. exit: 0 ok/in-sync, 2 need decrypt, 3 differ, 4 unencrypted .env, 5 can't compare, 1 error
  if [ ! -f "$ENV_FILE" ] && [ ! -f "$ENC_FILE" ]; then echo "no secrets configured"; exit 0; fi
  if [ -f "$ENV_FILE" ] && [ ! -f "$ENC_FILE" ]; then echo ".env present but never encrypted — run: bash tools/secrets.sh encrypt"; exit 4; fi
  if [ ! -f "$ENV_FILE" ] && [ -f "$ENC_FILE" ]; then echo ".env missing — run: bash tools/secrets.sh decrypt"; exit 2; fi
  P="$(get_pass noprompt)" || { echo "cannot verify sync — no cached passphrase (run: bash tools/secrets.sh setup)"; exit 5; }
  pass_ok "$P" || { echo "cached passphrase cannot decrypt .env.enc — re-run: bash tools/secrets.sh setup"; exit 1; }
  if RS_PASS="$P" $OSSL -d -in "$ENC_FILE" -pass env:RS_PASS 2>/dev/null | cmp -s - "$ENV_FILE"; then
    echo "in sync (.env <-> .env.enc)"; exit 0
  else
    echo ".env and .env.enc DIFFER — run: bash tools/secrets.sh encrypt (keep local .env) or decrypt --force (discard local)"; exit 3
  fi
}

case "${1:-}" in
  setup)   cmd_setup ;;
  encrypt) cmd_encrypt ;;
  decrypt) cmd_decrypt "${2:-}" ;;
  status)  cmd_status ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
