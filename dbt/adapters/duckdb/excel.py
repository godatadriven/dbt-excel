from typing import Any
from typing import Dict
from typing import Optional
from typing import Sequence
from typing import Union
from pandas import DataFrame

import pandas
from pandas import DataFrame

from dbt.adapters.base.column import Column

# TODO: instantiate pandas excel writer object as "client" to pass through to write multiple sheets in one file

def _create_table(client, table, data: DataFrame, path: str) -> None:
    data.to_excel(str(path), sheet_name=table, index=False)


def _update_table(client, database, table_def) -> None:
    client.update_table(DatabaseName=database, TableInput=table_def)


def _get_table(client="", database="", table=""):
    return False


def create_or_update_table(
    table: str,
    data: DataFrame,
    credentials,
    **kwargs: Optional[Dict[str, Union[str, int]]],
) -> None:
        # TODO: Check if table already exists
        _create_table(client="", table=table, data=data, path=credentials.path)
        
