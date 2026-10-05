# custom-ecc-python

[ECC (everything-claude-code)](https://github.com/affaan-m/ECC) のルールと、Ruff / pyright による品質チェックのフックを組み込んだ、Claude Code 向けの Python プロジェクトテンプレートです。

## 前提条件

| ツール | 用途 |
|---|---|
| [uv](https://docs.astral.sh/uv/) | Python と依存パッケージの管理 |
| [jq](https://jqlang.org/) | フックスクリプトが入力の JSON を読むのに使う |
| [Claude Code](https://claude.com/claude-code) と ECC プラグイン | ルールとフックを使う |

`uv` と `jq` がないと、Claude Code のフックが何もせずに終わります (エラーにはなりません)。

## テンプレートから新しいプロジェクトを作る

```bash
gh repo create <新しいリポジトリ名> --template Noboon803/custom-ecc-python --private --clone
cd <新しいリポジトリ名>
```

作成後、プロジェクト名 `custom-ecc-python` / パッケージ名 `custom_ecc_python` を新しい名前に変更します。

| ファイル | 変更箇所 |
|---|---|
| `pyproject.toml` | `[project]` の `name`、`[project.scripts]`、`[tool.coverage.run]` の `source` |
| `src/custom_ecc_python/` | ディレクトリ名 |
| `tests/` | `from custom_ecc_python import ...` |
| `CLAUDE.md` / `README.md` | タイトル |

変更したら `uv sync` で環境を作り直します。

## 開発コマンド

```bash
uv sync                                        # 環境の構築
uv run pytest                                  # テスト
uv run pytest --cov --cov-report=term-missing  # テスト + カバレッジ (80% 未満で失敗)
uv run ruff check .                            # lint
uv run ruff format .                           # 整形
uv run pyright                                 # 型チェック
```

## 構成

```
.
├── .claude/
│   ├── settings.json      # フックと、確認なしで実行してよいコマンドの設定
│   ├── hooks/             # フックスクリプト
│   └── rules/ecc/         # ECC のルール (common / python)
├── src/custom_ecc_python/ # アプリケーションコード
├── tests/                 # テスト
├── CLAUDE.md              # Claude への指示 (命名規則など)
└── pyproject.toml         # 依存関係と Ruff / pytest / coverage / pyright の設定
```

## 品質チェックの仕組み

コードの品質は、Claude Code のフックと、手動の開発コマンドでチェックします。フックは Claude Code の中でしか動かないため、人が編集したコードは開発コマンドで確認してください。

### Claude Code のフック (`.claude/hooks/`)

| フック | タイミング | 処理 |
|---|---|---|
| `ruff-post-edit.sh` (PostToolUse) | `.py` を Edit / Write するたび | `ruff check --fix` と `ruff format`。直せない lint エラーは Claude に返す |
| `python-stop.sh` (Stop) | Claude の応答の最後 | その応答で編集したファイルに `ruff check --fix` / `ruff format` / `pyright`。エラーが残れば Claude に修正を続けさせる |

未使用の import (F401) は、PostToolUse では無視し、Stop でまとめて削除します。Claude が Edit を重ねている途中で、追加したばかりの import が消されないようにするためです。

### Ruff のルール

`E`, `W`, `F`, `I`, `B`, `UP`, `SIM`, `PT`, `T20` を有効にしています。`T20` は `print()` を検出するルールで、ECC の「`print` ではなく `logging` を使う」というルールに対応します (`tests/` では除外)。

## ECC ルールの出典

`.claude/rules/ecc/` は ECC の日本語版ルールのコピーです。ECC が更新されても自動では追随しないので、必要に応じて手動で更新します。

| 項目 | 値 |
|---|---|
| 出典 | [affaan-m/ECC](https://github.com/affaan-m/ECC) の `docs/ja-JP/rules/` (`common/`, `python/`) |
| バージョン | v2.2.3 (コミット `ef648e0`, 2026-10-01) |
| ライセンス | MIT (`.claude/rules/ecc/LICENSE`) |

## ライセンス

[MIT](LICENSE)
