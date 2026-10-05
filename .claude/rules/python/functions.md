---
paths:
  - "**/*.py"
---

# 関数・メソッドの書き方

公開している関数・メソッドには「処理の流れ」だけを書き、各ステップの詳細は非公開の関数・メソッドに切り出す。ステップに適切な名前が付いていれば、公開メソッドを上から読むだけで処理の流れが文章として読める（Composed Method パターン。『Clean Code』の「1 つの関数に 1 つの抽象レベル」、SLAP とも呼ばれる）。

複雑すぎる関数は ruff の `C901`（循環的複雑度）・`PLR0912`（分岐の数）・`PLR0915`（文の数）で検出される。ただし、しきい値を下回っていてもこのルールに従う。検出されたら `# noqa` で抑えず、ステップに分けて解消する。

## 単一責務

- 1 つの関数・メソッドは 1 つのことだけをする。変更される理由が 1 つになるようにする
- 名前に「と」「and」が入る、または説明に「〜して、〜する」と複数の動作が必要になるなら、分ける
- 名前が付けにくいのは、責務がはっきりしていない兆候。先に責務を見直す

## 公開メソッドは処理の流れを書く

- 公開メソッドの各行は、1 つの処理ステップにする。ステップ同士の抽象度をそろえ、「何をするか」の行と「どうやるか」の行を混ぜない
- ループ・計算式・文字列の組み立て・外部 API やデータベースの呼び出し方など、ステップを実現する手続きは非公開メソッドに切り出す
- 切り出したメソッドの中がさらに複数のステップに分かれるなら、同じ考え方で分ける
- 処理の流れとしての分岐（早期 return、成功・失敗の振り分け）は公開メソッドに書いてよい。分岐の中身が手続きなら切り出す
- `try` の本体には、失敗しうるステップの呼び出しだけを書く

```python
# Bad: 流れと手続きが混ざり、何をしているのか読み取りにくい
def place(self, request: OrderRequest) -> Order:
    if not request.items:
        raise ValidationError("items is empty")
    for item in request.items:
        stock = self._repo.find_stock(item.product_id)
        if stock.quantity < item.quantity:
            raise OutOfStockError(item.product_id)
        self._repo.reserve(item.product_id, item.quantity)
    subtotal = sum(i.price * i.quantity for i in request.items)
    discount = subtotal * request.coupon.rate if request.coupon else 0
    order = Order(request.customer_id, request.items, subtotal - discount)
    self._repo.save(order)
    self._mailer.send(order.customer_id, f"ご注文 {order.id} を受け付けました")
    return order


# Good: 公開メソッドを読むと流れが文章として読める
def place(self, request: OrderRequest) -> Order:
    """注文を確定する。"""
    self._validate(request)
    self._reserve_stock(request.items)
    total = self._calculate_total(request.items, request.coupon)
    order = self._save(request.customer_id, request.items, total)
    self._notify_accepted(order)
    return order
```

## 切り出したメソッドの名前

- 「どうやるか」ではなく「何をするか」を、動詞から始めて書く（`_loop_items` ではなく `_reserve_stock`）
- 公開メソッドの中で並べたときに、処理の流れとして自然に読める名前にする

## ステップ間のデータの受け渡し

- ステップ同士は引数と戻り値でつなぐ。`self` の属性に途中結果を書き込んで次のステップに渡さない（流れから依存関係が読み取れなくなる）
- 切り出したメソッドは、受け取った値を変更せず、新しい値を返す

## 分けすぎない

- 名前が中身の言い換えにしかならない場合は分けない（例: `len(items) == 0` だけを返す `_is_empty`）。ただし、業務上の意味を表す名前が付くなら分けてよい（例: `_is_free_shipping`）
- 1 回しか呼ばれないことは、分けない理由にならない。流れを読みやすくするための切り出しは、呼び出しが 1 回でも行う
- 簡素化やリファクタリングのときも、流れのステップとして切り出したメソッドを、呼び出しが 1 回だからという理由で元に戻さない。ECC の code-simplifier の「single-use helpers を戻す」指示より、このルールを優先する

## 配置

- 切り出した非公開メソッドは、公開メソッドより後に、公開メソッドから呼ばれる順に並べる（`class-layout.md` の順序に従う）
- モジュールレベルの関数も同じ考え方で書き、切り出した関数は `_` 始まりにする
