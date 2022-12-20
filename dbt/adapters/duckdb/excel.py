from typing import Any
from typing import Dict
from typing import Optional
from typing import Sequence
from typing import Union
from pandas import DataFrame

import pandas
from pandas import DataFrame

from dbt.adapters.base.column import Column

def _create_table(client, table, columns, data: DataFrame) -> None:
    data.to_excel("excel_ouput.xlsx", sheet_name=table, index=False)


def _update_table(client, database, table_def) -> None:
    client.update_table(DatabaseName=database, TableInput=table_def)


def _get_table(client="", database="", table=""):
    return False


def create_or_update_table(
    table: str,
    column_list: Sequence[Column],
    data: DataFrame,
    **kwargs: Optional[Dict[str, Union[str, int]]],
) -> None:

        # Check if table already exists
        excel_table = _get_table() # not implemented
        columns = column_list # optionally convert columns
        
        if excel_table:
            # check for changed columns
            #_update_table(client=client, database=database, table_def=table_def)
            pass
        else:
            _create_table(client="", table=table, columns=column_list, data=data)
