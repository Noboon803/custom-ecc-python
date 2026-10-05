# custom-ecc-python

## 命名規則

PEP 8 の命名スタイル（関数・変数は `snake_case`、クラスは `CapWords`、定数は `UPPER_CASE`）に従ったうえで、名前が長くなりすぎないよう次の方針を守る。名前だけで意味を完全に表そうとせず、スコープ・クラス・モジュール・型ヒントといった文脈に意味を分担させる。

### 1. 名前の長さはスコープの広さに合わせる

- 数行で終わるループや内包表記では短い名前でよい（`i`, `u`, `row`）
- 関数内のローカル変数は 1〜2 語にする（`user`, `total`）
- モジュール全体や公開 API の名前は、説明的にしてよい（`fetch_active_users`）
- 慣例的な 1 文字名は使ってよい: カウンター `i` / `j`、例外 `e`、ファイル `f`

### 2. 文脈で分かることを名前に繰り返さない

- クラス名を属性名やメソッド名に繰り返さない: `user.user_name` ではなく `user.name`、`UserRepository.find_user_by_id` ではなく `UserRepository.find_by_id`
- 型ヒントで分かる情報を名前に入れない: `active_user_list: list[User]` ではなく `active_users: list[User]`、`config_dict` ではなく `config`
- モジュール名を関数名に繰り返さない: `billing.calculate_billing_total` ではなく `billing.calculate_total`

### 3. 省略形は広く知られたものだけ使う

- 一般的な省略形は使ってよい: `id`, `url`, `db`, `config`, `ctx`, `req`, `df` など
- プロジェクトの中でしか通じない独自の省略形は作らない: `usr_mgr`, `calc_tmp_val` など

### 4. 長いメソッドチェーンは中間変数に分ける

1 つの式に呼び出しを詰め込まず、意味のある単位で途中の結果に名前を付ける。中間変数はスコープが狭いので、短い名前でよい。

```python
# Bad
send_notification(user_repository.find_by_email(request.email).primary_address.normalize())

# Good
user = user_repository.find_by_email(request.email)
address = user.primary_address.normalize()
send_notification(address)
```

### 補足

上の方針に従っても名前が 4〜5 語になる場合は、関数やクラスが役割を抱えすぎていないか見直す。例: `calculate_monthly_discounted_total_for_premium_users` は `PremiumPricing.monthly_total()` のように役割を分けられないか検討する。

## コードレビュー

Python のコードを書いた・変更したら、ECC の `ecc:code-reviewer` / `ecc:python-reviewer` と並行して、`python-rules-reviewer` エージェントでレビューする。`python-rules-reviewer` は `.claude/rules/python/` のプロジェクト独自ルールに沿っているかを確認する。HIGH の指摘は、作業を完了とする前に直す。
