#!/bin/bash
# PostToolUse hook: 編集された .py / .pyi に ruff check --fix と ruff format をかける。
# 編集途中で追加したばかりの import を消さないよう、F401 (未使用 import) はここでは無視し、
# 応答の最後に Stop hook (ruff-stop.sh) でまとめて片付ける。
# 自動修正できない lint エラーが残った場合は exit 2 で Claude にフィードバックする。

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
session_id=$(jq -r '.session_id // empty' <<<"$input")

case "$file_path" in
  *.py | *.pyi) ;;
  *) exit 0 ;;
esac

# プロジェクト外のファイルや削除済みのファイルは対象外
# macOS はパスの大文字小文字を区別しないため (Projects / projects)、比較も区別しない
shopt -s nocasematch
case "$file_path" in
  "$CLAUDE_PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac
[ -f "$file_path" ] || exit 0

# Stop hook で処理するために、編集したファイルを記録する
if [ -n "$session_id" ]; then
  echo "$file_path" >>"${TMPDIR:-/tmp}/claude-ruff-edited-${session_id}.txt"
fi

ruff=(uv run --project "$CLAUDE_PROJECT_DIR" --quiet ruff)

# --force-exclude: pyproject.toml の exclude をパス直接指定時にも効かせる
lint_output=$("${ruff[@]}" check --fix --extend-ignore=F401 --force-exclude --quiet "$file_path" 2>&1)
lint_status=$?

"${ruff[@]}" format --force-exclude --quiet "$file_path"

if [ $lint_status -ne 0 ]; then
  echo "[ruff hook] $file_path に自動修正できない lint エラーがあります:" >&2
  echo "$lint_output" >&2
  exit 2
fi

exit 0
