from dbt.adapters.base.meta import available
from dbt.adapters.duckdb.impl import DuckDBAdapter
from dbt.adapters.excel.connections import ExcelConnectionManager
from dbt.adapters.excel.relation import ExcelRelation


class ExcelAdapter(DuckDBAdapter):
    ConnectionManager = ExcelConnectionManager
    Relation = ExcelRelation  # type: ignore

    @available
    def output_excel(self, location):
        import pandas as pd

        pd.read_parquet(location + ".parquet").to_excel(location)
