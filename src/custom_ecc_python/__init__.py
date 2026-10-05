def greet(name: str) -> str:
    return f"Hello, {name}!"


def main() -> None:
    print(greet("custom-ecc-python"))  # noqa: T201 - CLI の標準出力
