from dataclasses import dataclass

from dbt.adapters.duckdb import DuckDBConnectionManager
from dbt.adapters.duckdb import DuckDBCredentials


@dataclass
class ExcelCredentials(DuckDBCredentials):
    @property
    def type(self):
        return "excel"


class ExcelConnectionManager(DuckDBConnectionManager):
    TYPE = "excel"
