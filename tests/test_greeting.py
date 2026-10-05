import pytest

from custom_ecc_python import greet, main


@pytest.mark.unit
def test_greet_includes_name() -> None:
    assert greet("Alice") == "Hello, Alice!"


@pytest.mark.unit
def test_main_prints_greeting(capsys: pytest.CaptureFixture[str]) -> None:
    main()

    assert capsys.readouterr().out == "Hello, custom-ecc-python!\n"
