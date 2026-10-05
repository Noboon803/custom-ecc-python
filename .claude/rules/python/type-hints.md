---
paths:
  - "**/*.py"
---

# 型ヒントの前方参照

このプロジェクトは Python 3.14 以上を対象とし、注釈は既定で遅延評価される（PEP 649 / 749）。そのため、型ヒントの前方参照は引用符なしで書く。

- 型ヒントを文字列で書かない: `def add(self, child: "Node")` ではなく `def add(self, child: Node)`。ruff の `UP037` で検出・自動修正される
- `from __future__ import annotations` を書かない。ruff の `TID251` で検出される
- 自分のクラスのインスタンスを返すメソッドは、クラス名ではなく `typing.Self` を使う

## 例外

注釈ではなく実行時に評価される箇所では、まだ定義されていない型を引用符で書いてよい。

- `typing.cast("Node", value)` の第 1 引数
- 基底クラスの型引数（例: `class Tree(list["Node"])`）
