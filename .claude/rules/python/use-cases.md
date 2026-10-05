---
paths:
  - "**/*.py"
---

# ユースケースと Command

ユースケース（アプリケーションサービス）への入力は Command / Query オブジェクトにまとめ、`execute(command)` の形で渡す。引数が ID 1 つだけのユースケースでも例外にしない。どのユースケースも同じ形で呼べることを優先する。

## 配置

ユースケース 1 つにつき 1 ファイルとし、その Command / Query・Result・UseCase を同じファイルに置く。

```
src/custom_ecc_python/
├── domain/
│   └── order/
│       ├── order.py          # エンティティ・値オブジェクト
│       └── repository.py     # リポジトリの Protocol
└── application/
    └── order/
        ├── place_order.py    # PlaceOrderCommand / PlaceOrderResult / PlaceOrderUseCase
        └── find_order.py     # FindOrderQuery / FindOrderResult / FindOrderUseCase
```

- 依存の向きは「外側の層（API・CLI など）→ application → domain」。domain は application や外側の層を import しない
- ユースケースは、リポジトリなどの依存を `__init__` で受け取る。型には domain に置いた Protocol を使い、具体的な実装を import しない

## 名前

- 更新系は「動詞 + 名詞 + Command」、参照系は「動詞 + 名詞 + Query」（`PlaceOrderCommand`、`FindOrderQuery`）
- 結果は `XxxResult`、ユースケースは `XxxUseCase`。`Xxx` はファイル名と同じユースケース名にする
- モジュール名と重なるが、クラス名からユースケース名を省かない。呼び出し側で `Command` だけでは、どのユースケースのものか区別できないため
- 実行するメソッドは `execute` に統一する

## Command / Query

- `@dataclass(frozen=True, slots=True)` で、変更できないデータにする。複数の値は `list` ではなく `tuple` で持つ
- フィールドはプリミティブ型（`str`, `int`, `bool`, `tuple` など）か、プリミティブ型だけでできた入力用の dataclass にする。ドメインの値オブジェクトやエンティティを持たせない
- Command / Query 自体には検証の処理を書かない
  - 形式のチェック（必須項目、文字数、形式など）は外側の層（FastAPI なら Pydantic のモデル）で行う
  - 業務ルールのチェックは、ユースケースの中で値オブジェクトやエンティティを作るときに行う

## Result

- `execute` はエンティティを返さず、Result（`@dataclass(frozen=True, slots=True)`）を返す。外側の層がドメインのオブジェクトを直接操作できないようにするため
- Result のフィールドも、Command と同じくプリミティブ型にする

## execute の中身

`functions.md` の書き方に従い、`execute` には処理の流れだけを書く。典型的な流れは次のとおり。

1. Command の値を、ドメインの値オブジェクトに変換する
2. リポジトリからエンティティを取得する、またはエンティティを作る
3. ドメインの処理を呼ぶ（業務ルールはエンティティや値オブジェクトに書き、ユースケースには書かない）
4. リポジトリに保存する
5. Result に詰め替えて返す

```python
@dataclass(frozen=True, slots=True)
class OrderItemInput:
    product_id: str
    quantity: int


@dataclass(frozen=True, slots=True)
class PlaceOrderCommand:
    customer_id: str
    items: tuple[OrderItemInput, ...]
    coupon_code: str | None = None


@dataclass(frozen=True, slots=True)
class PlaceOrderResult:
    order_id: str
    total: int


class PlaceOrderUseCase:
    def __init__(self, orders: OrderRepository, products: ProductRepository) -> None:
        self._orders = orders
        self._products = products

    def execute(self, command: PlaceOrderCommand) -> PlaceOrderResult:
        """注文を確定する。"""
        customer_id = CustomerId(command.customer_id)
        lines = self._build_lines(command.items)
        order = Order.place(customer_id, lines)
        self._orders.save(order)
        return PlaceOrderResult(order_id=str(order.id), total=order.total.amount)
```

## 呼び出し側

- 外側の層は、受け取った入力（HTTP リクエスト、CLI の引数など）を Command / Query に詰め替えてから `execute` を呼ぶ
- Result を、その層の出力（レスポンスのモデルなど）に詰め替えて返す
- 外側の層で、ドメインのクラスを直接 import しない
