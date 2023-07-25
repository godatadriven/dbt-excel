import pytest
import duckdb
from dbt.clients.jinja import MacroGenerator


@pytest.mark.parametrize(
    "macro_generator",
    ["macro.dbt_excel.enforce_string"],
    indirect=True,
)
def test_enforce_string(macro_generator: MacroGenerator, config) -> None:
    """Always return a lowercase string."""
    macro = macro_generator(1)
    first_record = duckdb.sql(f"SELECT {macro}").fetchone()
    assert first_record[0] == "1"
