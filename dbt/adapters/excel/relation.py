from dataclasses import dataclass
from pathlib import Path
from typing import Any
from typing import Optional
from typing import Type

import pandas as pd

from dbt.adapters.base.relation import BaseRelation
from dbt.adapters.base.relation import Self
from dbt.contracts.graph.nodes import SourceDefinition


@dataclass(frozen=True, eq=False, repr=False)
class ExcelRelation(BaseRelation):
    external_location: Optional[str] = None

    @classmethod
    def create_from_source(cls: Type[Self], source: SourceDefinition, **kwargs: Any) -> Self:

        if "external_location" in source.meta:
            external_location = source.meta["external_location"]
        elif "external_location" in source.source_meta:
            external_location = source.source_meta["external_location"]
        else:
            external_location = None

        if external_location is not None:
            external_location = external_location.format(
                schema=source.schema,
                name=source.name,
                identifier=source.identifier,
            )
            if external_location.endswith(".xlsx"):
                excel_location = Path(external_location.strip("'"))
                csv_location = (
                    excel_location.parent / excel_location.stem / source.identifier
                ).with_suffix(".csv")
                csv_location.parent.mkdir(exist_ok=True)
                pd.read_excel(excel_location, sheet_name=source.identifier).to_csv(
                    csv_location, index=False
                )
                external_location = str(csv_location)
            if "(" not in external_location and not external_location.startswith("'"):
                external_location = f"'{external_location}'"
            kwargs["external_location"] = external_location

        return super().create_from_source(source, **kwargs)  # type: ignore

    def render(self) -> str:
        if self.external_location:
            return self.external_location
        else:
            return super().render()
