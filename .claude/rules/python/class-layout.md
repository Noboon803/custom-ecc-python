---
paths:
  - "**/*.py"
---

# クラス内の記述順

クラスのメンバーは次の順に並べる。読む人が「どう作るか → 何ができるか → どう実装されているか」の順に辿れるよう、公開されている部分を上に、実装の詳細を下に置く。

1. クラスの docstring
2. クラス変数・定数（`ClassVar`、`UPPER_CASE` の定数、`@dataclass` / `Enum` のフィールド）
3. インスタンス生成: `__new__` → `__init__` → `__post_init__`
4. 別のコンストラクター（`@classmethod` で生成するもの。例: `from_dict`）
5. プロパティ（`@property` と、対応する setter / deleter）
6. 公開メソッド（それ以外の `@classmethod` や `@staticmethod` もここに含め、関連するメソッドの近くに置く）
7. 非公開メソッド（`_` 始まり）
8. 特殊メソッド（`__repr__`, `__eq__`, `__hash__`, `__iter__` など。生成に関わるものは 3 に置く）

```python
class Account:
    """銀行口座。"""

    MAX_BALANCE: ClassVar[int] = 1_000_000

    def __init__(self, owner: str) -> None:
        self._owner = owner
        self._balance = 0

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Self: ...

    @property
    def balance(self) -> int:
        return self._balance

    def deposit(self, amount: int) -> None:
        self._validate(amount)
        ...

    def _validate(self, amount: int) -> None: ...

    def __repr__(self) -> str: ...
```

## 補足

- 同じグループの中では、関連するもの同士を近くに置く（アルファベット順にはしない）
- `@staticmethod` は、クラスの状態に依存しないならモジュールの関数にできないか先に検討する
