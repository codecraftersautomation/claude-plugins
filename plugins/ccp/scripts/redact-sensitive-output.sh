#!/usr/bin/env bash
# redact-sensitive-output.sh
#
# Reads stdin, writes a redacted copy to stdout.
#
# Goal: strip likely secrets from text that CCP is about to write into a
# repo-local file (handoff notes, workstate dumps, plugin inventories, diffs).
# It is intentionally conservative: the cost of leaving a normal line of code
# slightly mangled is much lower than the cost of leaking a token into a file
# that might get committed. But we also don't want to shred ordinary source so
# badly it becomes unreadable, so the patterns target key=value shapes and
# well-known token formats rather than "anything that looks high-entropy".
#
# Usage:
#   some_command | redact-sensitive-output.sh
#   redact-sensitive-output.sh < file.txt
#
# This uses Perl (present by default on macOS) for reliable regex; BSD sed on
# macOS does not support the constructs we need.

set -euo pipefail

perl -pe '
  # --- Whole-line secrets: PEM private key bodies ---
  # Replace the contents between BEGIN/END markers conservatively by redacting
  # any long base64-ish run on its own line.
  s/^[A-Za-z0-9+\/]{40,}={0,2}\s*$/[REDACTED_KEY_MATERIAL]/g;

  # --- Authorization / bearer headers ---
  # NOTE: variables before a literal "[" MUST be braced (${1}) — Perl otherwise
  # parses "$1[REDACTED]" as an array subscript and silently drops the text.
  s/(?i)(authorization\s*[:=]\s*)(bearer\s+)?\S+/${1}${2}[REDACTED]/g;
  s/(?i)(bearer\s+)[A-Za-z0-9._\-]+/${1}[REDACTED]/g;

  # --- Cookie / Set-Cookie headers ---
  s/(?i)(set-cookie\s*[:=]\s*).*/${1}[REDACTED]/g;
  s/(?i)(\bcookie\s*[:=]\s*).*/${1}[REDACTED]/g;

  # --- Known token prefixes (Anthropic, OpenAI, GitHub, Slack, AWS, Google) ---
  s/sk-ant-[A-Za-z0-9._\-]+/[REDACTED_ANTHROPIC_KEY]/g;
  s/sk-[A-Za-z0-9]{16,}/[REDACTED_API_KEY]/g;
  s/gh[pousr]_[A-Za-z0-9]{20,}/[REDACTED_GITHUB_TOKEN]/g;
  s/xox[baprs]-[A-Za-z0-9-]{10,}/[REDACTED_SLACK_TOKEN]/g;
  s/AKIA[0-9A-Z]{16}/[REDACTED_AWS_KEY_ID]/g;
  s/ya29\.[A-Za-z0-9._\-]+/[REDACTED_GOOGLE_OAUTH]/g;
  s/eyJ[A-Za-z0-9._\-]{20,}/[REDACTED_JWT]/g;

  # --- key = "value" / key: value style assignments for sensitive names ---
  # Matches: password, passwd, secret, client_secret, token, api_key, apikey,
  # access_token, refresh_token, auth_token, private_key, credential(s).
  s/(?i)\b(pass(?:word|wd)?|secret|client_secret|api[_-]?key|apikey|access[_-]?token|refresh[_-]?token|auth[_-]?token|token|private[_-]?key|credentials?)\b(\s*[:=]\s*)("?)[^"\s,}]+("?)/${1}${2}${3}[REDACTED]${4}/g;

  # --- .env style: NAME=value where NAME looks sensitive ---
  s/(?i)^([A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)[A-Z0-9_]*)=.*/${1}=[REDACTED]/g;
'
