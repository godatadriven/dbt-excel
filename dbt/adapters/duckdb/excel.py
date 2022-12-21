from typing import Any
from typing import Dict
from typing import Optional
from typing import Sequence
from typing import Union
from pandas import DataFrame

import pandas as pd
import os

excel_writer = None

def _get_excel_writer(path: str) -> pd.ExcelWriter:
    global excel_writer
    if not excel_writer:
        if not os.path.exists(path):
            pd.DataFrame().to_excel(path)
        excel_writer = pd.ExcelWriter(path, engine="openpyxl", mode="a", if_sheet_exists="replace")
    return excel_writer


# TODO: instantiate pandas excel writer object as "client" to pass through to write multiple sheets in one file

def _create_table(client, table, data: DataFrame) -> None:
    with client:
        data.to_excel(client, sheet_name=table, index=False)


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
        client = _get_excel_writer(credentials.path)
        _create_table(client, table=table, data=data)
        
