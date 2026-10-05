#!/bin/bash
# Stop hook: この応答で編集された .py / .pyi に対して、
#   1. F401 (未使用 import) も含めて ruff check --fix と ruff format をかける
#   2. pyright で型チェックする
# 編集途中は import を消さないよう PostToolUse では F401 を無視しているので、応答の最後にまとめて片付ける。
# 自動修正できない lint エラーや型エラーが残った場合は exit 2 で Claude に修正を続けさせる。

input=$(cat)
session_id=$(jq -r '.session_id // empty' <<<"$input")
stop_hook_active=$(jq -r '.stop_hook_active // false' <<<"$input")

edited_list="${TMPDIR:-/tmp}/claude-ruff-edited-${session_id}.txt"
[ -n "$session_id" ] && [ -f "$edited_list" ] || exit 0

files=()
while IFS= read -r f; do
  [ -f "$f" ] && files+=("$f")
done < <(sort -u "$edited_list")
rm -f "$edited_list"

[ ${#files[@]} -gt 0 ] || exit 0

ruff=(uv run --project "$CLAUDE_PROJECT_DIR" --quiet ruff)

# --fixable=ALL: pyproject.toml の unfixable (F401) をここでは解除する
# (= を付けないと、後ろのファイル名までルールコードとして解釈される)
lint_output=$("${ruff[@]}" check --fix --fixable=ALL --force-exclude --quiet "${files[@]}" 2>&1)
lint_status=$?

"${ruff[@]}" format --force-exclude --quiet "${files[@]}"

# 整形後のコードを型チェックする (設定は pyproject.toml の [tool.pyright])
type_output=$(uv run --project "$CLAUDE_PROJECT_DIR" --quiet pyright --project "$CLAUDE_PROJECT_DIR" "${files[@]}" 2>&1)
type_status=$?

# 無限ループ防止: Stop フックで継続させた後の 2 回目以降はブロックしない
[ "$stop_hook_active" = "true" ] && exit 0

blocked=0
if [ $lint_status -ne 0 ]; then
  echo "[python stop hook] 自動修正できない lint エラーがあります:" >&2
  echo "$lint_output" >&2
  blocked=1
fi
if [ $type_status -ne 0 ]; then
  echo "[python stop hook] pyright の型エラーがあります:" >&2
  echo "$type_output" >&2
  blocked=1
fi

[ $blocked -eq 0 ] || exit 2
exit 0
