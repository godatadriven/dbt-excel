from dbt.adapters.base import AdapterPlugin
from dbt.adapters.excel.connections import ExcelConnectionManager  # noqa F401
from dbt.adapters.excel.connections import ExcelCredentials
from dbt.adapters.excel.impl import ExcelAdapter
from dbt.include import excel

Plugin = AdapterPlugin(
    adapter=ExcelAdapter,  # type: ignore
    credentials=ExcelCredentials,
    include_path=excel.PACKAGE_PATH,
    dependencies=["duckdb"],
)
