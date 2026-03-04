#!/usr/bin/env bash
set -euo pipefail

# Wrapper for sbatch that appends a structured submission record.
# Usage: scripts/sbatch_track.sh [sbatch args...]

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 [sbatch args...]" >&2
  exit 2
fi

SELF_PATH="$(realpath "$0" 2>/dev/null || echo "$0")"
SBATCH_BIN="${SBATCH_BIN:-$(type -P sbatch || true)}"
if [[ -z "${SBATCH_BIN}" ]]; then
  echo "ERROR: sbatch not found in PATH" >&2
  exit 127
fi
if [[ "$(realpath "$SBATCH_BIN" 2>/dev/null || echo "$SBATCH_BIN")" == "$SELF_PATH" ]]; then
  if [[ -x /usr/bin/sbatch ]]; then
    SBATCH_BIN="/usr/bin/sbatch"
  else
    echo "ERROR: Resolved sbatch points to this wrapper and /usr/bin/sbatch is unavailable." >&2
    exit 127
  fi
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOG_FILE="${SLURM_HISTORY_FILE:-${REPO_ROOT}/scripts/slurm_history}"

# Build a shell-escaped command string for reproducibility.
CMD_STR="sbatch"
for arg in "$@"; do
  CMD_STR+=" $(printf '%q' "$arg")"
done

TIMESTAMP="$(date -Is)"
USER_NAME="${USER:-unknown}"
HOST_NAME="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown)"
CWD_NOW="$(pwd)"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo NA)"

# Best-effort extract of common options.
ARRAY_OPT=""
TIME_OPT=""
MEM_OPT=""
PARTITION_OPT=""
SCRIPT_ARG=""

prev=""
for arg in "$@"; do
  case "$prev" in
    --array) ARRAY_OPT="$arg"; prev=""; continue ;;
    --time) TIME_OPT="$arg"; prev=""; continue ;;
    --mem) MEM_OPT="$arg"; prev=""; continue ;;
    --partition|-p) PARTITION_OPT="$arg"; prev=""; continue ;;
  esac

  case "$arg" in
    --array|--time|--mem|--partition|-p)
      prev="$arg"
      ;;
    --array=*) ARRAY_OPT="${arg#--array=}" ;;
    --time=*) TIME_OPT="${arg#--time=}" ;;
    --mem=*) MEM_OPT="${arg#--mem=}" ;;
    --partition=*) PARTITION_OPT="${arg#--partition=}" ;;
    *.sh)
      if [[ -z "$SCRIPT_ARG" ]]; then
        SCRIPT_ARG="$arg"
      fi
      ;;
  esac
done

set +e
SBATCH_OUT="$("$SBATCH_BIN" "$@" 2>&1)"
SBATCH_RC=$?
set -e

echo "$SBATCH_OUT"

STATUS="ok"
JOB_ID=""
if [[ $SBATCH_RC -ne 0 ]]; then
  STATUS="error"
else
  JOB_ID="$(printf '%s\n' "$SBATCH_OUT" | awk '/Submitted batch job/ {print $4}' | tail -n1)"
  if [[ -z "$JOB_ID" ]]; then
    STATUS="unknown"
  fi
fi

mkdir -p "$(dirname "$LOG_FILE")"
if [[ ! -f "$LOG_FILE" ]]; then
  printf 'timestamp\tuser\thost\tcwd\tgit_sha\tjob_id\tstatus\tscript\tarray\ttime\tmem\tpartition\tcommand\n' > "$LOG_FILE"
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$TIMESTAMP" "$USER_NAME" "$HOST_NAME" "$CWD_NOW" "$GIT_SHA" "${JOB_ID:-NA}" "$STATUS" \
  "${SCRIPT_ARG:-NA}" "${ARRAY_OPT:-NA}" "${TIME_OPT:-NA}" "${MEM_OPT:-NA}" "${PARTITION_OPT:-NA}" "$CMD_STR" \
  >> "$LOG_FILE"

exit "$SBATCH_RC"
