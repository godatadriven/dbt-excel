import pytest
from dbt.clients.jinja import MacroGenerator


@pytest.mark.parametrize(
    "macro_generator",
    ["macro.dbt_excel.enforce_string"],
    indirect=True,
)
def test_enforce_string(macro_generator: MacroGenerator) -> None:
    """Always return a lowercase string."""
    out = macro_generator(1)
    assert out == "1"
