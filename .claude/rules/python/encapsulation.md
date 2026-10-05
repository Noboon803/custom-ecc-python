---
paths:
  - "**/*.py"
---

# カプセル化

データについての判断・計算・検索は、そのデータを使う側ではなく、データの側に置く。データだけを持つクラスを作り、それを使う側で中身を取り出して処理を書かない（Feature Envy、Tell, Don't Ask、ドメインモデル貧血症として知られる問題）。

クラスにすること自体が目的ではない。目的は、データについての知識を 1 か所にまとめ、定義が変わったときに直す場所を 1 つにすること。

## データの側に置くもの

- 状態についての判断（例: `order.is_confirmed()`）。使う側で `order.status in (...)` のように判断しない
- データから導ける値（例: `order.total`）。使う側で合計を計算しない。引数を取らない値は `@property` にする
- 一覧に対する検索・絞り込み・集計。`list[Order]` をそのまま受け渡さず、一覧を表すクラス（ファーストクラスコレクション）に置く
- 状態を変える操作。frozen な dataclass では、変更後の新しいインスタンスを返すメソッドにする（例: `order.cancel()` が新しい `Order` を返す）

```python
@dataclass(frozen=True, slots=True)
class Order:
    id: str
    status: OrderStatus
    items: tuple[OrderLine, ...]

    @property
    def total(self) -> int:
        return sum(line.subtotal for line in self.items)

    def is_confirmed(self) -> bool:
        return self.status in (OrderStatus.PAID, OrderStatus.SHIPPED)

    def cancel(self) -> Self:
        return replace(self, status=OrderStatus.CANCELLED)


@dataclass(frozen=True, slots=True)
class Orders:
    items: tuple[Order, ...]

    def find(self, order_id: str) -> Order | None:
        return next((o for o in self.items if o.id == order_id), None)

    def confirmed(self) -> Self:
        return replace(self, items=tuple(o for o in self.items if o.is_confirmed()))
```

## 使う側の書き方

- オブジェクトの中身を取り出して判断せず、オブジェクトに判断を頼む（`order.is_confirmed()`）
- 他のオブジェクトの内部を深くたどらない（`order.customer.address.city` ではなく、必要な値を返すメソッドを `Order` に用意するか、引数で受け取る）
- 同じ判断や計算を 2 か所以上に書きそうになったら、データの側に移す

## クラスにするほどでないもの

- 振る舞いが 1 つしかなく、状態も持たないなら、クラスではなく関数にする
- その場合も、関数はデータの定義と同じモジュールに置く。使う側のモジュールに書かない
- モジュールの外から使わない関数・属性は `_` 始まりにする

## 複数のクラスに共通する処理

似たコードが複数のクラスにあっても、すぐに関数にまとめない。次の順に判断し、その処理が本来どこに属するかを決める。

1. **同じ知識か**: 同じ理由で変わるものかを確かめる。偶然似ているだけなら、まとめずに重複のままにする。迷ったら、3 か所目が出てくるまでまとめない
2. **共通のデータを扱っているか**: 扱っているなら、そのデータは名前の付いていない概念である。値オブジェクトやクラスとして取り出し、処理をそのメソッドにする（例: 金額と税率を `int` / `float` で渡す関数ではなく、`Money.with_tax(rate)`）
3. **各クラスの能力だけを使うか**: 使うだけなら、その能力を `Protocol` で表し、それを受け取る関数か、協力するクラスに置く。共通化のための基底クラスは作らない
4. **骨組みが同じで、一部のステップだけが派生型ごとに違うか**: 本当に is-a の関係がある場合に限り、抽象基底クラスとテンプレートメソッドを使う
5. **ログ・リトライ・キャッシュなどの横断的な関心事か**: デコレーターにする
6. **ドメインと無関係な汎用処理か**: モジュールの関数にしてよい

### 避けること

- `utils.py` / `helpers.py` / `common.py` のような、内容を表さない名前のモジュールに関数を集めない。汎用処理も、内容を表す名前のモジュールに置く（例: `text_format.py`）
- 各クラスからデータを取り出して引数に並べる関数を作らない（2. を検討する）
- コードを再利用するためだけに継承しない
- Mixin は、小さく独立した能力（例: 作成日時を持つ）に限る。Mixin が前提とする属性は、型ヒント付きでクラス本体に宣言する
- まとめた関数に、呼び出し元ごとの違いを吸収するための引数やフラグ（`is_invoice: bool` など）を足さない。足したくなったら、まとめたこと自体が誤りだったと考え、分け直す

## カプセル化の対象外

- Command / Query / Result（`use-cases.md`）は、層をまたいで受け渡すためのデータなので、データだけを持たせる
- データそのものについての知識でない処理は、データのクラスに入れない。保存（リポジトリ）、通知の送信、外部 API の呼び出しなどは、インフラやユースケースの責務とする
- 1 つのクラスに何でも集めない。知識のまとまりごとにクラスを分ける
